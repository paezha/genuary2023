
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Debug view

<!-- badges: start -->
<!-- badges: end -->

The prompt for Day 5 is Debug View. Here I present one step in the
debugging process of creating a wave with damping.

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
```

## Wave equation

The equation of a wave that moves in one dimension: $$
y(x, t) = A\sin(kx + \omega t - \phi)
$$

- $A$: amplitude
- $k$: speed of propagation
- $\omega$: angular frequency
- $\phi$: phase

The amplitude $A$ can be parameterized in terms of time or position. I
try the following: $$
A(x) = \alpha\cdot\exp(-\beta x)
$$

## Simulate a wave

Create a data frame with values of $x$ and $t$ for the wave, and also a
data frame for the accent:

``` r
df <- expand.grid(x = seq(0, 14, 0.1),
                  t = 0:62) |>
  mutate(y = 4/49 * (7 - x)^2 * sin(2 * x + 0.1 * t))

df2 <- data.frame(t = 0:62) |>
  mutate(x0 = 7,
         y0 = 2.5,
         r = 1.5 * (62 - t)/62)
```

In the above, $\alpha = 4/49$ (this is the maximum amplitude) to ensure
that the size of the image is 7:4.

## Render

Plot:

``` r
ggplot() + 
  geom_line(data = df,
            aes(x = x, 
                y = y,
                group = t,
                color = t),
            linewidth = 0) +
  geom_circle(data = df2 |> filter(t %% 4 == 0),
              aes(x0 = x0, y0 = y0, r = r, color = t)) +
  scale_color_gradient(low = "white", high = "black") +
  theme_void() +
  coord_equal() +
  theme(legend.position = "none",
        panel.background = element_rect(fill = "black"),
        plot.background = element_rect(fill = "black"))
#> Warning: Using the `size` aesthetic in this geom was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` in the `default_aes` field and elsewhere instead.

# Save named image
ggsave("outputs/sine-wave.png",
       height = 4,
       width = 7,
       units = "in")
```

<img src="outputs/sine-wave.png" width="500px" />

The tootable version of the code above is as follows:

    library(dplyr)
    library(ggforce)
    library(ggplot2)
    df<-expand.grid(x=seq(0,14,0.1),t=0:62)|>mutate(y=4/49*(7-x)^2*sin(2*x+0.1*t))
    df2<-data.frame(t=0:62)|>mutate(x0=7,y0=2.5,r=1.5*(62-t)/62)
    ggplot()+geom_line(data=df,aes(x=x,y=y,group=t,color=t),linewidth=0)+geom_circle(data =df2|>filter(t%%4==0),aes(x0=x0,y0=y0,r=r,color=t))+scale_color_gradient(low="white",high="black")+theme_void()+coord_equal()+theme(legend.position="none",panel.background=element_rect(fill="black"))
