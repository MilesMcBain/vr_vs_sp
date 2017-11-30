f <- system.file("extdata/gebco1.tif", package = "anglr")
r <- raster::raster(f)

library(sf)
#nc <- read_sf(system.file("shape/nc.shp", package="sf"))
library(rnaturalearth)
#states <- rnaturalearth::ne_states(country =  "Australia")
#east <- subset(states, name %in% c("Victoria", "New South Wales", "Australian Capital Territory", "Queensland"))
#east <- subset(states, name == "New South Wales")
map <- rnaturalearth::ne_countries()

library(raster)
library(anglr) ## devtools::install_github("hypertidy/anglr")

## objects
## a relief map, triangles grouped by polygon with interpolated raster elevation 
p_mesh <- anglr(map, max_area = 1) ##  ( sq lon-lat degree)
#g <- anglr(graticule::graticule(-85:-74, 32:37))
p_mesh$v$z_ <- raster::extract(r, cbind(p_mesh$v$x_, p_mesh$v$y_), method = "bilinear") * 
  1000 ## we have to exaggerate
p_mesh <- globe(p_mesh)
## plot the scene
library(rgl)

rgl.clear()  ## rerun the cycle from clear to widget in browser contexts 
plot(p_mesh) 
#plot(g, color = "white") 
bg3d("black"); material3d(specular = "black")
rglwidget(width =  900, height = 450)  ## not needed if you have a local device
