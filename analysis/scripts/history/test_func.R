source('asrt_ana_functions.R')



sid <- 1
#tasktype <- 'motor'
tasktype <- 'percept'

#seqtype <- 'epoch'
unitx <- 'block'

finfo <- list_file(tasktype)
fpth1 <- select_file('sub103', finfo)
fpth2 <- select_file('sub0103', finfo)

d1 <- import(fpth1)
d2 <- import(fpth2)
dbind <- bind_rows(d1, d2)

#d_add_cond <- add_condition_cols(fpth, tasktype)
#d_add_freq <- assign_freq(d_add_cond)
#d_summary <- create_summ4plot(d_add_freq, unitx)
#fig <- asrt_plot2(seqtype, tasktype, d_summary, finfo, sid)
