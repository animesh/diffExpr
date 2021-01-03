#library(jsonlite)
x <- read.csv(url("http://proteomecentral.proteomexchange.org/cgi/GetJSON"))
write.csv(as.data.frame(x),paste0("data_",make.names(Sys.time()), ".Rda"))
