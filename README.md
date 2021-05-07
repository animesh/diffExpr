# Differential Expression Analysis [Protein/Gene/...] deployed via GH actions to shinyapp.io 
<br><br>
app: Shiny/R application for differential-expression analysis using T-test based on [VolcaNoseR](https://github.com/JoachimGoedhart/VolcaNoseR/)
<br><br>
fix: Automatically deployed via GH Actions to shinyapp.io available as https://fuzzylife.shinyapps.io/diffExpr/ using heroku deployment strategy of https://blog.simonpcouch.com/blog/r-github-actions-commit/ 
<br><br>
source: https://github.com/animesh/scripts/blob/master/diffExprANOVA.rmd 
mailto: sharma.animesh@gmail.com?subject=diffExprApp

```bash
git clone https://github.com/animesh/diffExpr
usethis::create_package(path = "diffExpr")
```
base: 

# deps
library(curl)
library(jsonlite)

# run
cron: "0 * * * *"

#### Server 
o [Install](https://rstudio.com/products/shiny/download-server/ubuntu/)
```
sudo su - -c "R -e \"install.packages(c('ggplot2','dplyr','ggrepel','shinycssloaders','readxl','DT', 'RCurl','svglite')repos='https://cran.rstudio.com/')\""
```
o log monitor *example*
```
tail -f /var/log/shiny-server/VolcaNoseR-shiny-*.log
```

o The first option is running it directly from Github. In the command line (in R or Rstudio) type:
```
shiny::runGitHub('VolcaNoseR', 'animesh')
```
o The second option is download the app and to use it offline:

-download the `app.R` and csv files (`Data-Vulcano-plot.csv` and `elife-45916-Cdc42QL_data.csv`) with example data.

-Run RStudio and load `app.R`

-Select 'Run All' (shortcut is command-option-R on a Mac) or click on "Run App" (upper right button on the window)

This should launch a web browser with the Shiny app.


### Credits

There are several Shiny apps for Volcano plots that have served as a source of inspiration:

-[VolcanoR](https://github.com/vovalive/volcanoR)

-[Volcanoshiny](https://github.com/hardingnj/volcanoshiny)

-[VolcanoPlot_shiny_app](https://github.com/stemicha/VolcanoPlot_shiny_app)


VolcaNoseR is created and maintained by Joachim Goedhart ([@joachimgoedhart](https://twitter.com/joachimgoedhart))

### Example output

Standard output generated with the example data:

![alt text](https://github.com/JoachimGoedhart/VolcaNoseR/blob/master/VolcaNoseR_example1.png "Output")

Output with user selected annotation of data:

![alt text](https://github.com/JoachimGoedhart/VolcaNoseR/blob/master/VolcaNoseR_example2.png "Output")

