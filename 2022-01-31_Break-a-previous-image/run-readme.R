library(knitr)
library(here)

for (i in 1:50){
  knitr::knit(paste0(here::here(), "/2022-01-31_Break-a-previous-image/README.Rmd"))
}
