#' Ait-Sahalia, Jacod & Li Jump Test Functions
#'
#' Helper functions for computing the Ait-Sahalia, Jacod & Li (2012) test
#'
#' @param mfun m(r) = E|N(0,1)|^r, see Jacod and Ait-Sahalia 2006 equation (10)
#' @param Vvec The jth element, j=0,...,p/2, is V(Y,g,p-2j,j) = sum |Ybar|^(p-2j) Yhat^j
#' @param rho_tilde The rho_tilde matrix in AJL2009
#' @param ...
#'
#' @import data.table
#'

#' @export
gfun <- function(x){
  return(x * (x>=0 & x<=0.5) + (1-x) * (x<=1 & x>0.5))
}

#' @export
gprimefun <- function(x){
  return(x<=0.5 & x>0) - (x>0.5 & x<1)
}

#' @export
mfun <- function(r){
  return(pi^(-1/2) * 2^(r/2) * gamma((r+1)/2))
}

#' @export
Mstar <- function (deltan,kn,p,Aprimegh,phibar2,phiprimebar2,Vvec_trunc_2p_phi){
  # Aprimegh can be computed by
  #
  # capAprime(ghandle,hhandle,gprimehandle,hprimehandle,p)
  #
  # Vvec_trunc_2p_phi can be computed by
  #
  # Vvec_trunc(Ybar,Yhat,2*p,un)

  output = 0;
  theta = sqrt(deltan) * kn

  for (w in 0:p) {
    windex = w+1;
    rho_2w = rho_vec(2*w)
    sum_rho_vstar = 0

    for (l in 0:w) {
      lindex = l+1
      sum_rho_vstar = sum_rho_vstar + rho_2w[lindex] * Vvec_trunc_2p_phi[p+lindex-w]
    }
    output = output + theta * Aprimegh[windex] / (mfun(2*w) * 2^(p-w) * phibar2^w * phiprimebar2^(p-w)) * sum_rho_vstar
  }

  output = output * deltan ^ (1-p/2)
  return(output)
}

#' @export
rho_matrix <- function (p){
  return(solve(rho_tilde(p)))
}

#' @export
rho_tilde <-  function(p){

  if (p %% 2 !=0 ) return('p should be an even integer')

  output = matrix(0, nrow =p/2+1, ncol = p/2+1)

  for (l in 0:(p/2)){
    for (j in l:(p/2)) {
      lindex = l+1
      jindex = j+1
      output[lindex,jindex] = 2^l * choose(p-2*l,2*j-2*l) * mfun(p-2*j) * mfun(2*j - 2*l) / mfun(p)
    }
  }
  return(output)
}

#' @export
rho_vec <- function(p){
  tmp = rho_matrix(p)
  tmp[1,]
}

#' @export
Vvec_trunc <- function(Ybar,Yhat,p,un){
  # Compute Vvec
  # The jth element, j=0,...,p/2, is
  # V(Y,g,p-2j,j) = sum |Ybar|^(p-2j) Yhat^j 1{|Ybar|<=un}
  #
  # Ybar2_trunc = |Ybar|^2 1{|Ybar|<=un}
  trunc = (abs(Ybar)<=un)
  Ybar2_trunc = Ybar^2 * trunc
  Yhat_trunc = Yhat*trunc

  halfp = p/2;
  output = vector(mode="numeric", length=halfp+1)

  output[1] = sum(Ybar2_trunc ^ halfp);
  output[halfp+1] = sum(Yhat_trunc ^ halfp);

  if (halfp-1 >= 1){
    for (j in 1:(halfp-1)){
      output[j+1] = sum(Ybar2_trunc ^ (halfp - j) * Yhat_trunc ^ j)
    }
  }
  return(output)
}

#' @export
Vvec <- function(Ybar,Yhat,p){
  halfp = p/2
  output = vector(mode="numeric", length=halfp+1)
  Ybar2 = Ybar ^ 2

  output[1] = sum(Ybar2 ^ halfp)
  output[halfp+1] = sum(Yhat ^ halfp)

  if (halfp-1 >= 1){
    for (j in 1:(halfp-1)){
      output[j+1] = sum((Ybar2 ^ (halfp - j) * Yhat) ^ j)
    }
  }
  return(output)
}

#' @export
YbarYhat <- function(dY,kn,k){

  # [Ybar, Yhat] = YbarYhat(dY,kn,k)
  # Compute Ybar, Yhat
  # dY: the first difference of data
  # kn: the window
  # k:  the scale parameter

  n <- length(dY)
  m <- n - kn + 1
  Ybar <- c()
  Yhat <- c()

  # Ensure m is positive for proper vector initialization
  if (m <= 0) {
    stop("Error: The calculation of 'm' results in a non-positive value, indicating an issue with 'kn' relative to the length of 'dY'.")
  }

  # The weighting vector
  g <- gfun(k*(0:kn)/kn)
  gprime2 <- (g[2:length(g)] - g[1:(length(g)-1)]) ^ 2
  g <- g[-1]

  # Compute Ybar, Yhat
  for (i in 1:m){
    tmpbar <- 0
    tmphat <- 0
    for (j in 1:kn){
      tmpbar <- tmpbar + g[(j)] * dY[(i+j-1)];
      tmphat <- tmphat + gprime2[(j)] * dY[(i+j-1)] ^ 2
    }

    Ybar[i] = tmpbar
    Yhat[i] = tmphat
  }
  return(list("Ybar" = Ybar,"Yhat" = Yhat))
}
