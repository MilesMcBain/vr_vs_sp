library(googledrive)

drive_download(
  file = googledrive::as_id("https://drive.google.com/open?id=12J-285aSC4taBmGVr6F0xZpO_H5pBNpo"),
  path = file.path('./data','GEBCO_2014_2D_-140.1818_22.6909_-50.9455_58.2545.nc')
)
