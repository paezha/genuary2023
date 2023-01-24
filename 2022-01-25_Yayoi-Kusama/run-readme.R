library(knitr)
library(here)

for (i in 1:50){
  knitr::knit(paste0(here::here(), "/2022-01-25_Yayoi-Kusama/README.Rmd"))
}
