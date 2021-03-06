#' @title Covariance matrix estimator for slm object
#'
#' @description This function gives the estimation of the asymptotic covariance matrix of the normalized least squares estimator in the case of the linear regression
#'  model with strictly stationary errors.
#'
#' @param object an object of class \code{slm}.
#'
#' @details The function computes the covariance matrix estimator of the normalized least squares estimator from the vector \code{cov_st}
#'  of a \code{slm} object. If the user has given the argument \code{Cov_ST} in the \code{slm} object, then it is used
#'  to compute the final covariance matrix. If the method used is the "hac" method, then the final covariance matrix is computed via
#'  the \code{\link[sandwich:kernHAC]{kernHAC}} function of the \code{sandwich} package, by using the Quadratic Spectral kernel and the bandwidth described in Andrews (1991).
#'  For the methods "efromovich", "kernel" and "select", the covariance matrix estimator may not be positive definite. Then we apply the
#'  "Positive definite projection" algorithm, which consists in replacing all eigenvalues lower or equal to zero with the smallest
#'  positive eigenvalue of the covariance matrix.
#'
#' @return This function returns the estimation of the asymptotic covariance matrix of the normalized least squares estimator.
#'
#' @importFrom stats toeplitz
#'
#' @seealso
#'
#'  The R package \code{\link[sandwich]{sandwich}}.
#'
#'  \code{\link[sandwich:kernHAC]{kernHAC}} for HAC methods.
#'
#' @references
#'  D. Andrews (1991). Heteroskedasticity and autocorrelation consistent covariant matrix estimation. \emph{Econometrica, 59(3), 817-858}.
#'
#'  E. Caron, J. Dedecker and B. Michel (2019). Linear regression with stationary errors: the R package slm. \emph{arXiv preprint arXiv:1906.06583}.
#'  \url{https://arxiv.org/abs/1906.06583}.
#'
#'  A. Zeileis (2004). Econometric computing with HC and HAC covariance matrix estimators.
#'
#' @export
cov_matrix_estimator = function(object) {
  Y = as.matrix(object$model[1])
  design = model.matrix(object) #design with intercept
  #design = cbind(rep(1,length(Y)),as.matrix(object$model[-1]))
  norm_matrix = object@norm_matrix
  design_qr = object@design_qr

  if (is.na(object@cov_st[1])) {
    if (object@method_cov_st=="hac") {
      Cn = norm_matrix%*%sandwich::kernHAC(lm(object), bw = sandwich::bwAndrews, kernel = "Quadratic Spectral", approx = "AR(1)", sandwich = TRUE)%*%norm_matrix
    } else {
      Cn = norm_matrix%*%(design_qr)%*%t(design)%*%object@Cov_ST%*%design%*%(design_qr)%*%norm_matrix
    }
  } else {
    Cn = norm_matrix%*%(design_qr)%*%t(design)%*%toeplitz(object@cov_st)%*%design%*%(design_qr)%*%norm_matrix
    # Gamma_tilde = toeplitz(object@cov_st)
  }
  #Projection sdp for Cn
  if ((object@method_cov_st=="efromovich") | (object@method_cov_st=="kernel") | (object@method_cov_st=="select")) {
    Cn_diag = eigen(Cn)
    valp = Cn_diag$values
    for (i in seq(1,length(valp))) {
      if (valp[i] <= 0) valp[i] = min(valp[valp>=0]) #treshold, smallest positive eigenvalue of Cn
    }
    Cn = Cn_diag$vectors%*%diag(valp)%*%solve(Cn_diag$vectors)
  }
  return(Cn)
}

#' @title Risk estimation for a tapered covariance matrix estimator via bootstrap method
#'
#' @description This function computes an estimation of the risk for the tapered covariance matrix estimator of a process via a bootstrap method,
#'  for a specified treshold and a specified kernel.
#'
#' @param epsilon numeric vector. An univariate process.
#' @param treshold integer. Number of estimated autocovariance terms that we consider for the estimation of the covariance matrix.
#' @param block_size integer. The size of the bootstrap blocks. \code{block_size} must be greater than \code{model_max}.
#' @param block_n integer. Blocks number used for the bootstrap.
#' @param model_max integer. The maximal dimension, that is the maximal number of terms available to estimate the covariance matrix.
#' @param kernel_fonc function. The kernel to use. The user can define his own kernel and put it in the argument.
#'
#@details The goal of this function is to estimate the risk of the tapered covariance matrix estimator via
#a boostrap approach (see the article of W.B. Wu and M. Pourahmadi (2009), Banding sample autocovariance matrices of
#stationary processes, \emph{Statistica Sinica}, pp. 1755–1768). We begin defining the target matrix, built with the estimated
#covariances of the process \code{epsilon}, from the variance to the covariance with the lag \code{model_max - 1}.
#We define \code{block_n} bootstrap block with size \code{block_size} randomly. For each block, we define the covariance matrix
#estimator built with the covariances from lag 0 to lag \code{treshold - 1}, then we smooth this vector with the kernel, in the argument
#\code{kernel_fonc}. Then we compute the matrix norm between the target matrix and the estimator. The final risk is the average on all blocks.
#'
#' @return This function returns a list with:
#'  \item{risk}{for one treshold, the value of the estimated risk.}
#'  \item{SE}{the standard-error due to the bootstrap.}
#'
#' @references
#'  E. Caron, J. Dedecker and B. Michel (2019). Linear regression with stationary errors: the R package slm. \emph{arXiv preprint arXiv:1906.06583}.
#'  \url{https://arxiv.org/abs/1906.06583}.
#'
#' @export
Rboot <- function(epsilon,treshold,block_size,block_n,model_max,kernel_fonc){
  n = length(epsilon)
  b = block_size
  cov_epsilon = as.vector(acf(epsilon,type="covariance",lag.max = n-1,plot=FALSE)$acf)
  target = toeplitz(cov_epsilon[1:model_max])
  risk_sigma = rep(0,block_n)
  block_init = sample.int(n-b+1,size=block_n,replace=FALSE)
  #prevoir un message d erreur si la taille des blocs est superieur a n
  #choix d'un certain nombre de blocs pris aleatoirement
  for (j in seq(1,block_n)) {
    residus_bootstrap = epsilon[block_init[j]:(block_init[j]+b-1)] #nu-eme bloc de taille b
    cov_bootstrap = rep(0,model_max) #gamma(0) -> gamma(model_max-1)
    cov_bootstrap[1:treshold] = acf(residus_bootstrap, type="covariance", lag.max=treshold, plot=FALSE)$acf[1:treshold] #residual autocov for the block nu
    cov_bootstrap = as.vector(cov_bootstrap)
    kern = rep(0,model_max)
    kern[1:treshold] = kernel_fonc((0:(treshold-1))/treshold)
    smooth_cov_bootstrap = kern*cov_bootstrap #smoothing of the covariance spectra
    sigma_res_blnu_hat = toeplitz(smooth_cov_bootstrap)
    risk_sigma[j] = max(apply(abs(sigma_res_blnu_hat - target),1,sum))
  }
  SE = sd(risk_sigma)
  risk = (1/block_n)*sum(risk_sigma) #R_hat, for one treshold
  risk_SE = c(risk,SE)
  return(risk_SE)
}

#' @title Kernel triangle
#'
#' @param x a vector of real numbers.
#'
#' @return This function computes the values of the triangle kernel at points \code{x}.
#'
#' @export
#'
#' @examples
#' x = seq(-2,2,length=1000)
#' y = triangle(x)
#' plot(x,y)
triangle <- function(x){
  y = (1 - abs(x))*(abs(x) <= 1)
  #kern[1:bwidth] = (1 - ((0:(bwidth-1))/bwidth))*((0:(bwidth-1))/bwidth <= 1)
  #on fera pareil mais ou x represent un des elements du vecteur du kernel
  return(y)
}

#' @title Trapeze kernel
#'
#' @param x a vector of real numbers.
#' @param width a number between 0 and 1.
#'
#' @return This function computes the values of the trapeze kernel at points \code{x}.
#'
#' @export
#'
#' @examples
#' x = seq(-2,2,length=1000)
#' y = trapeze(x, width=0.5)
#' plot(x,y)
trapeze <- function(x, width = 0.8){
  s = 1/(1-width)
  y = 1*(abs(x) <= width) + (s-s*abs(x))*((width < abs(x))) - (s-s*abs(x))*((abs(x) > 1))
  return(y)
}

#' @title Rectangular kernel
#'
#' @param x a vector of real numbers.
#'
#' @return This function computes the values of the rectangular kernel at points \code{x}.
#'
#' @export
#'
#' @examples
#' x = seq(-2,2,length=1000)
#' y = rectangle(x)
#' plot(x,y)
rectangle <- function(x){
  y = 1*(abs(x) <= 1)
  return(y)
}

#for a column, return the test-stat (zj) and the p-value
# #' @title One-parameter test
# #'
# #' @description For a given integer j, this function computes the test statistic for H0: \eqn{\beta_{j} = 0} and its
# #'  associated p-value.
# #'
# #' @param object an object of class slm.
# #' @param j an integer.
# #'
# #' @return The function returns the test statistic and the associated p-value.
# #'
# #' @export
# #'
# #' @examples
# #' data("shan")
# #' reg = slm(shan$PM_Xuhui ~ . ,data = shan, method_cov_st = "fitAR", model_selec = -1)
# #' test_stat(reg, 2)
# test_stat = function(object,j) {
#   beta_j = object$coefficients[j] #hat beta j
#   norm_matrix = object@norm_matrix
#   Cn = cov_matrix_estimator(object)
#   Zj = norm_matrix[j,j]*beta_j/sqrt(Cn[j,j])
#   pval = 2*(1-pnorm(abs(Zj),mean=0,sd=1))
#   return(c(Zj,pval))
# }


