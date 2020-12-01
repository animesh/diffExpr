# Differential Expression Analysis [Protein/Gene/...]
batch analysis, deployed via GH actions to heroku 
<br><br>
app: https://differential-expression.herokuapp.com/ 
<br><br>
source: https://github.com/animesh/scripts/blob/master/diffExprPlots.rmd 
mailto: sharma.animesh@gmail.com?subject=%22diffExpr%20App%22
base: https://medium.com/analytics-vidhya/deploying-an-r-shiny-app-on-heroku-free-tier-b31003858b68 

# deps
install.packages("renv")
renv::restore()
renv::activate()
install.packages("withr")
install.packages("shiny")
install.packages("shinydashboard")
install.packages("shinydashboardPlus")
install.packages("dashboardthemes")
install.packages("tidyverse")
install.packages("ggmap")
install.packages("shinyalert")
install.packages("rworldmap")

# run
?register_google
runApp('shiny_geocode')
