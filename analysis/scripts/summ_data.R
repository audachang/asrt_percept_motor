source('asrt_ana_functions.R')

all_tasktypes <- c("motor", "percept")
tasktype <- 'motor'




unitx <- 'epoch'
#unitx <- 'block'

all_d_summary <- tibble()
all_reportseq <- tibble()
all_sequence_learning <- tibble()
all_statistical_learning <- tibble()

for (tasktype in all_tasktypes){
  finfo <- list_file(tasktype)
  for (sidstr in finfo$sids) {
  
      fpth <- select_file(sidstr, finfo)
      d <- import_d(fpth, tasktype)
      d_add_cond <- add_condition_cols(d, tasktype)
      d_add_freq <- assign_freq(d_add_cond)
      d_summary <- create_summ4plot(d_add_freq, unitx)
      
      d_summary <- d_summary %>%
        mutate(sid = sidstr, tasktype = tasktype)
      
      
      report <- extr_stiseq_respseq(d, d_add_cond) #extract sti and response sequence
      
      report$reportseq <- report$reportseq %>%
        mutate(sid = sidstr, tasktype = tasktype)
      
      learning_res <- compute_learning_metrics(d_summary)
      learning_res$sequence_learning <- learning_res$sequence_learning %>%
        mutate(sid = sidstr, tasktype = tasktype)
      learning_res$statistical_learning <- learning_res$statistical_learning %>%
        mutate(sid = sidstr, tasktype = tasktype)
      
      all_d_summary <- bind_rows(all_d_summary, d_summary) 
      all_reportseq <- bind_rows(all_reportseq, report$reportseq) 
      all_sequence_learning <- bind_rows(
        all_sequence_learning, learning_res$sequence_learning) 
      all_statistical_learning <- bind_rows(
        all_statistical_learning, learning_res$statistical_learning) 
  }
  

}

export(all_d_summary, file = '../proc_data/all_d_summary.csv')
export(all_reportseq, file = '../proc_data/all_reportseq.csv')
export(all_sequence_learning, file = '../proc_data/all_sequence_learning.csv')
export(all_statistical_learning, file = '../proc_data/all_statistical_learning.csv')

