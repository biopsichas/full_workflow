#' Function to update single data line files
#'
#' @param txt_file data.frame of lines 
#' @param f_path character full path of files to be overwritten
#' 
update_file <- function(txt_file, f_path){
  write.table(paste0(basename(f_write), ": written on ", Sys.time()), f_path, append = FALSE,
              sep = "\t", dec = ".", row.names = FALSE, col.names = FALSE, quote = FALSE)
  write.table(txt_file[1,1], f_path, append = TRUE, sep = "\t", dec = ".", 
              row.names = FALSE, col.names = FALSE, quote = FALSE)
  write.table(txt_file[2,1], f_path, append = TRUE, sep = "\t", dec = ".", 
              row.names = FALSE, col.names = FALSE, quote = FALSE)
  print(paste0(basename(f_write), " file updated in ", dirname(f_write), " directory."))
}

#' Function to copy exe between destinations and run it
#'
#' @param path_from character path of directory from which file should be taken
#' @param path_to character path to which file should be put
#' @param file_name character names of file to copy and run

exe_copy_run <- function(path_from, path_to, file_name){
  # Copy into the destination directory
  file.copy(from = paste0(path_from, "/", file_name), 
            to = paste0(path_to, "/", file_name), overwrite = TRUE)
  
  ##Reset working directory to setup location
  wd_base <- getwd()
  if (str_sub(getwd(), -nchar(path_to), -1) != path_to) setwd(path_to)
  
  ##Write files
  system(file_name)
  
  ##Reset back working directory
  setwd(wd_base)
}
