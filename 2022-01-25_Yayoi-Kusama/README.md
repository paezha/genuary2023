
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Yayoi Kusama

<!-- badges: start -->
<!-- badges: end -->

This system draws inspiration from Yayoi Kusama’s [Infinty
Mirrors](https://ago.ca/exhibitions/kusama) and circles, circles,
circles! It combines a circle packing technique with rayrendering, and
it makes use of some of my favorite `R` packages:
[{ggplot}](https://ggplot2.tidyverse.org/),
[{MetBrewer}](https://github.com/BlakeRMills/MetBrewer), and
[{sf}](https://r-spatial.github.io/sf/).

Begin by loading the packages:

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
library(ggplot2) # Create Elegant Data Visualisations Using the Grammar of Graphics
library(glue) # Interpreted String Literals
library(MetBrewer) # Color Palettes Inspired by Works at the Metropolitan Museum of Art 
library(MexBrewer) # Color Palettes Inspired by Works of Mexican Muralists
#> Registered S3 method overwritten by 'MexBrewer':
#>   method        from     
#>   print.palette MetBrewer
library(rayrender) # Create Maps and Visualize Data in 2D and 3D
#> 
#> Attaching package: 'rayrender'
#> The following object is masked from 'package:ggplot2':
#> 
#>     arrow
library(sf) # Simple Features for R
#> Linking to GEOS 3.9.1, GDAL 3.4.3, PROJ 7.2.1; sf_use_s2() is TRUE
library(tidyr) # Tidy Messy Data
```

## Generate a random seed

``` r
seed <- sample.int(100000000, 1)
```

## Circle packing

This is my circle-packing algorithm. It takes a simple features polygon
`p` as an input, and the parameters for the circles (maximum number of
circles, maximum and minimum radii):

``` r
st_circle_packer <- function(p, max_circles = 100, max_radius = 1, min_radius = 0.1){
  
  # p = a simple features object with n >= 1 or more polygon features
  # max_circles = a number with the maximum number of candidate points for drawing circles
  # max_radius = a value with the maximum radius for drawing circles; can be a vector of size n so that the largest radius is different by polygon
  # min_radius = a value with the minimum radius for drawing circles; can be a vector of size n so that the smalest radius is different by polygon
  
  # Initialize the table with circles
  circles <- data.frame()
  
  # Initialize table with tolerance parameters
  radius_pars <- data.frame(id = p$id, 
                            min_radius, 
                            max_radius)
  
  # Convert polygons to lines
  p_lines <- p |>
    st_cast(to = "MULTILINESTRING")
  
  # Create initial set of points for potential circles in the space of the bounding box of the polygons
  c_points <- p |>
    st_sample(size = max_circles)
  
  c_points <- data.frame(geometry = st_geometry(c_points)) |>
    mutate(PID = 1:n()) |>
    st_as_sf()
  
  # Find any points that fall outside of a polygon and remove
  c_points <- c_points |>
    st_join(p) |>
    drop_na(id)
  
  # Initialize stopping criterion
  stopping_criterion <- TRUE
  
  while(stopping_criterion){
    # Sample one point from each polygon: these points are candidates for circles
    circle_candidates <- c_points |> 
      group_by(id) |>
      slice_sample(n =1) |>
      ungroup()
    
    # Remove the points sampled from the table of points so that they are not considered again in the future
    c_points <- c_points |>
      anti_join(circle_candidates |>
                  st_drop_geometry() |>
                  select(PID),
                by = "PID")
    
    # Find the distance of the candidate points to the boundaries of the polygons if no circles exist yet
    if(nrow(circles) == 0){
      circle_candidates$r <- circle_candidates |>
        st_distance(p_lines) |> 
        data.frame() |>
        apply(1, min)
    }# Find the distance of the candidate points to the boundaries of the polygons and circles if they exist
    else{
      circle_candidates$r <- circle_candidates |>
        st_distance(rbind(p_lines, 
                          circles |>
                            select(-PID))) |> 
        data.frame() |>
        apply(1, min)
    }
    
    # Join the tolerance parameters and filter candidates with a radius greater than the minimum
    circle_candidates <- circle_candidates |> 
      left_join(radius_pars, by = "id") |>
      filter(r >= min_radius)
    
    # Make sure that the radius does not exceed the maximum
    circle_candidates <- circle_candidates |>
      mutate(r = ifelse(r >= max_radius, max_radius, r)) |>
      select(-c(min_radius, max_radius)) # Drop tolerance parameters from table, no longer needed
    
    # If there are candidates points with a radius above the tolerance then create circles
    if(nrow(circle_candidates) > 0){
      # Use the points and buffers to create circles that are added to the existing table of circles
      circles <- rbind(circles,
                       circle_candidates |>
                         st_buffer(dist = circle_candidates$r))
      
      # Clear points that are now _inside_ a circle from the candidates (the radius will _not_ be NA)
      c_points <- c_points |>
        select(-c(r)) |> 
        st_join(circles |>
                  select(r)) |>
        filter(is.na(r))
    }
    stopping_criterion <- nrow(c_points) > 0
  }
  return(circles)
}
```

In this chunk I create a polygon. I choose randomly between a square or
a circle:

``` r
set.seed(seed)

style <- sample(c("Square", 
                  "Circle"), 
                1)

size <- runif(1, 1.5, 3)

if(style == "Square"){
  container_polygon <- matrix(c(-size, -size, 
                                -size, size, 
                                size, size,  
                                size, -size,
                                -size, -size),
                              ncol = 2,
                              byrow = TRUE)
  
  # Convert coordinates to polygons and then to simple features
  container_polygon <- data.frame(id = 1,
                                  r = NA,
                                  geometry = st_polygon(list(container_polygon)) |> 
                                    st_sfc()) |> 
    st_as_sf()
}else if(style == "Circle"){
  container_polygon <- data.frame(x = 0, y = 0) |>
    st_as_sf(coords = c("x", "y")) |>
    st_buffer(dist = size) |>
    mutate(id = 1,
           r = NA)
}
```

The polygon is then fed to the circle packing function. The parameters
are chosen at random:

``` r
# Set random seed
set.seed(seed)

# Pack polygons
circles <- container_polygon |> 
  st_circle_packer(max_circles = 500 + sample.int(5500, 1), 
                   max_radius = runif(1, 0.15, 0.4),
                   min_radius = runif(1, 0.01, 0.05))
```

This is the result of the packing algorithm:

``` r
ggplot2::ggplot() + 
  geom_sf(data = circles)
```

![](README_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

Here, I retrieve the coordinates of the centroids of the circles:

``` r
coords <- circles |>
  st_centroid() |>
  st_coordinates()
#> Warning in st_centroid.sf(circles): st_centroid assumes attributes are constant
#> over geometries of x
```

The coordinates of the circles are then added to the data frame:

``` r
df <- circles |>
  mutate(x = coords[,1], 
         y = coords[,2])
```

Next, I randomly select a color palette from package
[`MexBrewer`](https://CRAN.R-project.org/package=MexBrewer) or
[`MetBrewer`](https://CRAN.R-project.org/package=MetBrewer). The color
palette will consist of as many colors as circles in the system:

``` r
set.seed(seed)

color_edition <- sample(c("MetBrewer",
                          "MexBrewer"),
                        1)

if(color_edition == "MetBrewer"){
  col_palette_name <- sample(c("Archambault", "Austria", "Benedictus", "Cassatt1", "Cassatt2", "Cross", "Degas", "Demuth", "Derain", "Egypt", "Gauguin", "Greek", "Hiroshige", "Hokusai1", "Hokusai2", "Hokusai3", "Homer1", "Homer2", "Ingres", "Isfahan1", "Isfahan2", "Java", "Johnson", "Juarez", "Kandinsky", "Klimt", "Lakota", "Manet", "Moreau", "Morgenstern", "Nattier", "Navajo", "NewKingdom", "Nizami", "OKeeffe1", "OKeeffe2", "Paquin", "Peru1", "Peru2", "Pillement", "Pissaro", "Redon", "Renoir", "Signac", "Tam", "Tara", "Thomas", "Tiepolo", "Troy", "Tsimshian", "VanGogh1", "VanGogh2", "VanGogh3", "Veronese", "Wissing"), 1)
  col_palette <- met.brewer(col_palette_name, nrow(df))
}else{
  col_palette_name <- sample(c("Alacena", "Atentado", "Aurora", "Casita1", "Casita2", "Casita3", "Concha", "Frida", "Huida", "Maiz", "Ofrenda", "Revolucion", "Ronda", "Taurus1", "Taurus2", "Tierra", "Vendedora"), 1)
  col_palette <- mex.brewer(col_palette_name, nrow(df))
}
```

A color scheme is chosen at random. In one scheme, the colors are
assigned purely at random to the circles. In the second one the colors
are assigned by size. The thirds scheme assigns colors based on
position:

``` r
set.seed(seed)

# Choose at random whether to randomize or sort the colors
color_scheme <- sample(c("Random", 
                         "Size",
                         "Position"), 
                       1)

# Add the coloring scheme
if(color_scheme == "Random"){
  df <- df |>
    mutate(color = sample(col_palette, n(), replace = TRUE))
}else if(color_scheme == "Size"){
  df <- df |> 
    arrange(r) |>
    mutate(color = col_palette)
}else if(color_scheme == "Position"){
  df <- df |>
    mutate(position = x^sample.int(3, 1) + y^sample.int(3, 1)) |>
    arrange(position) |>
    mutate(color = col_palette)
}
```

This is the coloring of the circles:

``` r
ggplot() +
  geom_sf(data = df,
          aes(fill = color)) +
  scale_fill_identity()
```

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

# Rayrendering

For the next step, I will take the circles and use them to define
spheres for rayrendering. I create a data frame with the parameters for
the position and radius of the spheres. The position in x is on the
plane (left-right), y is the vertical axis, and z is on the plane
(front-back). Here I initialize an empty data frame and then use `df` to
populate the parameters that go into `rayrender::sphere()` to create the
thin planes that become my “columns”. The material of the spheres is
chosen at random:

``` r
set.seed(seed)

obj <- data.frame()

material <- sample(c("Diffuse", "Metal", "Glossy"), 1)

if(material == "Diffuse"){
  for(i in 1:nrow(df)){
    obj <- rbind(obj,
                 sphere(x = df$x[i],
                        y = 0,
                        z = df$y[i],
                        radius = df$r[i],
                        material = diffuse(color=df$color[i])))
  }
}else if(material == "Metal"){
  for(i in 1:nrow(df)){
    obj <- rbind(obj,
                 sphere(x = df$x[i],
                        y = 0,
                        z = df$y[i],
                        radius = df$r[i],
                        material = metal(color=df$color[i])))
  }
}else if(material == "Glossy"){
  for(i in 1:nrow(df)){
    obj <- rbind(obj,
                 sphere(x = df$x[i],
                        y = 0,
                        z = df$y[i],
                        radius = df$r[i],
                        material = glossy(color=df$color[i])))
  }
}
```

In this chunk of code, the scene for the rayrendering is initialized.
The color of the ground is set to black:

``` r
scene <- generate_ground(spheresize = 100000,
                         material = diffuse(color = "black"))
```

After initializing the scene, it is now possible to add the objects
(i.e., the spheres). Also, I like to include either one or two source of
light with random position:

``` r
set.seed(seed)

n_lights <- sample(c("One", "Two"), 1)

  # Randomly choose the position of the light source along the z-axis
  z_pos <- runif(1, 5, 10)
  x_pos <- runif(1, -5, 5)
  y_pos <- runif(1, -5, 5)


if(n_lights == "One"){

  scene <- scene |>
    add_object(objects = obj) |>
    #light source
    add_object(sphere(x = x_pos,
                      y = y_pos,
                      z = z_pos,
                      r = 1,
                      material=light(intensity = 10000,
                                     invisible = TRUE)))
  
}else{
  # Randomly choose the position of the light source along the z-axis; the lights are positioned an equal distance away from z=0
  z_pos <- runif(1, 5, 10)
  
  scene <- scene |> 
    add_object(objects = obj) |>
    # first light source
    add_object(sphere(x = x_pos,
                      y = y_pos,
                      z = -z_pos,
                      r = 1,
                      material=light(intensity = 5000,
                                     invisible = TRUE))) |>
    # second light source
    add_object(sphere(x = x_pos,
                      y = -y_pos,
                      z = z_pos,
                      r = 1,
                      material=light(intensity = 5000,
                                     invisible = TRUE)))
}
```

## Render the scene

Render the scene:

``` r
# Stipulate the point of view; this is where a lot of the work happens, finding parameters that produce pleasing perpsectives
x_from <- 1.0 
z_from <- 15 
y_from <- 1.0

render_scene(file = glue::glue("outputs/{material}-{col_palette_name}-{n_lights}-{seed}.png"),
             scene, 
             parallel = TRUE,
             ambient_light = TRUE,
             aperture = 0.01,
             clamp_value = 2,
             # Square
             width = 2000, 
             height = 2000,
             # Mastodon Header
             #width = 1500, 
             #height = 500,#1500,
             # iPhone 11
             #width = 828, 
             #height = 1792, 
             # windows wallpaper
             #width = 2560, 
             #height = 1440, 
             samples = 400, 
             lookfrom = c(x_from, z_from, y_from),
             lookat = c(0.0, -1, 0.0)
)
```

<img src="outputs/Metal-Casita1-Two-51354328.png" width="500px" />