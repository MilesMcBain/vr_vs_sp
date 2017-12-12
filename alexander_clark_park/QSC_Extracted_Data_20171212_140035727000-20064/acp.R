library(sf)
library(raster)
library(anglr) ## devtools::install_github("hypertidy/anglr")

nc <- read_sf("./Contours_1_metre.shp")
p_mesh <- anglr(nc, max_area = 0.008)

vertexes <- reduce(list(p_mesh$v, p_mesh$lXv, p_mesh$l, p_mesh$o), left_join)
vertex_dupes <- which(duplicated(vertexes$vertex_))
p_mesh$v$z_ <- vertexes$ELEVATION[-vertex_dupes]

library(tidyverse)
vertices <- 
   p_mesh$v %>%
   mutate(v_ind = seq(0, n()-1)) %>%
   mutate_if(is_double, ~scale(., center = TRUE, scale = FALSE))

faces_3js <- 
   p_mesh$tXv %>%
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



