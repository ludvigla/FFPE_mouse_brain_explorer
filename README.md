# FFPE mousebrain explorer
Explore spatial transcriptomics data of coronal sections from mouse brain tissue presented in "Genome-wide Spatial Expression Profiling in Formalin-fixed Tissues" (Villacampa E. and Larsson. L et al).

# Installation
Clone the repo from the terminal by running:

`$git clone https://github.com/ludvigla/FFPE_mousebrain_explorer`

To run the app, you first need to install the following R packages:
- ggplot2
- magrittr
- magick
- zeallot
- shiny
- shinydashboard
- RColorBrewer
- viridis
- scales

You can install the packages directly with the install-packages.R script:

`$Rscript install-packages.R`

# Run the app
From RStudio, navigate to the cloned repository:
`setwd("~/FFPE_mousebrain_explorer")`

You can then activate the app by running:

`library(shiny)`

`runApp()`

Or alternatively you can open the app.R file File->Open file->.../app.R and then click on the Run App at the top of the script.

# How to use
When you open the app, you will see 
![](app.png)
