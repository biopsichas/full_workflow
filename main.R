# Workflow joing all packages for setup preparation ----------------------------
# 
# Version 0.0.1
# Date: 2023-10-29
# Developers: Svajunas Plunge    svajunas_plunge@sggw.edu.pl
# 
# ------------------------------------------------------------------------------

##------------------------------------------------------------------------------
## 1) Check if result folder (Temp) exist, if not create it.
##------------------------------------------------------------------------------

if (!file.exists("Temp")) dir.create("Temp", recursive = TRUE)

##------------------------------------------------------------------------------
## 2) Run buildR
##------------------------------------------------------------------------------

##Please make sure swatbuildr.R includes correct path to your settings and your
##settings includes correct settings in relation to swatbuildr.R file location
source('Libraries/bildr_script/swatbuildr.R', chdir=TRUE)

##------------------------------------------------------------------------------
## 3) Add weather and atmospheric deposition data to setup
##------------------------------------------------------------------------------

## Description of functions and how data example was prepared is on this webpage
## https://biopsichas.github.io/SWATprepR/articles/weather.html

##Loading library
library(SWATprepR)

##Setting paths to the data
basin_path <- system.file("extdata", "GIS/basin.shp", package = "SWATprepR")
db_path <- "Temp/buildr_project/cs4_project/cs4_project.sqlite"

##Loading weather data and downloading atmospheric deposition
met <- readRDS('Data/for_prepr/met.rds')
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
## 5) Write files files into txtinout
##------------------------------------------------------------------------------

##Directory of setup .sqlite database 
dir_path <- file.path(dirname(db_path))

# Copy write.exe into the destination directory
file.copy(from = "Libraries/write.exe", to = paste0(dir_path, "/", "write.exe"), 
          overwrite = TRUE)

##Reset working directory to setup location
wd_base <- getwd()
if (str_sub(getwd(), -nchar(dir_path), -1) != dir_path) setwd(dir_path)

##Write files
system("write.exe")

##Reset back working directory
setwd(wd_base)

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

temp_path <- system.file("extdata", "pnt_data.xlsx", package = "SWATprepR")
pnt_data <- load_template(temp_path)
prepare_ps(pnt_data, dir_path)

##------------------------------------------------------------------------------
## 8) Run SWATfamR input preparation script
##------------------------------------------------------------------------------
in_dir <- "Libraries/farmR_input"
source(paste0(in_dir, "/write_SWATfarmR_input.R"), chdir=TRUE)
files <- list.files(in_dir, pattern = "\\.csv$")
out_dir <- "Temp/farmR_input"
if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE)
dir.create(out_dir)
file.copy(paste0(in_dir, "/", files), "Temp/farmR_input")
file.remove(paste0(in_dir, "/", files))

##------------------------------------------------------------------------------
## 9) Additional editing of farmR_input.csv file (required for SWATfarmR)
##------------------------------------------------------------------------------

mgt <- "Temp/farmR_input/farmR_input.csv"
mgt_file <- read.csv(mgt)
mgt_file[] <- lapply(mgt_file, gsub, pattern = "field_", 
                     replacement = "f", fixed = TRUE)
mgt_file <- bind_rows(mgt_file, lapply(mgt_file, gsub, pattern = "_lum", replacement = "_drn_lum", fixed = TRUE))
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
## 11) Update time.sim
##------------------------------------------------------------------------------
st_year <-  1990
end_year <- 2022

f_write <- paste0(dir_path, "/", "time.sim")
time_sim <- read.delim(f_write)
write.table(paste0("time.sim: written on ", Sys.time()), f_write, append = FALSE,
            sep = "\t", dec = ".", row.names = FALSE, col.names = FALSE, quote = FALSE)
st_hd <- c(rep('%9s', 5))
write.table(paste(sprintf(st_hd, unlist(strsplit(time_sim[1,1], "\\s+"))), collapse = ' '), 
            f_write, append = TRUE, sep = "\t", dec = ".", row.names = FALSE, col.names = FALSE, quote = FALSE)
time_sim_v <- as.numeric(unlist(strsplit(time_sim[2,1], "\\s+"))[-1])
time_sim_v[c(2, 4)] <- c(st_year, end_year)
write.table(paste(sprintf(st_hd, time_sim_v), collapse = ' '), 
            f_write, append = TRUE, sep = "\t", dec = ".", row.names = FALSE, col.names = FALSE, quote = FALSE)

##------------------------------------------------------------------------------
## 12) Run SWAT+ model
##------------------------------------------------------------------------------

# Copy write.exe into the destination directory
file.copy(from = "Libraries/swat.exe", to = paste0(dir_path, "/", "swat.exe"), 
          overwrite = TRUE)


if (str_sub(getwd(), -nchar(dir_path), -1) != dir_path) setwd(dir_path)

##Write files
system("swat.exe")

##Reset back working directory
setwd(wd_base)

##------------------------------------------------------------------------------
## 13) Run SWATfamR 
##------------------------------------------------------------------------------
library(SWATfarmR)
frm <- SWATfarmR::farmr_project$new(project_name = 'frm', project_path = dir_path)
api <- variable_decay(frm$.data$variables$pcp, -5,0.8)
asgn <- select(frm$.data$meta$hru_var_connect, hru, pcp)
frm$add_variable(api, "api", asgn)
frm$read_management(mgt, discard_schedule = TRUE)
frm$schedule_operations(start_year = 1998, end_year = 2022, replace = 'all')
frm$write_operations(start_year = 1998, end_year = 2022)

##Should be aligned with SWATfarmr input as rotations will be starting wrong for calibration and validation
## Means 2017 2022 farmr input was wrongs
## this means weather should be extended back to 1990 or so 
