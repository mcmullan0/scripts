# Runs after window.pl -p (cat file.csv | Rscript) saves output as Rplots.pdf
f <- file("stdin")
data <- read.table(f, header=F,sep=",")
pdf()
attach(data); plot(data, type="l",col=c("red")); detach(data)
title("Title/Window X")
dev.off()
