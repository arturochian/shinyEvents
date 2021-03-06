
nested.ui.example = function() {
  library(shinyEvents)
  library(shinyAce)
  library(restorepoint)
  set.restore.point.options(display.restore.point = TRUE)

  app = eventsApp()

  session=NULL

  main.ui = fluidPage(
    actionButton("Btn0", "Main Button"),
    textOutput("Text0"),
    uiOutput("ui1")
  )
  ui1 = fluidRow(
    actionButton("Btn1", "Button 1"),
    textOutput("Text1"),
    uiOutput("ui2")
  )
  ui2 = fluidRow(
    actionButton("Btn2", "Button 2"),
    textOutput("Text2"),
    uiOutput("ui3")
  )
  setUI("ui2",ui2)
  setUI("ui1",ui1)

  press = function(id, level,session,...) {
    restore.point("press", dots=NULL)
    txt = paste0(id, " ", sample(1:1000,1))
    cat("before setText")
    setText(paste0("Text",level),txt)
    cat("after setText")
    removeEventHandler("Btn1")
    cat("\n finished press....")
  }

  buttonHandler("Btn0", press, level=0)
  buttonHandler("Btn1", press, level=1)
  buttonHandler("Btn2", press, level=2)

  runEventsApp(app,ui=main.ui)
}


hotkey.shiny.events.example = function() {
  library(shinyEvents)
  library(shinyAce)

  app = eventsApp()
  session=NULL

  ui = fluidPage(
    aceEditor("myEdit",value = "Lorris ipsum",
              hotkeys = list(runLine="Ctrl-Enter")),
    actionButton("myBtn", "Press..."),
    textOutput("myText")
  )


  buttonHandler("myBtn", user.name="Sebastian",
    function(id,session,user.name,...) {
      updateAceEditor(session, "myEdit", value = paste0("Lorris ipsum", sample(1:1000,1), " ", user.name))
      setText("myText","I pressed a button...")
    }
  )

  aceHotkeyHandler("runLine", custom.var = "Omega",function(text,...) {
    cat("Hotkey handler:\n")
    print(list(...))
    print(text)
  })

  # I can set outputs before the app is started to set
  # initial values.
  setText("myText","This is the start text...")

  runEventsApp(app,ui=ui)
}


basic.shinyEvents.example = function() {
  library(shinyEvents)

  app = eventsApp(verbose=FALSE)

  # Main page
  ui = fluidPage(
    actionButton("textBtn", "text"),
    actionButton("plotBtn", "plot"),
    actionButton("uiBtn", "ui"),
    actionButton("handlerBtn", "handler for later"),
    actionButton("laterBtn", "later"),
    selectInput("varInput", "Variable:",
        c("Cylinders" = "cyl",
          "Transmission" = "am",
          "Gears" = "gear")
    ),
    textOutput("myText"),
    uiOutput('myUI'),
    plotOutput("myPlot")
  )
  setAppUI(ui)

  buttonHandler("textBtn", function(session, id, value, ...) {
    setText("myText", paste0("You pressed the button ",id," ", value," times. "))
  })
  
  buttonHandler("plotBtn", function(...) {
    setText("myText", "Show random plot...")
    setPlot("myPlot", plot(runif(10), runif(10)))    
  })

  # handler for change of an input value
  changeHandler("varInput",on.create=TRUE, function(id, value,...) {
    setText("myText",paste0("You chose the list item ", value,". ", 
                            "A random number: ", sample(1:1000,1)))
  })

  # A button handler that dynamically generates another handler
  buttonHandler("handlerBtn", function(value,...) {
    setText("myText", paste0("made handler ", value, " for later button."))
    buttonHandler("laterBtn", maker.value = value, function(maker.value,...) {
      setText("myText", paste0("Maker value: ", maker.value,
                               " Random number: ", sample(1:1000,1)))
    })
  })

  
  num = 1
  # Dynamically create UI with button and add handler for it
  buttonHandler("uiBtn", function(session, value,...) {
    
    # Set a new dynamic UI
    dynUI= fluidRow(
      actionButton("dynBtn", paste0("Created button ",value))
    )
    setUI("myUI", dynUI)
    
    # Add handlers for the new button in the UI.
    # Existing handlers for dynBtn are by default replaced
    buttonHandler("dynBtn", function(value,...) {
      setText("myText", paste0("Dynamic button pressed ", value, " times."))
    })
  })

  rapp = app
  rm(app)
  runEventsApp(rapp,launch.browser=rstudio::viewer)
}


chat.example = function() {
  library(shinyEvents)
  library(shinyAce)

  app = eventsApp()
  
  # app$glob can contain "global" variables that are visible
  # for all sessions.
  # app$glob$txt will be the content of the chat window
  app$glob$txt = "Conversation so far"
  
  app$ui = fluidPage(
    textInput("userName","User Name",""),
    
    # Chat window
    aceEditor("convAce",value = app$glob$txt, height="200px",showLineNumbers = FALSE, debounce=100),    
    
    # Enter new text
    aceEditor("enterAce",value = "Your text",height="30px",showLineNumbers = FALSE,debounce = 100,hotkeys = list(addTextKey="Ctrl-Enter")),
    
    actionButton("addBtn", "add")
  )

  addChatText = function(session,app,...) {
    restore.point("addChatText")
    user = getInputValue("userName")
    str = getInputValue("enterAce")
    app$glob$txt = paste0(app$glob$txt,"\n",user, ": ",paste0(str,collapse="\n"))
    updateAceEditor(session,"convAce", value = app$glob$txt)
    updateAceEditor(session,"enterAce", value = " ")
  }
  
  # Add chat text when button or Ctrl-Enter is pressed 
  buttonHandler(id="addBtn",addChatText)
  aceHotkeyHandler("addTextKey",addChatText)
  
  # refresh chat window each second
  timerHandler("refreshChatWindow",1000, function(session,app,...) {
    txt = getInputValue("convAce")
    if (!identical(txt, app$glob$txt)) {
      cat("Refresh chat window...")
      updateAceEditor(session, "convAce", value = app$glob$txt)
    }
  })
  

  # Initialize each new session with a random user name
  appInitHandler(function(session,app,...) {
    updateTextInput(session,"userName",
                    value=paste0("guest", sample.int(10000,1)) )
    updateAceEditor(session,editorId = "convAce",value = app$glob$txt)
  })


  runEventsApp(app, launch.browser=TRUE)
  # To test chat function, open several browser tabs
}


find.current.app.example = function() {
  library(shinyEvents)
  library(shinyAce)

  app = eventsApp()
  app$glob$txt = "Conversation so far"
  app$id = 0
  app$glob$id = 0
  app$initHandler = function(session,app,...) {
    app$glob$id = app$glob$id+1
    app$id = app$glob$id
  }
  ui = fluidPage(
    textInput("name","Name:",paste0("guest")),
    actionButton("btn","Click me"),
    textOutput("out")
  )

  buttonHandler(NULL,"btn", function(...) {
    txt = paste0("name = ", getInputValue("name"), " id = ", app$id,"  ", sample.int(10000,1))
    setText("out",txt)
  })
  runEventsApp(app,ui=ui)
}

selectize.example = function() {
  library(shinyEvents)
  set.restore.point.options(display.restore.point = TRUE)

  app = eventsApp()

  li = as.list(1:5)
  names(li) = paste0("item:", 1:5)
  app$ui = fluidPage(
    selectizeInput("mult","Choose multiple", choices = li, selected=NULL, multiple=TRUE),
    textOutput("text")
  )
  changeHandler("mult", function(app, value,...) {
    restore.point("mult.changeHandler")
    #browser()
    print(value)
    val = getInputValue("mult")
    print(val)
    setText("text", paste0(value, collapse=","))
  })
  runEventsApp(app)
}

