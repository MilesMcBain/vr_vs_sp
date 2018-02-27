library(raster)
library(anglr) ## devtools::install_github("hypertidy/anglr")
library(sf)
library(rgl)
library(tidyverse)

f <- system.file("extdata/gebco1.tif", package = "anglr")
## ad hoc scaling as x,y and  z are different units
r <- raster::raster(f)/1000

nc <- read_sf(system.file("shape/nc.shp", package="sf"))


## objects
## a relief map, triangles grouped by polygon with interpolated raster elevation 
p_mesh <- anglr(nc, max_area = 0.008) ## make small triangles ( sq lon-lat degree)
#g <- anglr(graticule::graticule(-85:-74, 32:37))
p_mesh$v$z_ <- raster::extract(r, cbind(p_mesh$v$x_, p_mesh$v$y_), method = "bilinear")

## plot the scene


rgl.clear()  ## rerun the cycle from clear to widget in browser contexts 
plot(p_mesh) 
#plot(g, color = "white") 
bg3d("black"); material3d(specular = "black")
rglwidget(width =  900, height = 450)  ## not needed if you have a local device



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
  writeLines(output, "test_carolina.json")
