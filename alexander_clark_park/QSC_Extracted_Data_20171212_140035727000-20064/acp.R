library(sf)
library(raster)
library(anglr) ## devtools::install_github("hypertidy/anglr")
library(rgl)
library(tidyverse)

# read shape file:
acp <- read_sf("./alexander_clark_park/QSC_Extracted_Data_20171212_140035727000-20064/Contours_1_metre.shp")

# convert contours to raster
acp_elev_raster <- 
  contour_2_raster(acp, 
                   n_samples = 100000,
                   raster_attribute = "ELEVATION",
                   ncol = 120,
                   nrow = 120)

# Create an extent to triangulate
acp_extent <- st_as_sf(as(extent( st_bbox(acp)[c(1, 3, 2, 4)] + c(1, -1, 1, -1) * 0.0005 ), "SpatialPolygons"))
acp_extent$z <- 0
# Set its spatial meta data
st_crs(acp_extent) <- st_crs(acp)

# make a mesh and set z to our raster
acp_extent_mesh <- anglr(acp_extent, max_area = 0.00000001)



acp_extent_mesh$v$z_ <- 
  raster::extract(acp_elev_raster/12000, # This is approximately right, I think.
                  cbind(acp_extent_mesh$v$x_, acp_extent_mesh$v$y_), method = "bilinear")
acp_extent_mesh$v <- tidyr::fill(acp_extent_mesh$v, z_)
acp_extent_mesh$v$z_

#rgl.clear()
#plot(acp_extent_mesh)

# Determine the face vertex colours
# Use the vegetation raster later.
terrain_pal_256 <- 
  terrain.colors(256) %>%
  rev() %>%
  map(~col2rgb(.)) %>%
  map(~rgb(red = .[1], green = .[2], blue = .[3], maxColorValue = 255)) %>%
  unlist() %>%
  gsub(pattern = "#", replacement = "0x", x = .) %>%
  as.numeric()
  
# Colours are indexed so we just need to assign the vertex index to the colour: 0 - 255
vegetation_raster <- raster("alexander_clark_park/slatsfpc2013/")

acp_extent_mesh$v <-
  acp_extent_mesh$v %>%
  mutate(value = raster::extract(vegetation_raster,
                  cbind(acp_extent_mesh$v$x_, acp_extent_mesh$v$y_), method = "bilinear")) %>%
  tidyr::fill(value) %>%
  mutate(colour = round( ((value - 100)/79)*255 ) )

# There's also a river which we have a shapefile for.
river_shape_file <- read_sf("alexander_clark_park/waterways/WaterwaysACP.shp")

# Add a water colour to our terrain colour palette
terrain_pal_257 <- c(terrain_pal_256, as.numeric('0x7cccba'))

acp_extent_mesh$v <- 
  acp_extent_mesh$v %>% 
  mutate(
    water = point_in_sf(x = x_, y_, river_shape_file),
    colour = if_else(water, 256 ,colour) # If the vertex is in water set the colour to something the last colour in palette (water)
  )




# Write JSON
vertices <-
   acp_extent_mesh$v %>%
   mutate(v_ind = seq(0, n()-1)) %>%
   mutate_at(c("x_", "y_"), ~scale(., center = TRUE, scale = FALSE))

faces_3js <-
   acp_extent_mesh$tXv %>%
   left_join(vertices) %>%
   select(triangle_, v_ind, colour) %>%
   nest(v_ind, colour) %>%
   pull(data) %>%
   map( ~paste0("130, ",
           paste0(.$v_ind, collapse=","),
           ", ",
           "0, ",
           paste0(.$colour, collapse=","),
           collapse=",")
       ) %>%
   unlist() %>%
   paste0(., collapse=", ")

face_vertices_3js <- 
  acp_extent_mesh$tXv %>%
   left_join(vertices) %>%
   select(triangle_, v_ind) %>%
   nest(v_ind) %>%
   pull(data) %>%
   map( ~paste0(.$v_ind, collapse = ","))


vertices_3js <-
  vertices %>%
  select(x_, y_, z_) %>%
  transpose() %>%
  map( ~paste0(., collapse=",")) %>%
  paste0( ., collapse=", ")

normals_3js <- ""

colors_3js <- 
  terrain_pal_257 %>% 
  paste0( ., collapse=", ")

uvs_3js <- ""
#########
## format out to JSON (I'm not at all sure about the uvs but it might not matter)
output <- sprintf(
  '{
  "metadata": { "formatVersion" : 3 },

  "materials": [ {"DbgColor": 15597568,
                "DbgIndex": 1,
                "DbgName": "land",
                "blending": "NormalBlending",
                "colorDiffuse": [1, 1, 1],
                "colorSpecular": [1, 1, 1],
                "depthTest": true,
                "depthWrite": true,
                "shading": "Phong",
                "specularCoef": 0.0,
                "transparency": 1.0,
                "transparent": false,
                "vertexColors": 2}],
  "vertices": [ %s ],
  "normals":  [ %s ],
  "colors":   [ %s ],
  "uvs":      [ %s ],
  "faces": [
  %s
  ]}
  ',
  vertices_3js, normals_3js, colors_3js, uvs_3js, faces_3js)
  writeLines(output, "./alexander_clark_park/test_acp.json")



