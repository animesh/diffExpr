library(jsonlite)
x <- fromJSON("http://proteomecentral.proteomexchange.org/cgi/GetJSON")
save(x, file = paste0("data_", make.names(Sys.time()), ".Rda"))
