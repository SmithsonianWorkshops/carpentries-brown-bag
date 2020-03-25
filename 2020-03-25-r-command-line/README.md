# Running R scripts from the command line

Why do it?
- Automated execution
- Share with others
- Use command line arguments

Caveat:
- R (and all needed packages) still needs to be installed on the system
	- but see: https://github.com/wleepang/DesktopDeployR and https://www.r-bloggers.com/deploying-desktop-apps-with-r/ for standalone solutions

## Demo of my `chronos-tree.R` script on Hydra

```
./chronos-tree.R --help
./chronos-tree.R --tree iq2_part_208taxa_ufboot_rooted.tre --calibration calibrations.csv -o corr.tre
./chronos-tree.R --tree iq2_part_208taxa_ufboot_rooted.tre --calibration calibrations.csv --model "relaxed" -o relaxed.tree
```

## Part 1: calling your R script from the command line
- General ref: http://blog.sellorm.com/2017/12/18/learn-to-write-command-line-utilities-in-r/

1. Create new project in RStudio: `r-commandline`
1. "Terminal" tab in RStudio is a way to access the terminal/command prompt of your computer
	- Different from the console which is the R console, not your operating system's
1. Create a new new R script ([code samples from here](http://blog.sellorm.com/2017/12/18/learn-to-write-command-line-utilities-in-r/)):
```R
houses <- c("Hufflepuff", "Gryffindor", "Ravenclaw", "Slytherin")
house <- sample(houses, 1)
cat(house, "\n")
```
1. Save to the project directory.

### Run from the command line with `Rscript...`
1. Switch to "Terminal" tab in RStudio
1. Run with: `Rscript sortinghat.R`

### Run from the command line without `Rscript` (Unix/Mac only)
1. Tell the OS that the file is directly executable: (in Terminal tab)
`chmod +x sortinghat.R`
1. Tell the OS what program should be used to execute the script: (add to beginning of sortinghat.R): `#!/usr/bin/env Rscript`
1. try it out: `./sortinghat.R`

## Part 2: command line arguments
- Use this to provide options to the script that can then be used in the script

### Builtin function `commandArgs()`

- `commandArgs(trailingOnly = TRUE)`
	- Returns a character vector with each argument as a value
	- Why `trailingOnly = TRUE`? Otherwise you get a bunch of otherwise hidden arguments (e.g. `/Library/Frameworks/R.framework/Resources/bin/exec/R --slave --no-restore --file=./sortinghat.R --args Matt`)

New script:
```R
#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
houses <- c("Hufflepuff", "Gryffindor", "Ravenclaw", "Slytherin")
house <- sample(houses, 1)
cat(paste0("Hello ", args[1], ", you can join ", house, "\n"))
```

We can also do some testing by adding:
```R
if (length(args) < 1){
  stop("I think you forgot your name\n")
}
```

- Pros of `commandArgs()`:
  - Builtin to R
	- Straight foward to use (IMHO), just creates a vector of strings

- Cons:
	- Options need to be entered in a specific order
	- Cumbersome to make a help screen
	- Cumbersome to add names for the arguments (e.g. `--name Matt`)


### `optparse` package

**All of these require an additional package be installed**
- `optparse`: Similar to Python `optparse` ([optparse documentation](https://cran.r-project.org/web/packages/optparse/index.html))
- Similar R packages (I haven't tried these)
	- `argparse`: uses Python's `argparse` to read in arguments (requires Python install)
	- `getopt`: C-style argument library
	- `argparser`: native R implementation of Python's `argparse`

```R
install.packages("optparse")
library(optparse)
```

#### `make_option`

```R
make_option(c("-n", "--name"),
						dest = "pupil_name", help = "Name of the Witch or Wizard [default: %default]",
						default = "Harry")
```

- `c("-n", "--name")`: how argument is called
- `dest="pupil_name"`: object that will store the argument
- `help="Name of the Witch or Wizard [default: %default]"`: help text, `%default` will be replaced with default value you define.
- `default = "Harry"`: (optional) default value if argument is not given

#### `parse_args`

```R
opt <- (OptionParser(option_list = option_list))
opt$pupil_name
```

#### more `make_option` options:
- `type = "integer"`: type of object to be created (produces warning if supplied argument is not that type)
- `action = "store_true"`: sets the object to `TRUE` if flag is supplied (example, `--verbose`)
- `action = "store_false"`: sets the object to `FALSE` if flag is supplied

### Final script

```R
#!/usr/bin/env Rscript
library ("optparse")

option_list <- list(
 make_option(c("-n", "--name"),
             dest = "pupil_name", help = "Name of the Witch or Wizard [default: %default]",
             default = "Harry"),
 make_option(c("-a", "--age"),
             dest = "pupil_age", help = "Age of the Witch or Wizard [default: %default]",
             default = 11,
             type = "integer"),
 make_option(c("--slytherin"),
             dest="is_slytherin",
             action = "store_true",
             default = FALSE,
             help = "Force pupil into Slytherin [default: %default]")
)

opt <- parse_args(OptionParser(option_list = option_list))

houses <- c("Hufflepuff", "Gryffindor", "Ravenclaw", "Slytherin")

if (opt$is_slytherin){
  house <- "Slytherin"
} else
{
  house <- sample(houses, 1)
}

cat(paste0("Hello ", opt$pupil_age, " year old ", opt$pupil_name, ", you can join ", house, "\n"))
```
