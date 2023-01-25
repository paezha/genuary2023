library(knitr)
library(here)

for (i in 1:100){
  knitr::knit(paste0(here::here(), "/2022-01-26_My-kid-could-have-done-that/README.Rmd"))
}
