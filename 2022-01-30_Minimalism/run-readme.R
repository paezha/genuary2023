library(knitr)
library(here)

for (i in 1:150){
  knitr::knit(paste0(here::here(), "/2022-01-30_Minimalism/README.Rmd"))
}
