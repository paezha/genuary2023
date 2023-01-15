
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Asemic

<!-- badges: start -->
<!-- badges: end -->

The basis for this is the code of Georgios Karamanis to create asemic
glyphs: check
<https://github.com/gkaramanis/aRtist/blob/main/asemic/asemic.R>

## Create a set of glyphs

Set the parameters for creating the glyphs, that is, the number of
glyphs (corresponding to letters), the number of points to generate each
glyph (used by the splines function), and the cutoff for the thickness
of the lines; notice that special characters are added to the set of
letters:

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
library(stringr)
library(tidyr)
```

## Generate a random seed

``` r
seed <- sample.int(100000000, 1)
# seed <- 83744970
```

## Create a set of glyphs

Set the parameters for creating the glyphs, that is, the number of
glyphs (corresponding to letters), the number of points to generate each
glyph (used by the splines function), and the cutoff for the thickness
of the lines; notice that special characters are added to the set of
letters:

``` r
set.seed(seed)

l <- c(letters, "'", "-", ":", "?")
special_chars <- c("accent1", "accent2", "accent3", "accent4")
nl <- length(l) # Number of letters
s <- sample.int(5, 1) + 3 # Points per letter
z <- runif(1, 0, 0.5) # Thickness of strokes
```

Initialize a data frame with all letters and special characters:

``` r
flo <- data.frame(letter = l) |> 
  # Group by row
  rowwise() |> 
  # Mutate rows with a list of values to generate random points for the glyphs
  mutate(
    #a = list(runif(s, 0, 2 * pi)),
    #rx = list(1 + seq(0.1, 0.5, length.out = s) * cos(a)),
    #ry = list(1 + seq(0.1, 0.3, length.out = s) * sin(a))
    a = list(runif(s, 0, 2 * pi)),
    rx = list(0.5 + runif(s, 0.1, 0.5) * cos(a)),
    ry = list(0.5 + runif(s, 0.1, 0.5) * sin(a))
    ) |> 
  # Ungroup and unnest
  ungroup() |> 
  unnest(c(rx, ry)) |> 
  # Group by row again
  rowwise() |> 
  # Mutate for thickness
  mutate(
    # Thickness of strokes
    size = runif(n(), 0, 2 * ry),
    size = if_else(size < z, 0, size)) |> 
  ungroup() |>
  # Give each asemic character a letter
  mutate(letter = rep(l, each = s))
```

Create some special characters to function as accents:

``` r
special_chars <- data.frame(accent = rep(special_chars, each = 4))

special_chars$rx <- c(0.15, 0.15, 0.65, 0.65,
                0.1, 0.125, 0.15, 0.175,
                0.1, 0.125, 0.15, 0.175,
                0.7, 0.725, 0.75, 0.775)

special_chars$ry <- c(0.15, 0.65, 0.65, 0.15,
                0.75, 0.725, 0.7, 0.675,
                0.25, 0.3, 0.35, 0.4,
                0.8, 0.6, 0.4, 0.2)

special_chars$size <- rep(c(0.1, 0.3, 0.5, 0.7), 4)
```

Different styles of glyphs can be obtained by sorting the coordinates
(or not):

``` r
# Randomly select one of eight possible styles
style <- sample.int(8, 1)
#style <- 1

# Modify the glyphs as per the style selected
switch(style,
       # As is
       {flo2 <- flo},
       # Arrange by x coord
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(rx,
                 .by_group = TRUE) |>
         ungroup()},
       # Arrange descending in x
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(desc(rx),
                 .by_group = TRUE) |>
         ungroup()},
       # Arrange by y
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(ry,
                 .by_group = TRUE) |>
         ungroup()},
       # Arrange descending in y
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(desc(ry),
                 .by_group = TRUE) |>
         ungroup()},
       # Arrange in x and y
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(rx, 
                 ry,
                 .by_group = TRUE) |>
         ungroup()},
       # Arrange descending in x and in y
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(desc(rx), 
                 ry,
                 .by_group = TRUE) |>
         ungroup()},
       # Arrange in x and descending in y
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(rx, 
                 desc(ry),
                 .by_group = TRUE) |>
         ungroup()},
       # Arrange descending both in x and y
       {flo2 <- flo |>
         group_by(letter) |>
         arrange(desc(rx), 
                 desc(ry),
                 .by_group = TRUE) |>
         ungroup()})
```

## Generate random text

Data frame with text:

``` r
haiku <- data.frame(text = c(paste0(sample(l, 5), collapse = ""),
                             paste0(sample(l, 7), collapse = ""),
                             paste0(sample(l, 5), collapse = ""))) |>
  # Convert all to lower case
  mutate(text = str_to_lower(text))
```

Prepare text:

``` r
#find the maximum width of a line in number of characters
pad <- max(str_length(haiku$text))

# Pad the strings to have the same width
haiku <- haiku |>
  mutate(text = str_pad(text, width = pad, side = "right"))
```

## Left-right writing

Convert text to single characters and add the coordinates to place the
glyphs in the block of text:

``` r
atext <- data.frame(x = rep(1:pad, 3),
                   y = rep(3:1, each = pad),
                   letter = str_split(haiku$text, pattern = "") |> 
                     unlist(),
                   type = "text")
```

Create signature:

``` r
signature <- data.frame(x = rep(max(atext$x) + 1, 2),
                        y = c(0, 0),
                        letter = c("a", "p"),
                        type = "signature") 
```

Retrieve coordinates for the accents:

``` r
accents <- slice_sample(atext, prop =0.4, replace = TRUE) |>
  mutate(id = 1:n(),
         letter = sample(special_chars$accent, n(), replace = TRUE))
```

Bind signature to data frame with text:

``` r
atext <- rbind(atext,
               signature)
```

Join asemic characters to text and accents:

``` r
atext_lr <- atext %>%
  left_join(flo2,
            by = "letter")

accents <- accents |>
  left_join(special_chars,
            by = c("letter" = "accent"))

atext_lr <- atext_lr |>
  # Adjust the values of the points rx and ry by their position in the block of text (row and column)
  mutate(rx = rx + x, 
         ry = ry + y,
         # Delete white spaces
         rx = ifelse(letter == " ", NA, rx),
         ry = ifelse(letter == " ", NA, ry))

accents <- accents |>
  # Adjust the values of the points rx and ry by their position in the block of text (row and column)
  mutate(rx = rx + x, 
         ry = ry + y,
         # Delete white spaces
         rx = ifelse(letter == " ", NA, rx),
         ry = ifelse(letter == " ", NA, ry),
         type = "text")
```

Plot:

``` r
ggplot() +
  # Use the coordinates to create splines: these are the glyphs
  geom_bspline2(data = atext_lr,
       aes(x = rx,
           y = ry,
           color = type,
           group = y,
           linewidth = size),
       n = 800,
       lineend = "round") +
  geom_bspline2(data = accents, 
       aes(x = rx, 
           y = ry, 
           color = type, 
           group = id,
           linewidth = size * 3),
       n = 800, 
       lineend = "round") +
  scale_linewidth_continuous(range = c(0, 1.5)) +
  # Define colors for each typeglyphs
  scale_color_manual(values = c("text" = "black", "signature" = "red")) +
  theme_void() +
  #coord_equal() +
  theme(#aspect.ratio = 4,
    legend.position = "none",
    plot.background = element_rect(fill = "grey97", color = NA)
  )

# Save named image
ggsave(glue::glue("outputs/asemic-haiku-lr-{seed}.png"),
       height = 4,
       width = 7,
       units = "in")
```

<img src="outputs/asemic-haiku-lr-75818716.png" width="500px" />

## Right-left, bottom-down writing:

Convert text to vector add coordinates for placement in block of text:

``` r
atext <- data.frame(x = rep(3:1, each = pad),
                   y = rep(pad:1, 3),
                   letter = str_split(haiku$text, pattern = "") |> 
                     unlist(),
                   type = "text")
```

Create signature:

``` r
signature <- data.frame(x = rep(max(atext$x) + 1, 2),
                        y = c(0, 0),
                        letter = c("a", "p"),
                        type = "signature") 
```

``` r
accents <- slice_sample(atext, prop =0.8, replace = TRUE) |>
  mutate(id = 1:n(),
         letter = sample(special_chars$accent, n(), replace = TRUE))
```

Bind signature to data frame with text:

``` r
atext <- rbind(atext,
               signature)
```

Join asemic characters to text and accents:

``` r
atext_bd <- atext %>%
  left_join(flo2,
            by = "letter")

accents <- accents |>
  left_join(special_chars,
            by = c("letter" = "accent"))

atext_bd <- atext_bd |>
  # Adjust the values of the points rx and ry by their position in the block of text (row and column)
  mutate(rx = rx + x, 
         ry = ry + y,
         # Delete white spaces
         rx = ifelse(letter == " ", NA, rx),
         ry = ifelse(letter == " ", NA, ry))

accents <- accents |>
  # Adjust the values of the points rx and ry by their position in the block of text (row and column)
  mutate(rx = rx + x, 
         ry = ry + y,
         # Delete white spaces
         rx = ifelse(letter == " ", NA, rx),
         ry = ifelse(letter == " ", NA, ry),
         type = "text")
```

Plot:

``` r
ggplot() +
  # Use the coordinates to create splines: these are the glyphs
  geom_bspline2(data = atext_bd,
       aes(x = rx,
           y = ry,
           color = type,
           group = x,
           linewidth = size),
       n = 800,
       lineend = "round") +
  geom_bspline2(data = accents, 
       aes(x = rx, 
           y = ry, 
           color = type, 
           group = id,
           linewidth = size * 3),
       n = 800, 
       lineend = "round") +
  scale_linewidth_continuous(range = c(0, 1.5)) +
  # Define colors for each typeglyphs
  scale_color_manual(values = c("text" = "black", "signature" = "red")) +
  theme_void() +
  #coord_equal() +
  theme(#aspect.ratio = 4,
    legend.position = "none",
    plot.background = element_rect(fill = "grey97", color = NA)
  )

# Save named image
ggsave(glue::glue("outputs/asemic-haiku-bd-{seed}.png"),
       height = 7,
       width = 4,
       units = "in")
```

<img src="outputs/asemic-haiku-bd-75818716.png" width="500px" />