af_render <- function(scene_title, object){

  template <- readLines(system.file("templates/basic.html", package="aftool"))
  template_args <- new.env()
  template_args$title <- scene_title
  template_args$file <- object
  af_html <- purrr::map(template, ~stringr::str_interp(., template_args))

  vr_app <- list(
    call = function(req){
      list(
        status = 200L,
        headers = list(
          'Content-Type' = 'text/html'
        ),
        body = paste0(af_html, collapse = "\r\n")
      )
   }
  )

  httpuv::runServer(host = "0.0.0.0",
                    port = 8080,
                    app = vr_app)

  # Create handler router for VR app


  # Create VR app

}


