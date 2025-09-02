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
  titlePanel("T test with FDR over log2-transform of selected columns from MaxLFQ output"),
  textInput("selection", "Select columns starting with", value = "LFQ.intensity", width = '500px', placeholder = NULL),
  fileInput("fileUp", "Upload proteinGroups.txt", multiple = FALSE,
            accept = c("text","text/tab-separated-values,text/plain",".txt"),
            width = NULL, buttonLabel = "Browse...",
            placeholder = "No file selected"),
  uiOutput("columnInfo"),
  fluidRow(
    column(6,
      h4("Select columns for Group 1:"),
  textInput("colFilter1", "Select columns (Group 1):", value = "43_|44_|45_|46_|47_|48_"),
  uiOutput("group1Checkboxes"),
  verbatimTextOutput("selectedCols1")
    ),
    column(6,
      h4("Select columns for Group 2:"),
  textInput("colFilter2", "Select columns (Group 2):", value = "37_|38_|39_|40_|41_|42_"),
  uiOutput("group2Checkboxes"),
  verbatimTextOutput("selectedCols2")
    )
  ),
  #selectInput("series1", "Group 1 LFQ columns:", choices=c()),
  #selectInput("series2", "Group 2 LFQ columns:", choices=c()),
  actionButton("runTTest", "Run t-test"),
  downloadButton("downloadData", "Download"),
  selectInput("seriesR", "Result & log2LFQ group columns:", width='500px',choices=c()),
  mainPanel(
    plotOutput("hist"),
    plotOutput("heatmap"),
    plotOutput("volcano"),
    hr(),
  selectInput("searchCol", "Select column to search:", choices = NULL),
  textInput("searchText", "Search for:", value = ""),
    actionButton("runSearch", "Run Search"),
    tableOutput("searchTable")
    #tableOutput("table1"),
    #tableOutput("table2")
  )
)
server <- function(session,input,output) {
  # Update search column choices when ttestResult changes
  observe({
    df <- ttestResult()
    if (!is.null(df)) {
      rn <- rownames(df)
      col_choices <- c("Rowname", colnames(df))
      updateSelectInput(session, "searchCol", choices = col_choices, selected = "Rowname")
      # Set default search text to first rowname
      if (length(rn) > 0) {
        updateTextInput(session, "searchText", value = rn[1])
      }
    } else {
      updateSelectInput(session, "searchCol", choices = character(0))
      updateTextInput(session, "searchText", value = "")
    }
  })

  # Reactive value to store search results
  searchResult <- reactiveVal(NULL)

  observeEvent(input$runSearch, {
    df <- ttestResult()
    col <- input$searchCol
    txt <- input$searchText
    if (!is.null(df) && !is.null(col) && nzchar(txt)) {
      if (col == "Rowname") {
        vals <- rownames(df)
      } else if (col %in% colnames(df)) {
        vals <- as.character(df[[col]])
      } else {
        vals <- rep("", nrow(df))
      }
      keep <- grepl(txt, vals, ignore.case = TRUE)
      res <- df[keep, , drop = FALSE]
      searchResult(res)
    } else {
      searchResult(NULL)
    }
  })

  output$searchTable <- renderTable({
    searchResult()
  }, rownames = TRUE)
  # Volcano plot output: log2 median change vs -log10 p-value
  output$volcano <- renderPlot({
    df <- ttestResult()
    if (!is.null(df) &&
        ("Log2MedianChange" %in% colnames(df) || "Log2.Median.Change" %in% colnames(df)) &&
        ("PValueMinusLog10" %in% colnames(df) || "PValue.MinusLog10" %in% colnames(df)) &&
        ("CorrectedPValueBH" %in% colnames(df) || "Corrected.P.Value.BH" %in% colnames(df)) &&
        nrow(df) > 0) {
      # Support both possible column names
      xcol <- if ("Log2MedianChange" %in% colnames(df)) "Log2MedianChange" else "Log2.Median.Change"
      ycol <- if ("PValueMinusLog10" %in% colnames(df)) "PValueMinusLog10" else "PValue.MinusLog10"
      pcol <- if ("CorrectedPValueBH" %in% colnames(df)) "CorrectedPValueBH" else "Corrected.P.Value.BH"
      xvals <- pmax(pmin(df[[xcol]], 10), -10)
      yvals <- pmax(pmin(df[[ycol]], 5), 0)
      pvals <- df[[pcol]]
      # Color: grayscale based on p-value (low p = black, high p = light gray), NA = mid gray
      pvals_clamped <- pmin(pmax(pvals, 0), 1)
      cols <- rep("white", length(pvals_clamped)) # NA = white
      not_na <- !is.na(pvals_clamped)
      if (any(not_na)) {
        # 1-p: low p = 1 (black), high p = 0 (white)
        grayvals <- 1 - pvals_clamped[not_na]
        # Clamp to [0,1]
        grayvals <- pmin(pmax(grayvals, 0), 1)
        cols[not_na] <- gray(grayvals)
      }
      plot(
        xvals,
        yvals,
        xlab = "Log2 Median Change",
        ylab = "-log10(p-value)",
        main = "Volcano Plot",
        pch = 20,
        col = cols,
        xlim = c(-10, 10),
        ylim = c(0, 5)
      )
      abline(h = -log10(0.05), col = "black", lty = 2)
      abline(v = c(-1, 1), col = "black", lty = 2)
    } else {
      plot.new(); title(main="No volcano data available")
    }
  })
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
  # For heatmap, always use all selected columns from both groups (not just group 1)
  data1 <- reactive({
    df <- dataRaw()
    # Combine columns from both groups
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

  # Heatmap output: use only image() and robust error handling
  observeEvent(input$runTTest, {
    mat <- data1()
    output$heatmap <- renderPlot({
      if (!is.null(mat) && nrow(mat) > 1 && ncol(mat) > 1) {
        mat_num <- suppressWarnings(as.matrix(sapply(mat, as.numeric)))
        miss_mat <- ifelse(is.na(mat_num) | mat_num == 0, 1, 0)
        keep <- rowSums(miss_mat) > 0
        miss_mat <- miss_mat[keep, , drop=FALSE]
        if (nrow(miss_mat) > 1 && ncol(miss_mat) > 1) {
          image(
            x = 1:nrow(miss_mat),
            y = 1:ncol(miss_mat),
            z = miss_mat,
            col = gray.colors(256, start=1, end=0),
            axes = FALSE,
            xlab = "Protein groups rows",
            ylab = "",
            main = "Heatmap of Missing Values"
          )
          axis(2, at=1:ncol(miss_mat), labels=colnames(miss_mat), las=2, cex.axis=0.7)
          box()
        } else {
          plot.new(); title(main="No missing/zero values to display")
        }
      } else {
        plot.new(); title(main="Not enough data for heatmap")
      }
    })
  })

  # Use only the selected columns for each group
  # Group 1 data
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
  ttestResult <- reactiveVal(NULL)

  observeEvent(input$runTTest, {
    d1 <- data2()
    d2 <- data3()
    if (is.null(d1) || is.null(d2) || ncol(d1) == 0 || ncol(d2) == 0) {
      ttestResult(NULL)
      updateSelectInput(session, "seriesR", choices = character(0))
      output$hist <- renderPlot({})
      return()
    }
    df5 <- testT(d1, d2, Inf)
    rownames(df5) <- paste(rownames(d1), rownames(d2), sep = ";;")
    ttestResult(df5)
    updateSelectInput(session, "seriesR", choices = colnames(df5))
    output$hist <- renderPlot({
      if (!is.null(input$seriesR) && input$seriesR %in% colnames(df5)) {
        hist(df5[, input$seriesR], main = input$seriesR)
      }
    })
  })

  output$downloadData <- downloadHandler(
    filename = function() {
      # Extract alphanumeric values from both Select columns and the selection input, remove non-alphanumeric characters
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
      write.csv(ttestResult(), file)
    }
  )
  # output$tableR removed
  #output$table1 <- renderTable(data2())
  #output$table2 <- renderTable(data3())
  #output$value <- renderText({ input$selThr })
}
shinyApp(ui = ui, server = server)
