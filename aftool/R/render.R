af_render <- function(scene_title, object){

  template <- readLines(system.file("templates/basic.html", package="aftool"))
  template_args <- new.env()
  template_args$title <- scene_title
  template_args$file <- object
  af_html <- purrr::map(template, ~stringr::str_interp(., template_args))

  # Create request router for VR app
  request_router <- routr::Route$new()

  # Handler for app root
  handle_root <- function(request, response, keys, ...) {
    response$status <- 200L
    response$type <- 'html'
    response$body <- paste0(af_html, collapse = "\r\n")
    return(FALSE)
  }

  # Handler for object JSON file
  handle_object <- function(request, response, keys, ...){
    response$status <- 200L
    response$type <- "json"
    response$body <- readr::read_lines(object)
  }

  # Attach handlers
  request_router$add_handler('get', "/", handle_root)
  request_router$add_handler('get', gsub(pattern = "^\\.",replacement = "", object), handle_object)

  # Create Route Stack
  routr_stack <- routr::RouteStack$new()
  routr_stack$add_route(request_router)

  # Create VR app
  app <- fiery::Fire$new()
  app$attach(routr_stack)
  app$ignite(block = TRUE)
  # In Terminal (or visit in browser)
  # curl http://127.0.0.1:8080/
}


