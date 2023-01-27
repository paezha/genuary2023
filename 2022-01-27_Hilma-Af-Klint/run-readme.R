library(knitr)
library(here)

for (i in 1:50){
  knitr::knit(paste0(here::here(), "/2022-01-27_Hilma-Af-Klint/README.Rmd"))
}
