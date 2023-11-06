
##Folder where results should be saved
res_path <- "Temp"
data_path <- "Data"
lib_path <- "Libraries"

##Starting year for model setup
st_year <-  1990
##End year for the model setup
end_year <- 2022

## Path to the basin shape file
basin_path <- system.file("extdata", "GIS/basin.shp", package = "SWATprepR")

## Path to weather data
## Description of functions and how data example was prepared is on this webpage
## https://biopsichas.github.io/SWATprepR/articles/weather.html
weather_path <- paste0(data_path, '/for_prepr/met.rds')

## Path to point data
## Description of functions and how data example was prepared is on this webpage
## https://biopsichas.github.io/SWATprepR/articles/psources.html
temp_path <- system.file("extdata", "pnt_data.xlsx", package = "SWATprepR")

out_path <- "../../"
buildr_data <- paste0(data_path, "/for_buildr/")

##------------------------------------------------------------------------------
## SWATbuilder settings 
##------------------------------------------------------------------------------

# Set input/output paths -------------------------------------------
#
# Project path (where output files are saved) ----------------------
project_path <- paste0(out_path, res_path, '/buildr_project')
project_name <- 'cs4_project'

# Path of the TxtInOut folder (project folder where the SWAT+ text
# files are written with the SWAT+Editor)
txt_path <- paste0(out_path, res_path, '/buildr_project/cs4_project/txt')

# Input data -------------------------------------------------------
## DEM raster layer path
dem_path <- paste0(out_path, buildr_data, 'DEM.tif')

##Soil raster layer and soil tables paths
soil_layer_path  <- paste0(out_path, buildr_data, 'SoilmapSWAT.tif')
soil_lookup_path <- paste0(out_path, buildr_data, 'Soil_SWAT_cod.csv')
soil_data_path   <- paste0(out_path, buildr_data, 'usersoil_lrew.csv')

## Land input vector layer path
land_path <- paste0(out_path, buildr_data, 'land.shp')

## Channel input vector layer path 
channel_path <- paste0(out_path, buildr_data, 'channel.shp')

## Catchment boundary vector layer path, all layers will be masked by the
## basin boundary
bound_path <- paste0(out_path, buildr_data, 'basin.shp')

## Path to point source location layer
point_path <- paste0(out_path, buildr_data, 'pnt.shp')

# Settings ---------------------------------------------------------
## Project layers
## The input layers might be in different coordinate reference systems (CRS). 
## It is recommended to project all layers to the same CRS and check them
## before using them as model inputs. The model setup process checks if 
## the layer CRSs differ from the one of the basin boundary. By setting 
## 'proj_layer <- TRUE' the layer is projected if the CRS is different.
## If FALSE different CRS trigger an error.
project_layer <- TRUE

## Set the outlet point of the catchment
## Either define a channel OR a reservoir as the final outlet
## If channel then assign id_cha_out with the respective id from the 
## channel layer:
id_cha_out <- 40

## If reservoir then assign the respective id from the land layer to
##  id_res_out, otherwise leave as set
id_res_out <- NULL

## Threshold to eliminate land object connectivities with flow fractions
## lower than 'frc_thres'. This is necessary to i) simplify the connectivity
## network, and ii) to reduce the risk of circuit routing between land 
## objects. Circuit routing will be checked. If an error due to circuit 
## routing is triggered, then 'frc_thres' must be increased to remove 
## connectivities that may cause this issue.
frc_thres <- 0.4

## Define wetland land uses. Default the wetland land uses from the SWAT+ 
## plants.plt data base are defined as wetland land uses. Wetland land uses
## should only be changed by the user if individual wetland land uses were 
## defined in the plant data base.
wetland_landuse <- c('wehb', 'wetf', 'wetl', 'wetn')

## Maximum distance of a point source to a channel or a reservoir to be included
## as a point source object (recall) in the model setup
max_point_dist <- 500 #meters