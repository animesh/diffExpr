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
  fileInput("fileUp", "Upload proteinGroups.txt", multiple = FALSE,
            accept = c("text","text/tab-separated-values,text/plain",".txt"),
            width = NULL, buttonLabel = "Browse...",
            placeholder = "No file selected"),
  #sliderInput("thr", "Observations:", 0, min = 0, max = 100),
  #sliderInput("selThr", "FDR:", 0.05, min = 0, max = 1),
  #sliderInput("selThrFC", "Log2 Fold Change:", 0.5, min = 0, max = 1),
  #numericInput("cvThr", "Observations:", 0.1, min = 0, max = 1),
  #sliderInput("cvThr", "Coefficient of Var:", 0.1, min = 0, max = 1),
  #verbatimTextOutput("thr"),
  textInput("selection", "Select columns starting with", value = "LFQ.intensity.", width = '500px', placeholder = NULL),
  textInput("series1", "Select columns for Group 1", value = "43_|44_|45_|46_|47_|48_",  width = '500px', placeholder = NULL),
  textInput("series2", "Select columns for Group 2", value = "37_|38_|39_|40_|41_|42_", width = '500px', placeholder = NULL),
  #selectInput("series1", "Group 1 LFQ columns:", choices=c()),
  #selectInput("series2", "Group 2 LFQ columns:", choices=c()),
  downloadButton("downloadData", "Download"),
  selectInput("seriesR", "Result & log2LFQ group columns:", width='500px',choices=c()),
  mainPanel(
    plotOutput("hist"),
    tableOutput("tableR")#,
    #tableOutput("table1"),
    #tableOutput("table2")
  )
)
server <- function(session,input,output) {
  data1 <- reactive({
    validate(need(input$fileUp,""))
    inFile <- input$fileUp
    if (is.null(inFile))
      return(NULL)
    df <- read.csv(inFile$datapath,sep="\t",header=TRUE)
    #df <- read.csv("proteinGroups.txt",sep="\t",header=TRUE)
    df2 <- df[,grep(input$selection,colnames(df))]
    colnames(df2)<-gsub(input$selection,"",colnames(df2))
    rowN<-1:nrow(df)
    if("Protein.IDs" %in% colnames(df)){
      rowN<-paste(rowN,df[,grep("Protein.IDs",colnames(df))],sep=";;")
    }
    if("Fasta.headers" %in% colnames(df)){
      rowN<-paste(rowN,df[,grep("Fasta.headers",colnames(df))],sep=";;")
    }
    rownames(df2)<-rowN
    #df2 <- head(df2, 20)
  return(df2)
})

  data2 <- reactive({
    df3 <- data1()
    df3 <- df3[,grep(c(input$series1),colnames(df3))]
    #updateSelectInput(session,"series1",choices=colnames(df3))
    return(df3)
  })

  data3 <- reactive({
    df4 <- data1()
    df4 <- df4[,grep(c(input$series2),colnames(df4))]
    #updateSelectInput(session,"series2",choices=colnames(df4))
    return(df4)
  })
  data4 <- reactive({
    d1<-data2()
    d2<-data3()
    #colnames(LFQ)=sub(selection,"",colnames(LFQ))
  #dim(LFQ)
  df5<-testT(d1,d2,Inf)
  rownames(df5)<-paste(rownames(d1),rownames(d2),sep=";;")
  #rowName<-paste(sapply(strsplit(paste(sapply(strsplit(data$Fasta.headers, "|",fixed=T), "[", 2)), "-"), "[", 1))
  #data$geneName<-paste(sapply(strsplit(paste(sapply(strsplit(data$Fasta.headers, "_",fixed=T), "[", 2)), "OS="), "[", 1))
  #data$uniprotID<-paste(sapply(strsplit(paste(sapply(strsplit(data$Protein.IDs, ";",fixed=T), "[", 1)), "-"), "[", 1))
  #data[data$geneName=="NA","geneName"]=data[data$geneName=="NA","uniprotID"]
  #ttest.results$RowGeneUniProtScorePeps<-data$geneName
  #ttest.results[is.na(ttest.results)]=selThr
  #Significance=ttest.results$CorrectedPValueBH<selThr&ttest.results$CorrectedPValueBH>0&abs(ttest.results$Log2MedianChange)>selThrFC
  #sum(Significance)
  #dsub <- subset(ttest.results,Significance)
  updateSelectInput(session,"seriesR",choices=colnames(df5))
  output$hist <- renderPlot(hist(df5[,input$seriesR],main=input$seriesR))
  return(df5)
  })
  output$downloadData <- downloadHandler(
    filename = function() {
      paste(input$fileUp,input$selection,input$series1,input$series2,"testT.csv",sep=".")
    },
    content = function(file) {
      write.csv(data4(), file)
    }
  )
  output$tableR <- renderTable(data4())
  #output$table1 <- renderTable(data2())
  #output$table2 <- renderTable(data3())
  #output$value <- renderText({ input$selThr })
}
shinyApp(ui = ui, server = server)
