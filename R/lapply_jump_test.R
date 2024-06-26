#' Lapply Jump Test
#'
#' Helper function to calculate test statistic for a list of datasets
#'
#' @import data.table
#'

#' @export
jump_test <- function(DATA, which_test) {##

  DT_tmp <- DATA
  progress <- round(quantile(1:length(DT_tmp), probs = seq(0,1,0.05)))
  ##

  ## get result ##
  Test_result <- rbindlist(lapply(1:length(DT_tmp), function(x) {
    if (x %in% progress) {print(Sys.time()); print(progress[which(progress == x)])}
    if (which_test == "LM_JumpTest"){
      LM_JumpTest(DT_tmp[[x]])
    } else if  (which_test == "AJL_JumpTest"){
      delta_n <- 1/365.25/(86400/DT_tmp[[x]][1, freq])
      AJL_JumpTest_2012(DT_tmp[[x]], deltan = delta_n)$result
    } else {
      which_test(DT_tmp[[x]])
    }
  })
  )
  return(Test_result)
}
