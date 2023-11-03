############# Script to write the SWATfarmR input file
##
## required inputs in folder input_data:
##           (1) Land use map with crop information
##                 ... The map must contain the land use of each hru. In case of cropland, the names must be unique
##                 ... for each field (e.g., 'field_1', 'field_2', etc.)
##                 ... The map must also contain crop infos for the period 1988 to 2020 (or 2021 if crop info available)
##                 ... this requires an extrapolation of the available crop sequences (the sequences
##                 ... derived from remote-sensing based crop classification or local data).
##                 ... The extrapolated crop sequence for 33 years will be also used for running climate scenarios
##                 ... and must not contain any gaps. That means, gaps have to be closed manually!
##                 ... The year columns must be named y_1988, y_1989, etc.
##                 ... The crop infos for each year must match the crop_mgt names in the
##                 ... management operation schedules (provided in a .csv file, see below).
##                 ... An example land use map is provided in folder input_data.
##                 ... Replace it with your land use map (see also section 4.1 of the modelling protocol).
##           (2) Management operation schedules for each crop (or, if available, crop-management type)
##                 ... All schedules must be compiled in one csv file (see example in demo data and
##                 ... study also section 4.2 of the modelling protocol).
##                 ... 'crop_mgt' must start with the 4-character SWAT crop names (any further management specification is optional).
##                 ... Each schedule must contain a 'skip' line to indicate the change of years.
##                 ... The 'skip' line should never be the last line of a schedule.
##                 ... An example table is provided in folder input_data. Replace it with your own table.
##           (3) Management operation schedules for generic land-use classes (usually all non-cropland classes with vegetation cover).
##                 ... here, all schedules must be provided already in the SWATfarmR input format.
##                 ... An example table is provided in folder input_data. Replace it with your own table.
##
#######################################################################################

# Load functions and packages -------------------------------------------------------
source('./functions_write_SWATfarmR_input.R')

foo1(c("sf" , "tidyverse" , "lubridate", "reshape2", "remotes", "dplyr", "data.table"))
foo2("HighFreq")

# Define input files-----------------------------------------------------------------

lu_shp <- '../../Data/for_farmr_input/lu_crops.shp' # land-use crop map shapefile

mgt_csv <- '../../Data/for_farmr_input/mgt_crops.csv' # crop management .csv table

lu_generic_csv <- '../../Data/for_farmr_input/mgt_generic.csv' # generic land use management .csv table

# Define variables-------------------------------------------------------------------

## Simulation period
start_y <- 1990 #starting year (consider at least 3 years for warm-up!)
end_y <- 2022 #ending year

## Prefix of cropland hrus (all names of hrus with a crop rotation must begin
## with this prefix in column 'lu' of your land use map)
hru_crops <- 'field'

## Multi-year farmland grass
## Did you define any multi-year farmland grass schedules? 'y' (yes), 'n' (no)
m_yr_sch_existing <- 'n'

## If yes, define also the following variables. If not, skip next four lines
crop_myr <- 'fesc' # prefix of multi-year schedules in management file
# multiple entries should have the same number of characters, e.g.: crop_myr <- c('akgs', 'bsvg')
max_yr <- 5 # maximum number of years farmland grass can grow before it is killed (should be <8)
## Do your multi-year farmland grass schedules consider the type of the following crop (summer or winter crop)?
## (e.g., a '_1.5yr' schedule with a kill op in spring allows for planting a summer crop immediately afterwards)
## If yes, you must define your summer crops
crop_s <- c("barl", "csil", "sgbt", "onio", "mint", "crrt", 'corn','alfa','lett')
## Do your summer crop schedules usually start with an operation in autumn (e.g. tillage)?
## To combine them with farmland grass, it is necessary that you provide 'half-year-schedules'
## ('half-year-schedules' are additional summer crop schedules without operations in autumn)
## The adapted schedules should be added to the crop management table with suffix '_0.5yr' (e.g. 'csil_0.5yr')
## If additional 'half-year-schedules' are not needed, because your normal summer crop schedules
## do not start in autumn, type 'n'
additional_h_yr_sch_existing <- 'n' # 'y' (yes), 'n' (no)

# Read input data ----------------------------------------------------------------

## Read land-use crop map shapefile and drop geometry
lu <- st_drop_geometry(read_sf(lu_shp))

## Read crop management .csv table
## Make sure it includes all crops of your lu map
mgt_crop <- read.csv(mgt_csv, as.is=T)

## Read generic land use management .csv table
## Make sure it includes all non-cropland classes with a vegetation cover
mgt_generic <- read.csv(lu_generic_csv, as.is=T)

# Check for correct positioning of 'skip' line ------------------------------------
check_skip <- check_skip_position()

# Check for date conflicts within single crop schedules -------------------------------
check_date_conflicts1()

# Build schedules for crop sequences ----------------------------------------------
rota_schedules <- build_rotation_schedules()

# Check for date conflicts in combined (rotation) schedule --------------------------
check_date_conflicts2()

# Solve minor date conflicts (where only a few days/weeks are overlapping)---------
rota_schedules <- solve_date_conflicts()

## check again for date conflicts -------------------------------------------------
check_date_conflicts2()

## write the SWAT farmR input table -----------------------------------------------
write_farmR_input()








