testT <- function(d1,d2,cvThr){
  #summary(log2LFQ)
  dataSellog2grpTtest<-as.matrix(cbind(d1,d2))
  dataSellog2grpTtest<-log2(dataSellog2grpTtest)
  dataSellog2grpTtest[dataSellog2grpTtest==-Inf]=NA
  if(sum(!is.na(dataSellog2grpTtest))>2){
    #hist(d1,breaks=round(max(dataSellog2grpTtest,na.rm=T)))
    #hist(d2,breaks=round(max(dataSellog2grpTtest,na.rm=T)))
    #assign(paste0("hda",sel1,sel2),dataSellog2grpTtest)
    #get(paste0("hda",sel1,sel2))
    #dataSellog2grpTtest[dataSellog2grpTtest==0]=NA
    #hist(dataSellog2grpTtest,breaks=round(max(dataSellog2grpTtest,na.rm=T)))
    #row.names(dataSellog2grpTtest)<-row.names(data)
    #comp<-paste0(sel1,sel2)
    sCol<-1
    eCol<-ncol(dataSellog2grpTtest)
    mCol<-ncol(d1)#ceiling((eCol-sCol+1)/2)
    dim(dataSellog2grpTtest)
    options(nwarnings = 1000000)
    pValNA = apply(
      dataSellog2grpTtest, 1, function(x)
        if(sum(!is.na(x[c(sCol:mCol)]))<2&sum(!is.na(x[c((mCol+1):eCol)]))<2){NA}
      else if(sum(is.na(x[c(sCol:mCol)]))==0&sum(is.na(x[c((mCol+1):eCol)]))==0){
        t.test(as.numeric(x[c(sCol:mCol)]),as.numeric(x[c((mCol+1):eCol)]),var.equal=T)$p.value}
      else if(sum(!is.na(x[c(sCol:mCol)]))>1&sum(!is.na(x[c((mCol+1):eCol)]))<1&(sd(x[c(sCol:mCol)],na.rm=T)/mean(x[c(sCol:mCol)],na.rm=T))<cvThr){0}
      else if(sum(!is.na(x[c(sCol:mCol)]))<1&sum(!is.na(x[c((mCol+1):eCol)]))>1&(sd(x[c((mCol+1):eCol)],na.rm=T)/mean(x[c((mCol+1):eCol)],na.rm=T))<cvThr){0}
      else if(sum(!is.na(x[c(sCol:mCol)]))>=2&sum(!is.na(x[c((mCol+1):eCol)]))>=1){
        t.test(as.numeric(x[c(sCol:mCol)]),as.numeric(x[c((mCol+1):eCol)]),na.rm=T,var.equal=T)$p.value}
      else if(sum(!is.na(x[c(sCol:mCol)]))>=1&sum(!is.na(x[c((mCol+1):eCol)]))>=2){
        t.test(as.numeric(x[c(sCol:mCol)]),as.numeric(x[c((mCol+1):eCol)]),na.rm=T,var.equal=T)$p.value}
      else{NA}
    )
    summary(warnings())
    #hist(pValNA)
    #summary(pValNA)
    dfpValNA<-as.data.frame(ceiling(pValNA))
    pValNAminusLog10 = -log10(pValNA+.Machine$double.xmin)
    #hist(pValNAminusLog10)
    #library(scales)
    #pValNAminusLog10=scale(pValNAminusLog10,c(0,5))
    #hist(pValNAminusLog10)
    length(pValNA)-(sum(is.na(pValNA))+sum(ceiling(pValNA)==0,na.rm = T))
    pValBHna = p.adjust(pValNA,method = "BH")
    #hist(pValBHna)
    pValBHnaMinusLog10 = -log10(pValBHna+.Machine$double.xmin)
    #hist(pValBHnaMinusLog10)
    logFCmedianGrp1=if(is.null(dim(dataSellog2grpTtest[,c(sCol:mCol)]))){dataSellog2grpTtest[,c(sCol:mCol)]} else{apply(dataSellog2grpTtest[,c(sCol:mCol)],1,function(x) median(x,na.rm=T))}
    grp1CV=if(is.null(dim(dataSellog2grpTtest[,c(sCol:mCol)]))){dataSellog2grpTtest[,c(sCol:mCol)]} else{apply(dataSellog2grpTtest[,c(sCol:mCol)],1,function(x) 100*sd(2^x,na.rm=T)/mean(2^x,na.rm=T))}
    #summary(logFCmedianGrp11-logFCmedianGrp1)
    logFCmedianGrp2=if(is.null(dim(dataSellog2grpTtest[,c((mCol+1):eCol)]))){dataSellog2grpTtest[,c((mCol+1):eCol)]} else{apply(dataSellog2grpTtest[,c((mCol+1):eCol)],1,function(x) median(x,na.rm=T))}
    grp2CV=if(is.null(dim(dataSellog2grpTtest[,c((mCol+1):eCol)]))){dataSellog2grpTtest[,c((mCol+1):eCol)]} else{apply(dataSellog2grpTtest[,c((mCol+1):eCol)],1,function(x) 100*sd(2^x,na.rm=T)/mean(2^x,na.rm=T))}
    logFCmedianGrp1[is.na(logFCmedianGrp1)]=0
    logFCmedianGrp2[is.na(logFCmedianGrp2)]=0
    #hda<-cbind(logFCmedianGrp1,logFCmedianGrp2)
    #plot(hda)
    #limma::vennDiagram(hda>0)
    logFCmedian = logFCmedianGrp1-logFCmedianGrp2
    logFCmedianFC = 2^(logFCmedian+.Machine$double.xmin)
    #logFCmedianFC=squish(logFCmedianFC,c(0.01,100))
    #hist(logFCmedianFC)
    log2FCmedianFC=log2(logFCmedianFC)
    #hist(log2FCmedianFC)
    ttest.results = data.frame(TtestPval=pValNA,CorrectedPValueBH=pValBHna,Log2MedianChange=logFCmedian,PValueMinusLog10=pValNAminusLog10,grp1CV,grp2CV,logFCmedianGrp1,logFCmedianGrp2,FoldChange=logFCmedianFC,dataSellog2grpTtest)
    #write.csv(ttest.results,paste0(inpF,selection,sCol,eCol,comp,selThr,selThrFC,cvThr,lGroup,rGroup,lName,"tTestBH.csv"),row.names = F)
    return(ttest.results)
  }
}
