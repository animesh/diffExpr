# Differential Expression Analysis [Protein/Gene/...]
batch analysis, deployed via GH actions to heroku 
<br><br>
app: https://differential-expression.herokuapp.com/ 
<br><br>
source: https://github.com/animesh/scripts/blob/master/diffExprPlots.rmd 
mailto: sharma.animesh@gmail.com?subject=%22diffExpr%20App%22
```bash
git clone https://github.com/animesh/diffExpr
usethis::create_package(path = "diffExpr")
```
base: https://blog.simonpcouch.com/blog/r-github-actions-commit/

# deps
library(jsonlite)

# run
cron: "0 * * * *"
