library(sf)
library(raster)
library(anglr) ## devtools::install_github("hypertidy/anglr")

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
acp_extent <- st_as_sf(as(extent( st_bbox(acp)[c(1, 3, 2, 4)] + c(1, -1, 1, -1) * 0.0001 ), "SpatialPolygons"))
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

rgl.clear()
plot(acp_extent_mesh)

# Determine the face colours



library(tidyverse)
vertices <-
   acp_extent_mesh$v %>%
   mutate(v_ind = seq(0, n()-1)) %>%
   mutate_if(is_double, ~scale(., center = TRUE, scale = FALSE))

faces_3js <-
   acp_extent_mesh$tXv %>%
   left_join(vertices) %>%
   select(triangle_, v_ind) %>%
   nest(v_ind) %>%
   pull(data) %>%
   map( ~paste0(.$v_ind, collapse=",")) %>%
   unlist() %>%
   paste0(" 2, ", .,", 0", collapse=",")

vertices_3js <-
  vertices %>%
  select(x_, y_, z_) %>%
  transpose() %>%
  map( ~paste0(., collapse=",")) %>%
  paste0( ., collapse=", ")

normals_3js <- ""
colors_3js <- ""
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
                "colorAmbient": [0, 0, 0],
                "colorDiffuse": [0.4784314, 0.9568627, 0.25882305],
                "colorEmissive": [0.0, 0.0, 0.0],
                "colorSpecular": [0.4784314, 0.9568627, 0.25882305],
                "depthTest": true,
                "depthWrite": true,
                "shading": "Phong",
                "specularCoef": 0.0,
                "transparency": 1.0,
                "transparent": false,
                "vertexColors": false}],
  "vertices": [ %s ],
  "normals":  [ %s ],
  "colors":   [ %s ],
  "uvs":      [ %s ],
  "faces": [
  %s
  ]}
  ',
  vertices_3js, normals_3js, colors_3js, uvs_3js, faces_3js)
  writeLines(output, "test_acp.json")



