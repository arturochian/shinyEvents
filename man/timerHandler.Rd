% Generated by roxygen2 (4.0.1): do not edit by hand
\name{timerHandler}
\alias{timerHandler}
\title{Add an handler that triggers every intervalMs milliseconds}
\usage{
timerHandler(id, intervalMs, fun, ..., app = getApp(), on.create = FALSE,
  if.handler.exists = c("replace", "add", "skip")[1], verbose = FALSE,
  session = getAppSession(app))
}
\arguments{
\item{id}{name of the input element}

\item{fun}{function that will be called if the input value changes. The function will be called with the arguments: 'id', 'value' and 'session'. One can assign the same handler functions to several input elements.}

\item{...}{extra arguments that will be passed to fun when the event is triggered.}
}
\description{
Add an handler that triggers every intervalMs milliseconds
}

