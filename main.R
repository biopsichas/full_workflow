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
