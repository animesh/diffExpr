options(shiny.maxRequestSize=100*1024^2)
#source: diffExpr
#install dependencies
#devtools::install_github(c("RDocTaskForce/testextra","RDocTaskForce/parsetools","halpo/purrrogress"))
#install.packages(c("BiocManager","shiny","markdown","knitr","sweave","xtable","DT","httpuv","sourcetools"))
#BiocManager::install(c("EDASeq","genefilter","sva","limma","GenomicFeatures","GenomeInfoDb","GenomicRanges","SummarizedExperiment","EnsDb.Hsapiens.v79","S4Vectors","biomaRt","BiocStyle","edgeR","IRanges","TCGAbiolinks"))
#download and process
library(shiny)
#golem::disable_autoload()
#options(shiny.autoload.r=FALSE)
#library(SummarizedExperiment)
#library(dplyr)
#library(DT)
#library(ggplot2)
#download.file("https://studntnu-my.sharepoint.com/:u:/g/personal/animeshs_ntnu_no/EfQcUVcV4m5IlA7YY9h6zFsBJwZhomsv-0r5uIgnd8Wt0g?e=UZC0vP","data.rds")
#legend("T Test")
#edit(t.test,file="test.r")
#source("test.r")
#body(blTT)<-source("bottomleft.r")
#body(blKM)[[25]][[4]]<-substitute({cat(paste0((ngenes - i), "."))})
ui <- fluidPage(
  titlePanel("T test over selected columns from MaxLFQ output"),
  textInput("selection", "Select columns starting with", value = "LFQ.intensity", width = '500px', placeholder = NULL),
  fileInput("fileUp", "Upload proteinGroups.txt", multiple = FALSE,
            accept = c("text","text/tab-separated-values,text/plain",".txt"),
            width = NULL, buttonLabel = "Browse...",
            placeholder = "No file selected"),
  uiOutput("columnInfo"),
  fluidRow(
    column(6,
      h4("Select columns for Group 1:"),
  textInput("colFilter1", "Filter columns (Group 1):", value = "43_|44_|45_|46_|47_|48_"),
  uiOutput("group1Checkboxes"),
  verbatimTextOutput("selectedCols1")
    ),
    column(6,
      h4("Select columns for Group 2:"),
  textInput("colFilter2", "Filter columns (Group 2):", value = "37_|38_|39_|40_|41_|42_"),
  uiOutput("group2Checkboxes"),
  verbatimTextOutput("selectedCols2")
    )
  ),
  #selectInput("series1", "Group 1 LFQ columns:", choices=c()),
  #selectInput("series2", "Group 2 LFQ columns:", choices=c()),
  downloadButton("downloadData", "Download"),
  selectInput("seriesR", "Result & log2LFQ group columns:", width='500px',choices=c()),
  mainPanel(
    plotOutput("hist"),
    plotOutput("heatmap"),
    DT::dataTableOutput("tableR")#,
    #tableOutput("table1"),
    #tableOutput("table2")
  )
)
server <- function(session,input,output) {
  # Helper to get filtered columns
  getFilteredCols <- function(df, sel, filterText) {
    cols <- colnames(df)
    # Always use sel as prefix (e.g. 'LFQ intensity ')
    if (!is.null(sel) && sel != "") {
      cols <- grep(paste0("^", sel), cols, value = TRUE)
    }
    if (!is.null(filterText) && filterText != "") {
      cols <- grep(filterText, cols, value = TRUE, ignore.case = TRUE)
    }
    cols
  }

  # Group 1 checkboxes
  output$group1Checkboxes <- renderUI({
    df <- dataRaw()
    if (is.null(df)) return(NULL)
    sel <- input$selection
    filter1 <- input$colFilter1
    choices <- getFilteredCols(df, sel, filter1)
    selected <- choices
    checkboxGroupInput("group1Cols", NULL, choices = choices, selected = selected)
  })

  # Group 2 checkboxes
  output$group2Checkboxes <- renderUI({
    df <- dataRaw()
    if (is.null(df)) return(NULL)
    sel <- input$selection
    filter2 <- input$colFilter2
    choices <- getFilteredCols(df, sel, filter2)
    selected <- choices
    checkboxGroupInput("group2Cols", NULL, choices = choices, selected = selected)
  })
  # Preload proteinGroups.txt if available
  defaultFile <- "proteinGroups.txt"
  fileExists <- file.exists(defaultFile)
  preloadedData <- if (fileExists) read.csv(defaultFile, sep = "\t", header = TRUE) else NULL

  dataRaw <- reactive({
    if (!is.null(input$fileUp)) {
      inFile <- input$fileUp
      if (is.null(inFile))
        return(NULL)
      df <- read.csv(inFile$datapath, sep = "\t", header = TRUE)
      return(df)
    } else if (fileExists) {
      return(preloadedData)
    } else {
      return(NULL)
    }
  })

  # Show available column names and a sample row
  output$columnInfo <- renderUI({
    df <- dataRaw()
    if (is.null(df)) return(NULL)
    sel <- input$selection
    all_cols <- colnames(df)
    # Always include the first column
    show_idx <- 1
    if (!is.null(sel) && sel != "") {
      match_idx <- grep(sel, all_cols)
      show_idx <- unique(c(1, match_idx))
    }
    show_cols <- all_cols[show_idx]
    colnames_str <- paste0(show_idx, ": ", show_cols, collapse = ", ")
    sample_row <- ""
    if (nrow(df) > 0 && length(show_idx) > 0) {
      # Defensive: handle single column as vector
      vals <- as.character(df[1, show_idx, drop=FALSE])
      if (length(vals) == 1 && is.null(dim(vals))) {
        sample_row <- vals
      } else {
        sample_row <- paste0(vals, collapse = ", ")
      }
    }
    tagList(
      tags$b("Available columns (position: name):"),
      tags$p(colnames_str),
      tags$b("First row (sample):"),
      tags$p(sample_row)
    )
  })


  # Show selected columns for each group
  output$selectedCols1 <- renderPrint({
    input$group1Cols
  })
  output$selectedCols2 <- renderPrint({
    input$group2Cols
  })

  # Use selected columns for each group
  selectedCols1 <- reactive({
    input$group1Cols
  })
  selectedCols2 <- reactive({
    input$group2Cols
  })

  # Data for each group (with debug output, only one definition)
  data2 <- reactive({
    df <- dataRaw()
    cols <- selectedCols1()
    if (is.null(cols) || length(cols) == 0) {
      output$selectedCols1 <- renderPrint({ "No columns selected for Group 1" })
      return(NULL)
    }
    cols <- intersect(cols, colnames(df))
    if (length(cols) == 0) {
      output$selectedCols1 <- renderPrint({ "No valid columns for Group 1" })
      return(NULL)
    }
    df2 <- df[, cols, drop = FALSE]
    rowN <- 1:nrow(df)
    if ("Protein.IDs" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Protein.IDs", colnames(df))], sep = ";;")
    }
    if ("Fasta.headers" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Fasta.headers", colnames(df))], sep = ";;")
    }
    rownames(df2) <- rowN
    return(df2)
  })
  data3 <- reactive({
    df <- dataRaw()
    cols <- selectedCols2()
    if (is.null(cols) || length(cols) == 0) {
      output$selectedCols2 <- renderPrint({ "No columns selected for Group 2" })
      return(NULL)
    }
    cols <- intersect(cols, colnames(df))
    if (length(cols) == 0) {
      output$selectedCols2 <- renderPrint({ "No valid columns for Group 2" })
      return(NULL)
    }
    df2 <- df[, cols, drop = FALSE]
    rowN <- 1:nrow(df)
    if ("Protein.IDs" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Protein.IDs", colnames(df))], sep = ";;")
    }
    if ("Fasta.headers" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Fasta.headers", colnames(df))], sep = ";;")
    }
    rownames(df2) <- rowN
    return(df2)
  })
  # For heatmap, show all selected columns from both groups
  data1 <- reactive({
    df <- dataRaw()
    cols <- unique(c(selectedCols1(), selectedCols2()))
    if (is.null(cols) || length(cols) == 0) return(NULL)
    cols <- intersect(cols, colnames(df))
    if (length(cols) == 0) return(NULL)
    df2 <- df[, cols, drop = FALSE]
    rowN <- 1:nrow(df)
    if ("Protein.IDs" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Protein.IDs", colnames(df))], sep = ";;")
    }
    if ("Fasta.headers" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Fasta.headers", colnames(df))], sep = ";;")
    }
    rownames(df2) <- rowN
    return(df2)
  })

  # Heatmap output: use the selected LFQ intensity matrix
  output$heatmap <- renderPlot({
    mat <- data1()
    if (!is.null(mat) && nrow(mat) > 1 && ncol(mat) > 1) {
      # Convert to numeric matrix (preserve rownames)
      mat2 <- as.matrix(sapply(mat, function(x) as.numeric(as.character(x))))
      rownames(mat2) <- rownames(mat)
      # Remove rows with all NA or all zero
      keep <- (rowSums(is.na(mat2)) < ncol(mat2)) & (rowSums(mat2, na.rm=TRUE) != 0)
      mat2 <- mat2[keep, , drop=FALSE]
      if (nrow(mat2) > 1 && ncol(mat2) > 1) {
        heatmap(mat2, main="Heatmap of selected LFQ intensities", Colv=NA, scale="row")
      }
    }
  })

  # Use only the selected columns for each group
  # Group 1 data
  data2 <- reactive({
    df <- dataRaw()
    cols <- selectedCols1()
    if (is.null(cols) || length(cols) == 0) return(NULL)
    cols <- intersect(cols, colnames(df))
    if (length(cols) == 0) return(NULL)
    df2 <- df[, cols, drop = FALSE]
    rowN <- 1:nrow(df)
    if ("Protein.IDs" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Protein.IDs", colnames(df))], sep = ";;")
    }
    if ("Fasta.headers" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Fasta.headers", colnames(df))], sep = ";;")
    }
    rownames(df2) <- rowN
    return(df2)
  })
  # Group 2 data
  data3 <- reactive({
    df <- dataRaw()
    cols <- selectedCols2()
    if (is.null(cols) || length(cols) == 0) return(NULL)
    cols <- intersect(cols, colnames(df))
    if (length(cols) == 0) return(NULL)
    df2 <- df[, cols, drop = FALSE]
    rowN <- 1:nrow(df)
    if ("Protein.IDs" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Protein.IDs", colnames(df))], sep = ";;")
    }
    if ("Fasta.headers" %in% colnames(df)) {
      rowN <- paste(rowN, df[, grep("Fasta.headers", colnames(df))], sep = ";;")
    }
    rownames(df2) <- rowN
    return(df2)
  })
  data4 <- reactive({
    d1 <- data2()
    d2 <- data3()
    if (is.null(d1) || is.null(d2) || ncol(d1) == 0 || ncol(d2) == 0) return(NULL)
    #colnames(LFQ)=sub(selection,"",colnames(LFQ))
    #dim(LFQ)
    df5 <- testT(d1, d2, Inf)
    rownames(df5) <- paste(rownames(d1), rownames(d2), sep = ";;")
    updateSelectInput(session, "seriesR", choices = colnames(df5))
    output$hist <- renderPlot({
      if (!is.null(input$seriesR) && input$seriesR %in% colnames(df5)) {
        hist(df5[, input$seriesR], main = input$seriesR)
      }
    })
    return(df5)
  })
  output$downloadData <- downloadHandler(
    filename = function() {
      # Extract alphanumeric values from both filter columns and the selection input, remove non-alphanumeric characters
      filter1 <- input$colFilter1
      filter2 <- input$colFilter2
      selection <- input$selection
      clean_str <- function(x) paste(unlist(regmatches(x, gregexpr("[A-Za-z0-9]+", x))), collapse="_")
      filter1_str <- clean_str(filter1)
      filter2_str <- clean_str(filter2)
      selection_str <- clean_str(selection)
      # Compose filename with cleaned filter values and selection string
      paste0(
        if (!is.null(input$fileUp) && !is.na(input$fileUp$name)) sub("\\.txt$", "", input$fileUp$name) else "proteinGroups",
        "_SEL-", selection_str,
        "_G1-", filter1_str,
        "_G2-", filter2_str,
        "_testT.csv"
      )
    },
    content = function(file) {
      write.csv(data4(), file)
    }
  )
  output$tableR <- DT::renderDataTable(data4())
  #output$table1 <- renderTable(data2())
  #output$table2 <- renderTable(data3())
  #output$value <- renderText({ input$selThr })
}
shinyApp(ui = ui, server = server)
