#!/usr/bin/env Rscript
suppressPackageStartupMessages(library ("optparse"))
suppressPackageStartupMessages(library ("ape"))

option_list <- list( 
  make_option(c("-t", "--tree"),
              dest="treefile", help="Tree file (with branch lengths) in which to do dating analysis (newick format, possibly nexus)"),
  make_option(c("-c", "--calibration"), 
              dest="calfile",help="Tab separated file with: node, age.min, age.max, soft.bounds"),
  make_option(c("-o", "--output-file"), 
              dest="outfile", default="chronotree.tre", help="Name of output file, [default: %default])"),
  make_option(c("-l", "--lambda"), 
              dest="lambda", default=1.0, help="Lambda value for chronos function, [default: %default])"),
  make_option(c("-m", "--model"), 
              dest="model", default="correlated", help="Model for chronos function, [default: %default])"),
  make_option(c("--tol"), 
              dest="tol", default=1e-08, help="tol, [default: %default])"),
  make_option(c("--itermax"), 
              dest="itermax", default=1e+04, help="iter.max, [default: %default])"),
  make_option(c("--evalmax"), 
              dest="evalmax", default=1e+04, help="eval.max, [default: %default])"),
  make_option(c("--nbratecat"), 
              dest="nbratecat", default=10, help="nb.rate.cat, [default: %default])"),
  make_option(c("--dualitermax"), 
              dest="dualitermax", default=20, help="dual.iter.max, [default: %default])"),
  make_option(c("--overwrite"), 
              dest="overwrite", action="store_true", default=FALSE, help="Overwrite output file, [default %default])")
)


opt <- parse_args(OptionParser(option_list=option_list))

if( !opt$overwrite & file.access(opt$outfile) == 0) {
  stop(sprintf("Output file already exists, add the --overwrite option to skip this warning in the future: %s", opt$outfile))
}

if( file.access(opt$calfile) == -1) {
  stop(sprintf("Specified calibration file ( %s ) does not exist", opt$calfile))
}else {
  cal <- read.csv(opt$calfile, header = TRUE, sep = "\t", comment.char= "#")
}

if( file.access(opt$treefile) == -1) {
  stop(sprintf("Specified tree file ( %s ) does not exist", opt$treefile))
} else{
  tree <- read.tree(file=opt$treefile)
}

ctrl <- chronos.control(tol = opt$tol, iter.max = opt$itermax, eval.max = opt$evalmax, nb.rate.cat = opt$nbratecat, dual.iter.max = opt$dualitermax)

sprintf("Input tree: %s", opt$treefile)
sprintf("Calibration values: %s", cal)
sprintf("Output file: %s", opt$outfile)
sprintf("Model: %s", opt$model)
sprintf("Lambda: %s", opt$lambda)
sprintf("chronos.control values:")
ctrl

chronotree <- chronos(tree, calibration = cal, lambda = opt$lambda, model = opt$model, control = ctrl)
write.tree(chronotree, file=opt$outfile)

attributes(chronotree)