source('asrt_ana_functions.R')



sid <- 1
tasktype <- 'motor'
#seqtype <- 'epoch'
seqtype <- 'block'

finfo <- list_file(tasktype)
fpth <- select_file(sid, finfo)
d_add_cond <- add_condition_cols(fpth, tasktype)
d_add_freq <- assign_freq(d_add_cond)
d_summary <- create_summ4plot(d_add_freq, seqtype)
fig <- asrt_plot2(seqtype, tasktype, d_summary, finfo, sid)
