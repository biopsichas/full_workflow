# Workflow joining all packages for uncalibated setup preparation --------------
# 
# Version 0.0.1
# Date: 2023-11-06
# Developers: Svajunas Plunge    svajunas_plunge@sggw.edu.pl
# 
# ------------------------------------------------------------------------------

##------------------------------------------------------------------------------
## 1) Loading  libraries, settings, functions, initializing result's directory
##------------------------------------------------------------------------------

library(SWATprepR)
library(SWATfarmR)
source('settings.R')
source('functions.R')

##If exists deleting results directory (Please be careful!!!)
if (file.exists(res_path)) unlink(res_path, recursive = TRUE)
##Creating results directory
dir.create(res_path, recursive = TRUE)

##------------------------------------------------------------------------------
## 2) Run SWATbuildR
##------------------------------------------------------------------------------

##Please make sure SWATbuilder settings are 
source(paste0(lib_path, '/bildr_script/swatbuildr.R'), chdir=TRUE)

##------------------------------------------------------------------------------
## 3) Add weather and atmospheric deposition data to setup
##------------------------------------------------------------------------------

## Description of functions and how data example was prepared is on this webpage
## https://biopsichas.github.io/SWATprepR/articles/weather.html

##Setting paths to the data
db_path <- list.files(path = getwd(), pattern = project_name, 
                      recursive = TRUE, full.names = TRUE)

##Loading weather data and downloading atmospheric deposition
met <- readRDS(weather_path)
df <- get_atmo_dep(basin_path)

##Calculating weather generator statistics
wgn <- prepare_wgn(met)

##Adding weather and atmospheric deposition data into setup
add_weather(db_path, met, wgn)
add_atmo_dep(df, db_path, t_ext = "annual")

##------------------------------------------------------------------------------
## 4) Add small modification to .sqlite 
##------------------------------------------------------------------------------

##This is needed for the write.exe to work
db <- dbConnect(RSQLite::SQLite(), db_path)
project_config <- dbReadTable(db, 'project_config')
project_config$input_files_dir <- "."
dbWriteTable(db, 'project_config', project_config, overwrite = TRUE)
dbDisconnect(db)

##------------------------------------------------------------------------------
## 5) Write files files into txtinout with write.exe
##------------------------------------------------------------------------------

##Directory of setup .sqlite database 
dir_path <- file.path(dirname(db_path))

##Copy write.exe into txtinout directory and run it
exe_copy_run(lib_path, dir_path, "write.exe")

##------------------------------------------------------------------------------
## 6) Link aquifers and channels with geomorphic flow
##------------------------------------------------------------------------------

# A SWATbuildR model setup only has one single aquifer (in its current 
# version). This aquifer is linked with all channels through a channel-
# aquifer-link file (aqu_cha.lin) in order to maintain recharge from the
# aquifer into the channels using the geomorphic flow option of SWAT+

link_aquifer_channels(dir_path)

##------------------------------------------------------------------------------
## 7) Add point sources
##------------------------------------------------------------------------------

## Description of how data should be prepared is on this webpage
## https://biopsichas.github.io/SWATprepR/articles/psources.html
pnt_data <- load_template(temp_path)
prepare_ps(pnt_data, dir_path)

##------------------------------------------------------------------------------
## 8) Run SWATfamR input preparation script
##------------------------------------------------------------------------------

##Setting directory and running Micha's SWAtfarmR input script
in_dir <- paste0(lib_path, "/farmR_input")
source(paste0(in_dir, "/write_SWATfarmR_input.R"), chdir=TRUE)

##Coping results in to results folder
files <- list.files(in_dir, pattern = "\\.csv$")
out_dir <- paste0(res_path, "/farmR_input")
if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE)
dir.create(out_dir)
file.copy(paste0(in_dir, "/", files), paste0(res_path, "/farmR_input"))
file.remove(paste0(in_dir, "/", files))

##------------------------------------------------------------------------------
## 9) Additional editing of farmR_input.csv file (required for SWATfarmR)
##------------------------------------------------------------------------------

mgt <- "Temp/farmR_input/farmR_input.csv"
mgt_file <- read.csv(mgt)
mgt_file[] <- lapply(mgt_file, gsub, pattern = "field_", 
                     replacement = "f", fixed = TRUE)
mgt_file <- bind_rows(mgt_file, lapply(mgt_file, gsub, pattern = "_lum", 
                                       replacement = "_drn_lum", fixed = TRUE))
file.remove(mgt)
write_csv(mgt_file, file = mgt, quote = "needed", na = '')

##------------------------------------------------------------------------------
## 10) Update landuse.lum
##------------------------------------------------------------------------------

if(!file.exists(paste0(dir_path, "/", "landuse.lum.bak"))) {
  file.copy(from = paste0(dir_path, "/", "landuse.lum"),
            to = paste0(dir_path, "/", "landuse.lum", ".bak"), overwrite = TRUE)
}

source('Libraries/read_and_modify_landuse_lum.R')
file.remove(paste0(dir_path, "/", "landuse.lum"))
file.rename(paste0(dir_path, "/", "landuse2.lum"),paste0(dir_path, "/", "landuse.lum"))

##------------------------------------------------------------------------------
## 11) Update nutrients.sol (if needed)
##------------------------------------------------------------------------------

f_write <- paste0(dir_path, "/", "nutrients.sol")
nutrients.sol <- read.delim(f_write)
nutrients.sol[2,1] <- gsub("5.00000", "40.4000", nutrients.sol[2,1])
update_file(nutrients.sol, f_write)

##------------------------------------------------------------------------------
## 11) Update time.sim
##------------------------------------------------------------------------------

f_write <- paste0(dir_path, "/", "time.sim")
time_sim <- read.delim(f_write)

y <- as.numeric(unlist(strsplit(time_sim[2,1], "\\s+"))[-1])
if(min(y[y>0]) != st_year){
  time_sim[2,1] <- gsub(min(y[y>0]), st_year, time_sim[2,1])
}
if(max(y[y>0]) != end_year){
  time_sim[2,1] <- gsub(max(y[y>0]), end_year, time_sim[2,1])
}

update_file(time_sim, f_write)

##------------------------------------------------------------------------------
## 12) Run SWAT+ model
##------------------------------------------------------------------------------

##Copy swat.exe into txtinout directory and run it
exe_copy_run(lib_path, dir_path, "swat.exe")

##------------------------------------------------------------------------------
## 13) Run SWATfamR 
##------------------------------------------------------------------------------

##Preparing management files
frm <- SWATfarmR::farmr_project$new(project_name = 'frm', project_path = dir_path)
api <- variable_decay(frm$.data$variables$pcp, -5,0.8)
asgn <- select(frm$.data$meta$hru_var_connect, hru, pcp)
frm$add_variable(api, "api", asgn)
frm$read_management(mgt, discard_schedule = TRUE)
frm$schedule_operations(start_year = 1998, end_year = 2022, replace = 'all')
frm$write_operations(start_year = 1998, end_year = 2022)

##------------------------------------------------------------------------------
## 14) Final SWAT model run
##------------------------------------------------------------------------------

##Copy swat.exe into txtinout directory and run it
exe_copy_run(lib_path, dir_path, "swat.exe")
print("Congradulations!!! You have pre-calibrated model!!! ")
