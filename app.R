source("utils.R")
options(shiny.usecairo = FALSE)


#### pre-run setup ####

theme_empty <- make_empty_theme()

expr.data <- readRDS("data/data")
props <- readRDS("data/props")
data <- readRDS("data/coords")
imdims.list <- readRDS("data/imdims.list")


#### UI ####

ui <- dashboardPage(

  header = dashboardHeader(title = "FFPE mouse brain \ndata explorer"),

  sidebar = dashboardSidebar(
    width = 250,
    column(width = 12),

    column(width = 12,
           uiOutput("var_features"),
           selectInput(
             inputId = "cells",
             label = "Cell type",
             choices = rownames(props),
             selected = "Oligo"),
           sliderInput(
             inputId = "alpha",
             label = "Opacity", value = 1,
             min = 0, max = 1, step = 0.01
           ),
           sliderInput(
             inputId = "size",
             label = "Size", value = 1,
             min = 0.7, max = 1.3, step = 0.01
           ),
           selectInput(
             inputId = "cscale",
             label = "colors",
             choices = names(COLORS),
             selected = "Red"),
           fluidRow(
             column(width = 4, radioButtons(
               inputId = "edgecolor",
               label = "edgecolor",
               choices = names(EDGESTROKES),
               selected = "Off")),
             column(width = 8, radioButtons(
               inputId = "scalealpha",
               label = "scale opacity",
               choices = c("On", "Off"),
               selected = "Off"))
           )

    )

  ),

  body = dashboardBody(
    height = "500px",
    tags$head(tags$style(HTML("/* body */
                                .content-wrapper, .right-side {
                                background-color: #ffffff;
                                }"))),
    uiOutput("STplot1")
  )
)

### SERVER ####
server <- function(input, output, session) {


  rv <- reactiveValues(lastBtn = character())
  observeEvent(input$var, {

    if (input$var > 0 ) {
      rv$lastBtn = "gene"
    }
  })
  observeEvent(input$cells, {
    if (input$cells > 0 ) {
      rv$lastBtn = "cells"
    }
  })

  output$STplot1 <- renderUI({
    fluidRow(column(width = 6,
                    tags$head(tags$style(paste0("#plot1",
                                                "{width: 40vw !important; height:40vw !important;}"))),
                    div(id = "container",
                        height = imdims.list[[1]]$height,
                        width = imdims.list[[2]]$width,
                        div(tags$img(src = file.path("imgs/1.png"),
                                     style = "width: 40vw; height: 40vw;"),
                            style = "position:absolute; top:0; left:0;"),
                        div(plotOutput("plot1"),
                            style = "position:absolute; top:0; left:0;")
                    )),
             column(width = 6,
                    tags$head(tags$style(paste0("#plot2",
                                                "{width:40vw !important; height:40vw !important;}"))),
                    div(id = "container",
                        height = imdims.list[[1]]$height,
                        width = imdims.list[[2]]$width,
                        div(tags$img(src = file.path("imgs/2.png"),
                                     style = "width: 40vw; height: 40vw;"),
                            style = "position:absolute; top:0; left:0;"),
                        div(plotOutput("plot2"),
                            style = "position:absolute; top:0; left:0;")
                    ))
              )
    })

  output$var_features <- renderUI({

    selectInput(
      inputId = "var",
      label = "Gene",
      choices = rownames(expr.data),
      selected = "Nrgn")

  })

  get_data <- reactive({

    if (rv$lastBtn == "cells") {
      data[, input$cells] <- props[input$cells, ]
      if (input$scalealpha == "On") {
        data[, "alpha"] <- scales::rescale(data[, input$cells])
      }
    }  else if (rv$lastBtn == "gene") {
      data[, input$var] <- expr.data[input$var, ]
      if (input$scalealpha == "On") {
        data[, "alpha"] <- scales::rescale(data[, input$var])
      }
    }
    
    return(list(data,
                variable = ifelse(rv$lastBtn %in% names(input),
                                  input[[rv$lastBtn]],
                                  input$var
                                  )
                  ))

  })
  

  # re-render the plot with the new data -------------------------

    lapply(1:2, function(i) {
      output[[paste0("plot", i)]] <- renderPlot({
        c(dt, variable) %<-% get_data()
        dims <- imdims.list[[i]][2:3] %>% as.numeric()
        dfs <- diff(dims)
        
        dt.subset <- subset(dt, sample == paste0(i))
        tit <- ifelse(i == 1, "FFPE", "FF")
        
        # Check if alpha scaling is activated
        if ("alpha" %in% colnames(dt)) {
          p <- ggplot() +
            geom_point(data = dt.subset,
                       mapping = aes_string(x = "warped_x",
                                            y = paste0("dims[2] - warped_y"),
                                            fill = paste0("`", variable, "`")
                       ),
                       stroke = EDGESTROKES[[input$edgecolor]],
                       size = input$size*session$clientData$output_plot1_width/250,
                       alpha = dt.subset$alpha,
                       shape = 21)
        } else {
          p <- ggplot() +
            geom_point(data = dt.subset,
                       mapping = aes_string(x = "warped_x",
                                            y = paste0("dims[2] - warped_y"),
                                            fill = paste0("`", variable, "`")
                       ),
                       stroke = EDGESTROKES[[input$edgecolor]],
                       size = input$size*session$clientData$output_plot1_width/250,
                       alpha = input$alpha,
                       shape = 21)
        }
        
        p <- p +

          theme_empty +

          ggtitle(ifelse(rv$lastBtn %in% "cells",
                        paste0(tit, ": ", variable),
                        paste0(tit, ": ", variable))) +

          labs(fill = ifelse(rv$lastBtn %in% "cells",
                            "Cell type \nproportion",
                            "norm.\n(expr.)")) +

          scale_x_continuous(limits = c(dfs/2, dims[1] - dfs/3), expand = c(0, 0)) +
          scale_y_continuous(limits = c(ifelse(i == 2, dfs/4, dfs), dims[2] - dfs/3), expand = c(0, 0)) +
          scale_fill_gradientn(colours = COLORS[[input$cscale]])
        
        p
              },
              bg = "transparent")
    })
}

# Run the application
shinyApp(ui = ui, server = server)
