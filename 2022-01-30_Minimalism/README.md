
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Minimalism

<!-- badges: start -->
<!-- badges: end -->

When my son Leo was little, he had an amazing drawing style. He made
some monsters that were all spirals, spikes, huge bug-eyes, and lots and
lots of skinny legs.

The sinuous meander paths of [David
Chappell](doi.org/10.1080/17513472.2015.1092859) may have been inspired
by the mathematics used to represent the geomorphology of streams, but
to me many of the outputs look like the awesome monsters that my son
used to draw as a child.

For this piece I use the following packages:

``` r
library(dplyr) # A Grammar of Data Manipulation
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(ggforce)
#> Loading required package: ggplot2
library(ggplot2) # Create Elegant Data Visualisations Using the Grammar of Graphics
library(glue) # Interpreted String Literals
library(MetBrewer) # Color Palettes Inspired by Works at the Metropolitan Museum of Art 
library(MexBrewer) # Color Palettes Inspired by Works of Mexican Muralists
#> Registered S3 method overwritten by 'MexBrewer':
#>   method        from     
#>   print.palette MetBrewer
#library(tidyr)
```

## Generate a random seed

``` r
seed_1 <- sample.int(100000000, 1)
seed_2 <- sample.int(100000000, 1)
#seed <- 8336784
```

## Generate meandering path

Select the number of sine curves for the path, and the parameters of the
curves: the amplitude $A$, frequency $f$, and phase $phi$ ($\phi$).

``` r
mounts <- function(seed){
  set.seed(seed)
  
  n_sine <- 2#sample(c(1, 2), 1)# + sample.int(2, 1)
  
  # Calibrating the amplitude A is critical here to avoid waves that fold on themselves
  A <- runif(n_sine, 0, 1.0) |> sort(decreasing = FALSE)
  f <- runif(n_sine, 1, 5) |> sort(decreasing = TRUE)
  phi <- runif(n_sine, 0, 2 * pi) |> sort(decreasing = FALSE)
  
  # Number of points
  n_t <- 1000
  
  # Points
  t <- seq(0, 2 * pi, length = n_t)
  
  x <- 0  
  y <- 0
  idx <- 0
  
  df <- data.frame(x = numeric(length = n_t),
                   y = numeric(length = n_t),
                   theta = numeric(length = n_t)) 
  
  #In this chunk of code the angle is calculated and used to obtain the values of $x$ and $y$:
  for(i in t){
    idx <- idx + 1
    theta <- 0
    for(j in 1:n_sine){
      theta <- theta + A[j] * sin(f[j] * t[idx] + phi[j])
    }
    df$x[idx] <- cos(theta)
    df$y[idx] <- sin(theta)
    df$theta[idx] <- theta
  }
  
  df |>
    mutate(x = x + cumsum(x),
           y = y + cumsum(y))
}
```

Assign colors to the icons:

``` r
set.seed(seed_1)

color_edition <- sample(c("MetBrewer", "MexBrewer"), 1)

if(color_edition == "Monotone"){
  col_palette <- c("white", "red", "black")
}else if(color_edition == "MetBrewer"){
  col_palette_name <- sample(c("Cassatt1", "Cassatt2", "Greek", "Hiroshige", "Hokusai1", "Hokusai2", "Hokusai3", "Homer1", "Homer2", "Ingres", "Isfahan1", "Manet", "Morgenstern", "OKeeffe1", "OKeeffe2", "Paquin", "Peru2", "Pissaro", "Tam", "Tiepolo", "Troy", "VanGogh1", "VanGogh3", "Veronese"), 1)
  col_palette <- met.brewer(col_palette_name, n = 23)
}else if(color_edition == "MexBrewer"){
  col_palette_name <- sample(c("Alacena", "Atentado", "Aurora", "Concha", "Frida", "Huida", "Maiz", "Ofrenda", "Revolucion", "Ronda", "Taurus1", "Taurus2", "Tierra", "Vendedora"), 1)
  col_palette <- mex.brewer(col_palette_name, n = 23)
}

if(sample(c(TRUE, FALSE), 1)){
  col_palette <- rev(col_palette)
}
```

``` r
set.seed(seed_2)

col_1 <- 17 + sample.int(3, 1)
col_2 <-  col_palette[col_1 - 5]
col_1 <- col_palette[col_1]

col_3 <- 13 + sample.int(3, 1)
col_4 <- col_palette[col_3 - 5]
col_3 <- col_palette[col_3]

ggplot() +
  geom_circle(aes(x0 = runif(1, min = 0.15, 0.85),
                  y0 = min(1.35, rlnorm(1, 0, 0.10)),
                  angle = 0,
                  r = runif(1, min = 0.1, 0.15)),
              color = "white",
              fill = sample(c("gold", "darkorange", "firebrick", "brown3"), 1),
              size = 1.0) +
  geom_ribbon(data = mounts(seed_1) |>
                mutate(x = (x - min(x))/(max(x) - min(x)),
                       y = runif(1, 0.4, 0.6) + (y - min(y))/(runif(1, 3, 5) * (max(y) - min(y))),
                       y = y - runif(1, 0.15, 0.25) * x),
              aes(x = x,
                  ymax = y,
                  ymin = 0),
              color = "white",#col_2,
              fill = col_1,
              linewidth = 1.0) +
  geom_ribbon(data = mounts(seed_2) |>
                mutate(x = (x - min(x))/(max(x) - min(x)),
                       y = runif(1, 0.10, 0.2) + (y - min(y))/(runif(1, 4, 6) * (max(y) - min(y))),
                       y = y + runif(1, 0.15, 0.25) * x),
              aes(x = x,
                  ymax = y,
                  ymin = 0),
              color = "white",#col_4,
              fill = col_3,
              linewidth = 1.0) +
  scale_fill_identity() +
  coord_equal(expand = FALSE) +
  xlim(c(0,1)) + 
  ylim(c(0,1.5)) + 
  theme_void() +
  theme(panel.background = element_rect(color = "white",
                                        fill = col_palette[sample.int(5, 1)],
                                        linewidth = 1.5))
#> Warning in geom_circle(aes(x0 = runif(1, min = 0.15, 0.85), y0 = min(1.35, :
#> Ignoring unknown aesthetics: angle
#> Warning: Using the `size` aesthetic in this geom was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` in the `default_aes` field and elsewhere instead.
```

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

``` r

ggsave(file = glue::glue("outputs/dunes-{col_palette_name}-{seed_1}-{seed_2}.png"),
       w = 4,
       h = 6,
       units = "in")
```

<img src="outputs/dunes-Frida-4414050-52084467.png" width="500px" />
