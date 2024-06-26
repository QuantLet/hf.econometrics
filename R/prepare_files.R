#' Preprocess LM jump test result
#'
#' Convenience functionalities for subsetting the jump results, changing the significance level, splitting the jumps into different waves, adding a Bonferroni correction, splitting the data by exchange / symbol, and modifying the variation measure for the test statistic
#'
#' @import data.table
#'
#' @param DATA The output from `LM_JumpTest_2012`.
#' @param subs_date A vector with dates can be provided to subset from. Defaults to NA.
#' @param sign_level The significance level for detecting jumps. Defaults to 0.01.
#' @param split_waves Should the data be split into jump waves? Defaults to FALSE.
#' @param wave_dist If `split_waves = TRUE`, where to set the splits? E.g. if no jump for longer than `wave_dist = 5`, the wave is over. This is adaptive w.r.t. to minutely / secondly frequency. Defaults to NA.
#' @param wave_size Lower threshold of jumps needed to be in a wave for it to be considered? Defaults to 5, i.e. only waves with at least 5 jumps will be kept in the end. Set to 1 for all jumps to be included.
#' @param bonferroni Should a Bonferroni correction be performed? Defaults to TRUE.
#' @param DIFF_ID Should the data be evaluated by exchange and symbol or just by exchange? Defaults to FALSE, i.e. jumps are calculated per symbol.
#' @param asymptotic_variation Should the asymptotic variation be used for calculating the test statistic? Defaults to FALSE, s.t. the empirical variation is used.
#' @param hourly Is the test statistic calculated hourly? This can be useful for very high frequency data. Defaults to FALSE.

#' @export
preprocess_jump_data <- function(DATA,
                          subs_date = NA,
                          sign_level = 0.01,
                          split_waves = FALSE,
                          wave_dist = NA,
                          wave_size = 5,
                          bonferroni = TRUE,
                          DIFF_ID = FALSE,
                          asymptotic_variation = FALSE,
                          hourly = FALSE){

  ## choose DT_LM_jump_only ##
  DT_LM_jump_only <- copy(DATA)
  if (!typeof(DT_LM_jump_only[,date]) == "character") DT_LM_jump_only[, date := as.character(date)]
  if (!is.na(subs_date)) {DT_LM_jump_only <- DATA[date %in% subs_date]}
  if(! "hour" %in% names(DT_LM_jump_only)) DT_LM_jump_only[, hour := hour(t)] # if no h available
  setkey(DT_LM_jump_only, t)
  ## ##

  ## evaluate per symbol + exchange or only per symbol? ##
  if(DIFF_ID == FALSE){ # if no exchange ID available
    which_id <- quote(s)
  } else {
    which_id <- quote(id_s)
  }
  ##

  ## Adjust sign. level + Bonferroni correction ##
  DT_LM_jump_only[, 'sign_level' := sign_level]

  if (bonferroni == TRUE) {

    if (hourly == TRUE){
      DT_LM_jump_only[DT_LM_jump_only[, (.N), , by=c("date", "hour", "id", "s")], n_obs_sample := i.V1, on=c("date", "hour", "id", "s")]
    }

    if (hourly == FALSE){
      DT_LM_jump_only[DT_LM_jump_only[, (.N), , by=c("date", "id", "s")], n_obs_sample := i.V1, on=c("date", "id", "s")]
    }
    DT_LM_jump_only[, 'sign_level' := sign_level/n_obs_sample] # bonferroni correction
  }

  DT_LM_jump_only[,'betastar' := -log(-log(1-sign_level))]
  DT_LM_jump_only[,'criticalvalue' := betastar*B_n + A_n]

  if (asymptotic_variation == FALSE) {
    DT_LM_jump_only[, 'Chi_t_j' := sqrt(M) / sqrt(Vn) * L_t_j]
  } else if (asymptotic_variation == TRUE) {
    DT_LM_jump_only[, 'Chi_t_j' := sqrt(M) / sqrt(plim_Vn) * L_t_j]
  }

  DT_LM_jump_only[,'Jump_indicator' := as.numeric(abs(Chi_t_j) > criticalvalue)]
  DT_LM_jump_only[,'Jump_indicator' := Jump_indicator*sign(Chi_t_j)]
  DT_LM_jump_only <- DT_LM_jump_only[Jump_indicator != 0]

  if(nrow(DT_LM_jump_only) == 0) {print("No jumps detected"); return(data.table())}

  if (split_waves == TRUE){
    ## make a separation between jump waves ##

    # add observation counter #
    DT_LM_jump_only[, obs_N := 1:nrow(DT_LM_jump_only)]

    # count time between observed jumps #
    DT_LM_jump_only[, t_diff := as.difftime(t-shift(t, type = "lag"))][, id_s := paste(id,s,sep="_")]

    # prepare variables for loop #
    if (units(DT_LM_jump_only$t_diff) == "secs" ){
      splits <- DT_LM_jump_only[t_diff > wave_dist]$obs_N # where to set splits? t_diff/60 > x -> if no jump for longer than x min, wave over
    } else if (units(DT_LM_jump_only$t_diff) == "mins" ) {
      splits <- DT_LM_jump_only[t_diff*60 > wave_dist]$obs_N
    }
    start <- 1
    end <- nrow(DT_LM_jump_only)
    split_list <- vector(mode = "list", length = length(splits)+1) # preassign list

    # fill first list entry manually #
    split_list[[1]] <- start:(splits[1]-1)

    # add all other values manually (this will fail for the last entry) #
    for (i in 1:(length(splits))){
      if (!is.na(splits[i+1]))
        split_list[[i+1]] <- (splits[i]):(splits[i+1]-1)
    }

    # because of the error in the last value, add last entry manually again #
    split_list[[length(split_list)]] <-  last(splits):end

    # split the data table at the previously determined breakpoints and add a rank variable #
    list_LM_jump_only <- lapply(split_list, function(x) DT_LM_jump_only[x][, rank := .GRP, by  = t][, index := 1:nrow(DT_LM_jump_only[x])])

    # keep only those with more than N values (arbitrary threshold) #
    list_LM_jump_only <- list_LM_jump_only[which(sapply(list_LM_jump_only, function(x) nrow(x)) >= wave_size)]

    # rebind the data with the rankings per wave#
    DT_LM_jump_only <- rbindlist(list_LM_jump_only, idcol = "wave_ID")
  }

  setkey(DT_LM_jump_only, t)
  return(DT_LM_jump_only)
}
