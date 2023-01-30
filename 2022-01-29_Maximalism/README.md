
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Maximalism

<!-- badges: start -->
<!-- badges: end -->

For this prompt I learned about [Chinese
Maximalism](https://en.wikipedia.org/wiki/Maximalism#Visual_arts).
Eventually, I found inspiration in the work of [Xu
Hongming](https://www.wikiart.org/en/xu-hongming), and particularly his
[“Human Condition”](https://www.wikiart.org/en/xu-hongming/-1994) series
(人态 : Rén tài).

This piece is called *Pluribus unum Multorum chaos*. I begin by loading
the packages used in this notebook:

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
library(ggforce) # Accelerating 'ggplot2'
#> Loading required package: ggplot2
library(ggplot2) # Create Elegant Data Visualisations Using the Grammar of Graphics
library(glue) # Interpreted String Literals
library(MetBrewer) # Color Palettes Inspired by Works at the Metropolitan Museum of Art
library(MexBrewer) # Color Palettes Inspired by Works of Mexican Painters and Muralists
#> Registered S3 method overwritten by 'MexBrewer':
#>   method        from     
#>   print.palette MetBrewer
library(patchwork) # The Composer of Plots
library(stringr) # Simple, Consistent Wrappers for Common String Operations
#library(tidyr) # Tidy Messy Data
```

## Generate a random seed

``` r
seed <- sample.int(100000000, 1)
```

## Create a set of strokes to represent the human figure

Create strokes:

``` r
# body 1
stroke1 <- data.frame(rx = c(0.15, 0.25, 0.40, 0.50, 0.62, 0.75, 0.85),
                      ry = c(0.05, 0.38, 0.60, 0.64, 0.62, 0.38, 0.01),
                      size = c(0.70, 0.65, 0.50, 0.45, 0.30, 0.25, 0.05)) |>
  transmute(icon = "ren",
            stroke = "stroke1",
            id = 1:n(),
            rx,
            ry,
            size)

# body 2
stroke2 <- data.frame(rx = c(0.15, 0.20, 0.45, 0.30, 0.35, 0.50, 0.75, 0.55, 0.75, 0.85),
                      ry = c(0.05, 0.25, 0.42, 0.52, 0.62, 0.65, 0.55, 0.38, 0.23, 0.10),
                      size = c(0.70, 0.68, 0.55, 0.50, 0.48, 0.42, 0.36, 0.25, 0.15, 0.01)) |>
  transmute(icon = "ren",
            stroke = "stroke1",
            id = 1:n(),
            rx,
            ry,
            size)

# Head
stroke3 <- data.frame(theta = seq(3 * pi/2, 7 * pi/2, length = 10)) |>
  mutate(icon = "ren",
         stroke = "stroke2",
         id = 1:n(),
         rx = 0.50 + (0.2 - 0.00010 * id) * cos(theta),
         ry = 0.80 + (0.2 - 0.0043 * id) * sin(theta),
         size = c(0.1, 0.15, 0.25, 0.30, 0.45, 0.52, 0.61, 0.68, 0.75, 0.80)) |>
  select(-theta)

# Bind the strokes
strokes1 <- rbind(stroke1,
                  stroke3) |>
  mutate(icon = "ren1")

# Bind the strokes
strokes2 <- rbind(stroke2,
                  stroke3) |>
  mutate(icon = "ren2")

# Bind the two body styles
ren <- rbind(strokes1,
             strokes2)
```

Plot the strokes with one of the base icons in data frame `ren`, and
plot the control points:

``` r
ggplot() +
  geom_bspline2(data = ren |> filter(icon == "ren1"),
                aes(x = rx * 2,
                    y = ry * 2,
                    #color = type,
                    group = stroke,
                    linewidth = size),
                n = 800,
                lineend = "round") +
  geom_point(data = ren |> filter(icon == "ren1"),
             aes(x = rx * 2,
                 y = ry * 2),
             color = "red") +
  coord_equal()
```

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

Generate a grid to place each icon to create a multitude:

``` r
set.seed(seed)

# Select number of rows and columns
n_row <- 5 + sample.int(15, 1)
n_col <- 5 + sample.int(15, 1)

multitude <- expand.grid(x = seq(0, n_row, 1), y = seq(0, n_col, 1)) |>
  # Generate id for the position of glyphs in the text
  mutate(icon_id = 1:n(),
         # Sample glyph identifiers
         icon = sample(c("ren1", "ren2"), n(), replace = TRUE)) |>
  # Join strokes corresponding to each glyph identifier
  left_join(ren,
            by = "icon") |> 
  # Randomize the positions and sizes of the strokes by a small amount
  mutate(rx = x + 2.1 * rx + runif(n(), 0.90, 1.10),
         ry = y + 2.1 * ry + runif(n(), 0.90, 1.10),
         size = size * runif(n(), 0.95,1.05))
```

Assign colors to the icons:

``` r
set.seed(seed)

col_palette <- c("white", "red", "black")

# I tried various color palettes, but this works best in black and white in my experiments I could try to select colors in a more directed way to increase the contrast

#color_edition <- sample(c("Monotone", "MetBrewer", "MexBrewer"), 1)

# if(color_edition == "Monotone"){
#   col_palette <- c("white", "red", "black")
# }else if(color_edition == "MetBrewer"){
#   col_palette_name <- sample(c("Archambault", "Austria", "Benedictus", "Cassatt1", "Cassatt2", "Cross", "Degas", "Demuth", "Derain", "Egypt", "Gauguin", "Greek", "Hiroshige", "Hokusai1", "Hokusai2", "Hokusai3", "Homer1", "Homer2", "Ingres", "Isfahan1", "Isfahan2", "Java", "Johnson", "Juarez", "Kandinsky", "Klimt", "Lakota", "Manet", "Moreau", "Morgenstern", "Nattier", "Navajo", "NewKingdom", "Nizami", "OKeeffe1", "OKeeffe2", "Paquin", "Peru1", "Peru2", "Pillement", "Pissaro", "Redon", "Renoir", "Signac", "Tam", "Tara", "Thomas", "Tiepolo", "Troy", "Tsimshian", "VanGogh1", "VanGogh2", "VanGogh3", "Veronese", "Wissing"), 1)
#   col_palette <- met.brewer(col_palette_name, n = 3)
# }else if(color_edition == "MexBrewer"){
#   col_palette_name <- sample(c("Alacena", "Atentado", "Aurora", "Casita1", "Casita2", "Casita3", "Concha", "Frida", "Huida", "Maiz", "Ofrenda", "Revolucion", "Ronda", "Taurus1", "Taurus2", "Tierra", "Vendedora"), 1)
#   col_palette <- mex.brewer(col_palette_name, n = 3)
# }
```

Create object to plot Pluribus unum:

``` r
set.seed(seed)

# Select Ran: agent of chaos
ran <- sample(multitude$icon_id, 1)

# Pluribus unum
pu <- ggplot() +
  geom_bspline2(data = multitude |>
                  # Choose alternating points in the grid
                  mutate(rx = ifelse(y %% 2 == 0, rx + x + 0.5, rx + x),
                         ry = ry + y,
                         # Assign colors to the icons: red for Ran and black for everyone else
                         color = ifelse(icon_id == ran, col_palette[2], col_palette[3])),
                aes(x = rx,
                    y = ry,
                    color = color,
                    # The group is the interaction of icon_id and stroke, if icon_id only the strokes are merged
                    group = interaction(icon_id, stroke),
                    linewidth = size),
                n = 800,
                lineend = "round") +
  scale_color_identity() +
  scale_linewidth(range = c(0.25, 1)) +
  coord_equal() +
  theme_void() +
  theme(legend.position = "none",
        panel.background = element_rect(color = NA,
                                        fill = col_palette[1])) 
```

Create object to plot Multorum chaos:

``` r
set.seed(seed)

# Multorun chaos
mc <- ggplot() +
  geom_bspline2(data = multitude |>
                  # Choose alternating points in the grid
                  mutate(rx = ifelse(y %% 2 == 0, rx + x + 0.5, rx + x),
                         ry = ry + y,
                         # Randomize the strokes progressively
                         rx = rx * runif(n(), 0.98, 1.02),
                         ry = ry * runif(n(), 0.98, 1.02),
                         # Assign colors to the icons: red for Ran and black for everyone else
                         color = ifelse(icon_id == ran, col_palette[2], col_palette[3])),
                aes(x = rx,
                    y = ry,
                    color = color,
                    # The group is the interaction of icon_id and stroke, if icon_id only the strokes are merged
                    group = interaction(icon_id, stroke),
                    linewidth = size),
                n = 800,
                lineend = "round") +
  scale_color_identity() +
  scale_linewidth(range = c(0.25, 1)) +
  coord_equal() +
  theme_void() +
  theme(legend.position = "none",
        panel.background = element_rect(color = NA,
                                        fill = col_palette[1]))
```

Plot two panels side by side (check
[{patchwork}](https://patchwork.data-imaginist.com/articles/patchwork.html))

``` r
pu + mc

ggsave(glue::glue("outputs/pluribus-unum-multorum-chaos-{seed}.png"),
       #height = h,
       width = 7,
       units = "in")
#> Saving 7 x 5 in image
```

<img src="outputs/pluribus-unum-multorum-chaos-7328883.png" width="500px" />