---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->



# Shadows

<!-- badges: start -->
<!-- badges: end -->


For this piece I use the following packages:

```r
library(dplyr) # A Grammar of Data Manipulation
#library(ggplot2) # Create Elegant Data Visualisations Using the Grammar of Graphics
library(glue) # Interpreted String Literals
library(MetBrewer) # Color Palettes Inspired by Works at the Metropolitan Museum of Art 
library(MexBrewer) # Color Palettes Inspired by Works of Mexican Muralists
library(rayrender) # Create Maps and Visualize Data in 2D and 3D
```

## Generate a random seed


```r
seed <- sample.int(100000000, 1)
# seed <- 83744970
```

## Columns

Generate a grid with the positions of the columns. These are the basic positions, but can be modified to obtain more interesting patterns.

```r
df <- expand.grid(x = c(-3), # This is to create a single rows of columns; consider adding more
                  z = seq(30, -30, -2.5)) # These are the positions and spacing between columns in the z axis (front-back)
```

Randomly select a color palette from package [`MexBrewer`](https://CRAN.R-project.org/package=MexBrewer) or [`MetBrewer`](https://CRAN.R-project.org/package=MetBrewer). The color palette will consist of as many colors as columns in the grid:

```r
set.seed(seed)

color_edition <- sample(c("MetBrewer",
                          "MexBrewer"),
                        1)

if(color_edition == "MetBrewer"){
  col_palette_name <- sample(c("Archambault", "Austria", "Benedictus", "Cassatt1", "Cassatt2", "Cross", "Degas", "Demuth", "Derain", "Egypt", "Gauguin", "Greek", "Hiroshige", "Hokusai1", "Hokusai2", "Hokusai3", "Homer1", "Homer2", "Ingres", "Isfahan1", "Isfahan2", "Java", "Johnson", "Juarez", "Kandinsky", "Klimt", "Lakota", "Manet", "Moreau", "Morgenstern", "Nattier", "Navajo", "NewKingdom", "Nizami", "OKeeffe1", "OKeeffe2", "Paquin", "Peru1", "Peru2", "Pillement", "Pissaro", "Redon", "Renoir", "Signac", "Tam", "Tara", "Thomas", "Tiepolo", "Troy", "Tsimshian", "VanGogh1", "VanGogh2", "VanGogh3", "Veronese", "Wissing"), 1)
  col_palette <- met.brewer(col_palette_name, n = nrow(df) + 1)
}else{
  col_palette_name <- sample(c("Alacena", "Atentado", "Aurora", "Casita1", "Casita2", "Casita3", "Concha", "Frida", "Huida", "Maiz", "Ofrenda", "Revolucion", "Ronda", "Taurus1", "Taurus2", "Tierra", "Vendedora"), 1)
  col_palette <- mex.brewer(col_palette_name, n = nrow(df) + 1)
}
```

Next, I create a data frame with the parameters for the position, radius, and height of the columns. The position in x is on the plane (left-right), y is the vertical axis, and z is on the plane (front-back). The element used for the columns is essentially a plane (no depth) and the dimensions are given by parameters `xwidth` and `ywidth`. Given the effect I wish to achieve, the center of this thin element will be centered on $y = 5$. The height of the columns should be at least twice this value to ensure that the columns are not "floating". Also, an angle can be used to rotate the thin plane on any of the three axes. Here, the angle will be for a rotation on the y-axis (vertical). In this data frame, the chosen color palette is also used to assign colors either at random or sorted (as an alternative the colors could be a function of position, angle, or other attribute of the columns):

```r
set.seed(seed)

# Choose at random whether to randomize or sort the colors
color_scheme <- sample(c("Random", "Sorted"), 1)

# Mutate the data frame to change the position on x as a function of z. Here I experiment with a power function.
df <- df |> 
  mutate(x = z^sample.int(4, 1),#0.01 * z^2,
         # Adjust the value in z to make sure that it is in a small interval, since the powers of z could result in very large values of x
         x = sample(c(-1, 1), 1) * runif(1, 0.1, 0.5) * 60 * x/(max(x) - min(x)),
         y = 5, # The columns are on the ground, not floating, not sunk
         xwidth = 2,
         ywidth = 30, 
         angle = runif(1, -2.5, 2.5) * max(x)) # The angle is in degrees, not radians, and is a rotation on the vertical plane

# Add the coloring scheme
if(color_scheme == "Random"){
  df <- df |>
    mutate(color = sample(col_palette[1:nrow(df)]))
}else{
  df <- df |>
    mutate(color = col_palette[1:nrow(df)])
}
```

Here I initialize an empty data frame and then use `df` to populate the parameters that go into `rayrender::xy_rect()`  to create the thin planes that become my "columns". The material of the columns is chosen at random:

```r
set.seed(seed)

obj <- data.frame()

material <- sample(c("Diffuse", "Metal", "Dielectric", "Glossy"), 1)

if(material == "Diffuse"){
  for(i in 1:nrow(df)){
    obj <- rbind(obj,
                 xy_rect(x = df$x[i],
                         y = df$y[i],
                         z = df$z[i],
                         xwidth = df$xwidth[i],
                         ywidth = df$ywidth[i],
                         angle = c(0, df$angle[i], 0),
                         material = diffuse(color=df$color[i])))
  }
}else if(material == "Metal"){
  for(i in 1:nrow(df)){
    obj <- rbind(obj,
                 xy_rect(x = df$x[i],
                         y = df$y[i],
                         z = df$z[i],
                         xwidth = df$xwidth[i],
                         ywidth = df$ywidth[i],
                         angle = c(0, df$angle[i], 0),
                         material = metal(color=df$color[i])))
  }
}else if(material == "Dielectric"){
  for(i in 1:nrow(df)){
    obj <- rbind(obj,
                 xy_rect(x = df$x[i],
                         y = df$y[i],
                         z = df$z[i],
                         xwidth = df$xwidth[i],
                         ywidth = df$ywidth[i],
                         angle = c(0, df$angle[i], 0),
                         material = dielectric(df$color[i])))
  }
}else{
  for(i in 1:nrow(df)){
    obj <- rbind(obj,
                 xy_rect(x = df$x[i],
                         y = df$y[i],
                         z = df$z[i],
                         xwidth = df$xwidth[i],
                         ywidth = df$ywidth[i],
                         angle = c(0, df$angle[i], 0),
                         material = glossy(color=df$color[i])))
  }
}
```

In this chunk of code, the scene for the rayrendering is initialized. The color of the ground is chosen randomly from the color palette in use:

```r
set.seed(seed)

#bkg_c <- col_palette[25]
scene <- generate_ground(spheresize = 10000 ,
                         material = diffuse(color = sample(col_palette, 1)))
```

After initializing the scene, it is now possible to add the objects (i.e., the columns). Also, I like to include either one or two source of light with random position:

```r
set.seed(seed)

n_lights <- sample(c("One", "Two"), 1)

if(n_lights == "One"){
  # Randomly choose the position of the light source along the z-axis
  z_pos <- runif(1, -30, 30)
  
  scene <- scene |>
    add_object(objects = obj) |>
    #light source
    add_object(sphere(x = -50,
                      y = 50,
                      z = z_pos,
                      r = 5,
                      material=light(intensity = 1000,
                                     invisible = TRUE)))
  
}else{
  # Randomly choose the position of the light source along the z-axis; the lights are positioned an equal distance away from z=0
  z_pos <- runif(1, 0, 30)
  
  scene <- scene |> 
    add_object(objects = obj) |>
    # first light source
    add_object(sphere(x = -50,
                      y = 50,
                      z = -z_pos,
                      r = 5,
                      material=light(intensity = 500,
                                     invisible = TRUE))) |>
    # second light source
    add_object(sphere(x = -50,
                      y = 50,
                      z = z_pos,
                      r = 5,
                      material=light(intensity = 500,
                                     invisible = TRUE)))
}
```

## Render the scene

Render the scene: 

```r
set.seed(seed)

# Stipulate the point of view; this is where a lot of the work happens, finding parameters that produce pleasing perpsectives
x_from <- 10 
z_from <- 100 
y_from <- 0

render_scene(file = glue::glue("outputs/shadows-{seed}.png"),
  scene, 
  parallel = TRUE,
  ambient_light = TRUE,
  aperture = 0.01,
  clamp_value = 2,
  # This size is callibrated to show the scene; changing it may result in tchanges in the composition
  width = 2000, 
  height = 1200,
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
  lookat = c(8, 0, 0))
#> --------------------------Interactive Mode Controls---------------------------
#> W/A/S/D: Horizontal Movement: | Q/Z: Vertical Movement | Up/Down: Adjust FOV | ESC: Close
#> Left/Right: Adjust Aperture  | 1/2: Adjust Focal Distance | 3/4: Rotate Environment Light 
#> P: Print Camera Info | R: Reset Camera |  TAB: Toggle Orbit Mode |  E/C: Adjust Step Size
#> K: Save Keyframe | L: Reset Camera to Last Keyframe (if set) | F: Toggle Fast Travel Mode
#> Left Mouse Click: Change Look At (new focal distance) | Right Mouse Click: Change Look At
```

<img src="outputs/shadows-86422391.png" alt="plot of chunk unnamed-chunk-10" width="500px" />


