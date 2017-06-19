#*********************************************************************************************************
#*********************************************************************************************************
# Short Linear Motif Enrichment Analysis App (SLiMEnrich)
# Developer: **Sobia Idrees**
# Version: 1.0.5
# Description: SLiMEnrich predicts Domain Motif Interactions (DMIs) from Protein-Protein Interaction (PPI) data and analyzes enrichment through permutation test.
#*********************************************************************************************************
#*********************************************************************************************************
##############################
#Version History
##############################
#V1.0.1 - Added code for checking whether packages installed. (Removes manual step)
#V1.0.2 - Better naming conventions in code
#V1.0.3 - Added titles/captions to data tables (uploaded files).
#       - Improved summary bar chart (used plotly), 
#       - Improved histogram module (removed separate window option for plot, added width/height input option in settings of histogram to download plot as png file). 
#V1.0.4 - Checks whether any of the random files is missing and creates if not present.
#V1.0.5 - Added a new tab to show distribution of ELMs in the predicted DMI dataset in tabular as well as in interactive view.
##############################

##############################
#Required Libraries
##############################
# Check whether packages of interest are installed
is_installed = function(mypkg) is.element(mypkg, installed.packages()[,1]) 
# Install library if not already installed
# Run a for-loop of all the package names listed below in the function call
# with the list of packages: load_or_install(c("pkg1", "pkg2",..., "pkgn"))
load_or_install = function(package_names) 
{ 
  for(package_name in package_names) 
  { 
    if(!is_installed(package_name)) 
    { 
      #install.packages(package_name,repos="http://lib.stat.cmu.edu/R/CRAN") 
      install.packages(package_name)
    } 
    library(package_name,character.only=TRUE,quietly=TRUE,verbose=FALSE) 
  } 
}
load_or_install(c("shiny", "ggplot2", "colourpicker", "shinyBS", "shinythemes", "DT", "shinyjs", "visNetwork", "igraph","markdown","plotly", "plyr"))

##############################
#GUI of the App
##############################
#navbar page with sidebar layout along with tabsets
ui <- shinyUI(navbarPage(div(id="title", ("SLiMEnrich")), tabPanel("Domain-Motif Interactions", tags$head(
  tags$style(HTML("
                  .shiny-output-error-validation {
                  color: red;
                  font-size: 18px;
                  font-style: italic;
                  font-weight: bold;
                  -webkit-animation: mymove 5s infinite; /* Chrome, Safari, Opera */
                  animation: mymove 5s infinite;
                  }
                  @-webkit-keyframes mymove {
                  50% {color: black;}
                  }
                  "))
  ),
  # Sidebar
  sidebarLayout(
    sidebarPanel(
      fileInput("PPI","Select Interaction file",accept=c('text/csv','text/comma-separated-values,text/plain','csv')),
      
      fileInput("Motif","Select SLiM prediction file",accept=c('text/csv','text/comma-separated-values,text/plain','csv')),
      actionButton("run", "Run", width = "100px"),
      div(id="fileuploads",checkboxInput("uploadmotifs",label = "Upload Domain and/or Motif-Domain Files", value = FALSE)),
      div(id="uploadmotif",  fileInput("domain","Select Domain file",accept=c('text/csv','text/comma-separated-values,text/plain','csv')),
          fileInput("MotifDomain","Select Motif-Domain file",accept=c('text/csv','text/comma-separated-values,text/plain','csv')))
    ),
    
    # MainPanel
    mainPanel(
      #Creates a seperate window (pop up window)
      #Creates a seperate window (pop up window)
      bsModal("DisE", "ELM Distribution", "godis", size = "large", plotlyOutput("diselmchart")),
      #Tab view
      tabsetPanel(type="tabs",
                  tabPanel("Uploaded Data",
                           fluidRow(
                             splitLayout(cellWidths = c("50%", "50%", "50%", "50%"), DT::dataTableOutput("udata2"), DT::dataTableOutput("udata")), DT::dataTableOutput("udata4"), DT::dataTableOutput("udata3")
                           )
                  ),
                  
                  tabPanel("Potential DMIs",
                           DT::dataTableOutput("data"),
                           tags$hr(),
                           downloadButton('downloadDMI', 'Download')
                  ),
                  
                  tabPanel("Predicted DMIs", DT::dataTableOutput("PredDMIs"),tags$hr(),downloadButton('downloadpredDMI', 'Download')),
                  
                  tabPanel("Statistics", fluidRow(
                    splitLayout(cellWidths = c("75%", "25%"), plotlyOutput("plotbar"))
                  )),
                  tabPanel("Histogram", fluidRow(
                    splitLayout(cellWidths = c("50%", "50%"), plotOutput("histogram"), htmlOutput("summary"))),
                    tags$hr(),
                    div(id="txtbox",actionButton("setting", "Settings")),
                    div(id="txtbox",downloadButton("downloadPlot", "Download")),
                    
                    div(id="settings", sliderInput("bins", 
                                                   "Number of bins",
                                                   min= 1,
                                                   max = 200,
                                                   value = 30),
                        tags$hr(),
                        tags$h4(tags$strong("Select labels")),
                      
                        checkboxInput("barlabel", label="Bar Labels", value = FALSE, width = NULL),
                        div(id="txtbox", textInput("text3", label = "Main title", value = "Distribution of random DMIs")),
                        div(id="txtbox",textInput(inputId="text",label = "X-axis title", value = "Numbers of random DMIs")),
                        tags$style(type="text/css", "#txtbox {display: inline-block; max-width: 200px; }"),
                        div(id="txtbox", textInput("text2", label = "Y-axis title", value = "Frequency of random DMIs")),
                        tags$hr(),
                        tags$h4(tags$strong("Select Colors")),
                        
                        div(id="txtbox",colourInput("col", "Select bar colour", "deepskyblue1")),
                        div(id="txtbox",colourInput("col2", "Select background colour", "white")),
                        tags$hr(),
                        tags$h4(tags$strong("Select width/height to download plot as png")),
                        
                        div(id="txtbox",numericInput("width", label = "Width ", value = 1200)),
                        div(id="txtbox",numericInput("height", label = "Height ", value = 700)),
                        tags$hr(),
                        
                        tags$h4(tags$strong("Download Randomized data")),
                        downloadButton('downloadrandom', 'Download')
                        
                        
                    )),
                  tabPanel("Distribution of ELMs",
                           DT::dataTableOutput("diselmsdata"), tags$br(),tags$hr(),div(id="txtbox",actionButton("godis", "Interactive View"))
                  ),
                  tabPanel("Network",fluidPage(tags$br(), selectInput("selectlayout", label = "Select Layout",
                                                                      choices = list("Circle" = "layout_in_circle","Nice" = "layout_nicely", "Random" = "layout_randomly", "Piecewise" = "piecewise.layout", "Gem" = "layout.gem"),
                                                                      selected = "layout_in_circle"),
                                               
                                               
                                               hr(),
                                               
                                               visNetworkOutput(outputId = "network",
                                                                height = "1500px",
                                                                width = "1500px")
                                               
                                               
                  )
                  )
                  
                  
      )
    )
  )),
  
  
  
  tabPanel("Getting Started"),tabPanel("Instructions", fluidPage(
    includeMarkdown("doc/instructions.Rmd")
  )), useShinyjs(),theme = shinytheme("sandstone"),
  tags$style(type="text/css", "#title {font-family: 'Impact', cursive;
             font-size: 32px;
             font-style:italic;
             font-color: #fff;
             -webkit-text-stroke-width: 1px;
             -webkit-text-stroke-color: black;}")
  
  
))

