library("shiny")
library("tidyverse")
library("readxl")
library("shinyalert")

# Define server logic
server <- function(input, output) {
    
    # load if csv or xlsx file uploaded
    data_file <- reactive({
        req(input$file_upload)
        
        if (str_detect(input$file_upload$datapath, "\\.csv$")){
            
            df <- read.csv(input$file_upload$datapath,
                           header = input$header,
                           sep = input$sep,
                           colClasses = "character"
            )
            return(df)
        }
        
        else if (str_detect(input$file_upload$datapath, "\\.xlsx$")){
            
            df <- read_excel(input$file_upload$datapath, 
                             col_names = input$header,
                             col_types = "character"
            )
            return(df)
        }
        
        else {
            return("Error: Wrong file format")
            
        }
        
    })
    
    output$preview <- renderTable({
        
        # input$file1 will be NULL initially. After the user selects
        # and uploads a file, head of that data file by default,
        # or all rows if selected, will be shown.
        req(data_file())
        return(head(data_file(),10))
        
    }, caption= "Data preview"
    )
    
    # output size of uploaded data
    output$data_size <- renderText({
        req(data_file())
        return(paste("No of rows: ", nrow(data_file()), "<br>No of columns: ", ncol(data_file())))
    })
    
    # get row size of uploaded data
    row_number <- reactive({
        req(data_file())
        nrow(data_file())
    })
    
    # make shiny alert info box on first data upload only
    observeEvent(data_file(), once = TRUE, {
        req(data_file())
        shinyalert(
            title = "Check",
            text = paste("uploaded dataset has", row_number(), "entries"),
            size = "s", 
            closeOnEsc = TRUE,
            closeOnClickOutside = TRUE,
            html = TRUE,
            type = "info",
            showConfirmButton = TRUE,
            showCancelButton = FALSE,
            confirmButtonText = "OK",
            confirmButtonCol = "#17677C",
            timer = 0,
            imageUrl = "",
            animation = TRUE
        )
    })
    
    # make Input filter pop up when data was uploaded
    output$ID <- renderUI({
        req(data_file())
        selectInput("ID",choices= c("", names(data_file())), width='40%', selected = "")
    })
    
    output$pathway <- renderUI({
        req(data_file())
        selectInput("Pathway", choices= c("", names(data_file())), width='40%', selected = "")
    })
    # render start button
    output$start_button <- renderUI({
        req(data_file())
        actionButton("start", "Start pathway mapping", style= "background-color: #00ffd5")
    })
    
    # on button click check consistency
    check_df_message <- eventReactive(eventExpr = input$start, label="button_react_addresspaste", valueExpr = {
        req(data_file())
        if (row_number() > 10000) {
            "<span style=\"color:red\">Error: More than 10000 entries can not be coded</span>"
        }
        else if (input$ID == "" & input$pathway == ""){
            "<span style=\"color:red\">Error: ID or pathway column required</span>"
        }
        else if (input$ID != "" & !is.character(data_file()[[input$ID]])) {
            "<span style=\"color:red\">Error: ID column not in character format</span>"
        }
        else if (input$pathway != "" & !is.character(data_file()[[input$pathway]])) {
            "<span style=\"color:red\">Error: pathway column not in character format</span>"
        }
        else {
            "<span style=\"color:green\">coding finished</span>"
        }
        
    })
    
    # Error/finish message output
    output$df_message<- renderText({
        req(check_df_message())
        return(check_df_message())
    })
    

    # if input consistent, make complete adress column and diffExprcode it
    coded_data<- eventReactive(eventExpr = input$start, label="button_react_diffExprcode", ignoreNULL = FALSE, valueExpr ={
        req(check_df_message())
        if (check_df_message() == "<span style=\"color:green\">diffExprcoding finished</span>"){
          g_data <-  data_file() %>%
               
                transmute(complete_address = paste0(
                   (if(input$address != ""){
                        paste0(!!sym(input$address), ", " )
                    }),
                   (if(input$zip != ""){
                       paste0(!!sym(input$zip), " ") 
                   }),
                   (if(input$city != ""){
                       !!sym(input$city)
                   }), ",",
                   (if(input$country != ""){
                       paste0(" ", !!sym(input$country)) 
                   }),
                   (if(input$country_list != ""){
                       paste0(" ", input$country_list) 
                   })
                ))
          
          # init diffExprcoding addresses to long lat with google maps API with progress bar
          withProgress(message = 'diffExprcoding in progress', detail = '', value = 0, {
            
                gc<- map(g_data$complete_address, function(x){ 
                    
                    # incremet progress bar
                    incProgress(1/row_number())    
                    
                })
          })
         # transform list long lat to tibble and bind to input data
         final_data<- bind_cols( do.call(rbind, gc), data_file())
         return(final_data)
        
        } # end of if clause
    })
    
    # preview finished dataset
    output$preview_results<- renderTable({
        req(coded_data())
        return(head(coded_data(), 10))
    }, caption = "Results preview (lon/lat shortened)")
    
    # render download button
    output$download_button <- renderUI({
        req(coded_data())
        downloadButton("downloadData", "Download", style= "background-color: #00ffd5")
    })
    
    # download df
    output$downloadData <- downloadHandler(
        
        # This function returns a string which tells the client
        # browser what name to use when saving the file.
        filename = function() {
            paste0("coded_addresses_", Sys.Date(), ".csv" )
        },
        
        # This function should write data to a file given to it by
        # the argument 'file'.
        content = function(file) {
            
            # Write to a file specified by the 'file' argument
            write_csv(coded_data(), file)
        }
    )
}
