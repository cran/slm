% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generative.R
\name{generative_model}
\alias{generative_model}
\title{Some linear model}
\usage{
generative_model(n, model = "mod1")
}
\arguments{
\item{n}{integer. The sample size.}

\item{model}{a list of character "mod1" or "mod2" to choose the model.}
}
\value{
This function returns a data-frame which contains a simulated random design.
}
\description{
This function returns a design for the regression linear model, without the intercept. The user can choose one of the two models:
 "mod1" or "mod2". The first model "mod1" contains just one column, equal to \eqn{i^2 + X_i}, \eqn{i=1,...,n}, where \eqn{X} is an AR(1)
 process with \code{phi_1 = 0.5}.

 The second model "mod2" contains two columns, the first equal to \eqn{log(i) + sin(i) + X_i} and the second equal to \eqn{i}, for \eqn{i=1,...,n}.
 The process \eqn{X} is again an AR(1) process with \code{phi_1 = 0.5}. More information about "mod2" is available in the paper of
 E. Caron, J. Dedecker and B. Michel (2019). Linear regression with stationary errors: the R package slm.
}
\examples{
generative_model(500,"mod1")
}
\references{
E. Caron, J. Dedecker and B. Michel (2019). Linear regression with stationary errors: the R package slm. \emph{arXiv preprint arXiv:1906.06583}.
 \url{https://arxiv.org/abs/1906.06583}.
}
