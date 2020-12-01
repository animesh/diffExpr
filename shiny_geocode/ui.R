library("shinydashboard")
library("shinydashboardPlus")
library("dashboardthemes")


# Define UI for application 
ui <- dashboardPage(
    header= dashboardHeader(title= "Batch Differential Expression Analysis",
                            tags$li(a(href = 'mailto:sharma.animesh@gmail.com?subject="Differential Expression Analysis App"',
                                      icon("envelope", "fa-2x"),
                                      title = "Contact",
                                      style = "color: #17677C; margin-top: -4px; padding-left: 4px;" ),
                                    class = "dropdown"),
                            tags$li(a(href = 'https://differential-expression.herokuapp.com/',
                                      icon("github", "fa-2x"), # 2x size from f
                                      title = "GitHub Repo",
                                      style = "color: #17677C; margin-top: -4px; padding-left: 4px;" ),
                                    class = "dropdown"),
                            # Set height of dashboardHeader
                            tags$li(class = "dropdown",
                                    tags$style(".navbar {max-height: 40px;}")
                            )
                                    
    ),
    
    sidebar= dashboardSidebar(disable = TRUE),
    
    body= dashboardBody(
        shinyalert::useShinyalert(),
        shinyDashboardThemes(theme = "blue_gradient"),
        # app title 
        titlePanel("Get ID & pathway from list"),
        column(width=4,
               fluidRow(
                   # box w/ description and upload inputs
                   box(width = '100%',
                       title="1. Upload your address list as CSV or Excel file",
                       "After uploading specify if the data has a header. If it is a CSV file, specify the separator.", br(),
                       "Note that for Excel files, all columns need to be in character format.", br(),
                       "You can check the data in the preview once uploaded.",
                       
                       br(), br(),
                       fileInput(
                           inputId = "file_upload",
                           label= "Upload file",
                           multiple = FALSE,
                           accept = c(".csv", ".xlsx"),
                           width = '40%',
                           buttonLabel = "Browse...",
                           placeholder = "No file selected"
                       ),
                       
                       # check if file has header
                       checkboxInput("header", "Header", TRUE),
                       
                       # Input: Select separator 
                       radioButtons("sep", "Separator",
                                    choices = c(Comma = ",",
                                                Semicolon = ";",
                                                Tab = "\t",
                                                Pipe = "|"),
                                    selected = ","),
                   )
               ), 
               box(
                   width = '100%',
                   title= "2. Choose the ID columns",
                   "Either ID or pathway is required. A map column or a map choosen from the dropdown list is required.", br(), br(),
                   uiOutput("address"),
                   uiOutput("pathway"),
                   uiOutput("ID"),
                   uiOutput("map"),
                   uiOutput("map_list")
               ),
               box(
                   width = '100%',
                   title= "3. Differential Expression Analysis",
                   uiOutput("start_button"),
                   htmlOutput("df_message")
                   
               ),
               box(
                   width = '100%',
                   title= "4. Download results",
                   uiOutput("download_button")
                   
               )
               
        ),
        
        
        column(width = 8,
               htmlOutput("data_size"),
               tableOutput("preview"),
               tableOutput("preview_results")
              
        )
    )
    
    
    
)
