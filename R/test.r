inpF <- "elife-45916-Cdc42QL_data.csv"
data <- read.csv(inpF)
#clean
#data = data[!data$Reverse=="+",]
#data = data[!data$Potential.contaminant=="+",]
#data = data[!data$Only.identified.by.site=="+",]
#row.names(data)<-paste(row.names(data),data$Fasta.headers,data$Protein.IDs,data$Protein.names,data$Gene.names,data$Score,data$Peptide.counts..unique.,sep=";;")
summary(data)
dim(data)
selection<-"o"
LFQ<-as.matrix(data[,grep(selection,colnames(data))])
LFQ<-as.data.frame(LFQ[,c(2:5)])
LFQ<-sapply(LFQ, as.numeric)
dim(LFQ)
log2LFQ<-log2(LFQ)
log2LFQ[log2LFQ==-Inf]=NA
log2LFQ[log2LFQ==0]=NA
summary(log2LFQ)
hist(log2LFQ)
rowName<-data$Uniprot
rowName<-sub("ProteinCenter:sp_tr_incl_isoforms\\|","",rowName)
rowName<-gsub("\r","",rowName)
rowName<-gsub("\n","",rowName)
#rownames(data)<-rowName
#rowName<-paste(sapply(strsplit(paste(sapply(strsplit(rowName, ">",fixed=T), "[", 2)), " "), "[", 1))
write.table(as.data.frame(cbind(Uniprot=rowName,log2LFQ)),paste0(inpF,"log2LFQ.txt"),row.names = F,sep="\t",quote = FALSE)
hda<-as.matrix(log2LFQ[,grep("WD",colnames(log2LFQ))])
hist(as.matrix(hda))
WT<-apply(hda,1,function(x) if(sum(is.na(x))<ncol(hda)){median(x,na.rm=T)} else{0})
sum(WT>0)
inpW<-paste0(inpF,"sel-LFQ-control.xlsx")
hdaWT<-hda
hda<-as.matrix(log2LFQ[,grep("log",colnames(log2LFQ))])
hist(as.matrix(hda))
MUTYHHA<-apply(hda,1,function(x) if(sum(is.na(x))<ncol(hda)){median(x,na.rm=T)} else{0})
sum(MUTYHHA>0)
inpW<-paste0(inpF,"sel-LFQ-MUTYHHA.xlsx")
hdaMUTYHHA<-hda
dataSellog2grpTtest<-cbind(hdaMUTYHHA,hdaWT)
summary(dataSellog2grpTtest)
compName<-colnames(dataSellog2grpTtest)
compName<-toString(compName)
compName<-gsub(" ", "",compName)
compName<-gsub(",", "",compName)
row.names(dataSellog2grpTtest)<-row.names(data)
sCol<-1
eCol<-4
mCol<-2
t.test(as.numeric(dataSellog2grpTtest[1,c(sCol:mCol)]),as.numeric(dataSellog2grpTtest[1,c((mCol+1):eCol)]),na.rm=T)$p.value
chkr<-1
sum(!is.na(dataSellog2grpTtest[chkr,c(1:eCol)]))
t.test(as.numeric(dataSellog2grpTtest[chkr,c(sCol:mCol)]),as.numeric(dataSellog2grpTtest[chkr,c((mCol+1):eCol)]),na.rm=T)$p.value
dim(dataSellog2grpTtest)
options(nwarnings = 1000000)
pValNA = apply(
  dataSellog2grpTtest, 1, function(x)
    if(sum(!is.na(x[c(sCol:mCol)]))<2&sum(!is.na(x[c((mCol+1):eCol)]))<2){NA}
  else if(sum(is.na(x[c(sCol:mCol)]))==0&sum(is.na(x[c((mCol+1):eCol)]))==0){
    t.test(as.numeric(x[c(sCol:mCol)]),as.numeric(x[c((mCol+1):eCol)]),var.equal=T)$p.value}
  else if(sum(!is.na(x[c(sCol:mCol)]))>1&sum(!is.na(x[c((mCol+1):eCol)]))<1){0}
  else if(sum(!is.na(x[c(sCol:mCol)]))<1&sum(!is.na(x[c((mCol+1):eCol)]))>1){0}
  else if(sum(!is.na(x[c(sCol:mCol)]))>=2&sum(!is.na(x[c((mCol+1):eCol)]))>=2){
    t.test(as.numeric(x[c(sCol:mCol)]),as.numeric(x[c((mCol+1):eCol)]),na.rm=T,var.equal=T)$p.value}
  else{NA}
)
summary(warnings())
hist(pValNA)
pValNAdm<-cbind(pValNA,dataSellog2grpTtest,row.names(data))
pValNAminusLog10 = -log10(pValNA+.Machine$double.xmin)
hist(pValNAminusLog10)
pValBHna = p.adjust(pValNA,method = "BH")
hist(pValBHna)
pValBHnaMinusLog10 = -log10(pValBHna+.Machine$double.xmin)
hist(pValBHnaMinusLog10)
dataSellog2grpTtestNum<-apply(dataSellog2grpTtest, 2,as.numeric)
logFCmedianGrp1 = median(dataSellog2grpTtestNum[,c(sCol:mCol)],na.rm=T)
logFCmedianGrp2 = median(dataSellog2grpTtestNum[,c((mCol+1):eCol)],na.rm=T)
logFCmedianGrp1[is.nan(logFCmedianGrp1)]=0
logFCmedianGrp2[is.nan(logFCmedianGrp2)]=0
logFCmedian = logFCmedianGrp1-logFCmedianGrp2
logFCmedianFC = 2^(logFCmedian+.Machine$double.xmin)
hist(logFCmedianFC)
log2FCmedianFC=log2(logFCmedianFC)
hist(log2FCmedianFC)
ttest.results = data.frame(Uniprot=rowName,PValueMinusLog10=pValNAminusLog10,FoldChanglog2median=logFCmedianFC,CorrectedPValueBH=pValBHna,TtestPval=pValNA,dataSellog2grpTtest,Log2MedianChange=logFCmedian,RowGeneUniProtScorePeps=rownames(dataSellog2grpTtest))
write.table(ttest.results,paste0(inpF,selection,sCol,eCol,compName,"tTestOGG1HAWT.txt"),row.names = F,sep="\t")
