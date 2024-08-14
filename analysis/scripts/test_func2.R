source('asrt_ana_functions.R')



#sid <- 1
tasktype <- 'motor'
#tasktype <- 'percept'


unitx <- 'epoch'
#unitx <- 'block'


sidstr <- 'sub104'
finfo <- list_file(tasktype)
fpth <- select_file(sidstr, finfo)

d <- import_d(fpth, tasktype)
d_add_cond <- add_condition_cols(d, tasktype)
d_add_freq <- assign_freq(d_add_cond)
d_summary <- create_summ4plot(d_add_freq, unitx)
#figrt <- asrt_plot(unitx, tasktype, d_summary, finfo, sidstr, FALSE, 10)
#print(figrt)
#figacc <- asrt_acc_plot(unitx, tasktype, d_summary, finfo, sidstr, TRUE, 10)
#print(figacc)

report <- extr_stiseq_respseq(d, d_add_cond) #extract sti and response sequence
dfresp <- report$reportseq
stiseq <- report$stiseq

learning_res <- compute_learning_metrics(d_summary)
plot_combined_learning_metrics(learning_res, 
                               finfo, sidstr,
                               unitx = unitx, 
                               fontsize = 12, show_legend = TRUE, 
                               legend_text_size = 10)
