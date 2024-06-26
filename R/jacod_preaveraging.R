#' Jacod Preaveraging (2009, 2010)
#'
#' Calculate sigma_hat according to the pre-averaging approach Jacod et al. (2009, 2010)
#'
#' @import data.table
#'
#' @param DATA A data.table with structure as provided in the example.
#' @param kn The degree of subsampling during preaveraging. Defaults to 100.
#'
#' @return Returns the variation estimation

#' @export
jacod_preaveraging <- function(DATA,kn = 100){

  dz <- DATA[!is.na(log_ret), log_ret]

  # Set up constants
  gbar2 = 1/12
  phibar2 = 1/12
  phiprimebar2 = 1
  gamma = 2
  gammap = 2
  gammapp = 2
  Aprimegg = c(
    3.599999960562231,
    1.221424577286807,
    0.370635624815616,
    0.035039285812380,
    0.002315373900701)

  Aprimegh = c(
    2.725769745686566,
    0.589334298318853,
    0.122686505762394,
    0.007755996403950,
    0.000347923390644)

  Aprimehh = c(
    30.217754077981802,
    2.535050327092127,
    0.188268743583475,
    0.004415379915876,
    0.000072391168973)

  # Compute the ratio stat
  yg = YbarYhat(dz,kn,1)
  ybarg <- yg$Ybar
  yhatg <- yg$Yhat
  vvec_p4_g = Vvec(ybarg,yhatg,4)
  vbar_p4_g = vvec_p4_g[1] - 3 * vvec_p4_g[2] + 0.75 * vvec_p4_g[3]
  return(vbar_p4_g)
}
