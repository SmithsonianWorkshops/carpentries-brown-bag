2019-09-26

Summary notes of the demo given today in the Brown Bag. 

## Querying EDAN using R or Python

These two packages allow you to query the EDAN API in either R or Python. The code takes care of formatting the query and the credentials that the API expects.

The packages to query the EDAN API are available at:

 * R: https://github.com/Smithsonian/EDANr
 * Python: https://github.com/Smithsonian/EDAN-python

Either one can be further expanded with more functions that query other API routes or help in the search. Feel free to submit a pull request if you want to contribute your code.

### EDAN key

The use of the EDAN API requires a key. The functions in the packages require you to provide the AppID and AppKey you get from EDAN. Request a key at this link: 

https://edandoc.si.edu/request-credentials

### EDANr

The EDANr package is not available from CRAN. You can install it from Github using `devtools`: 

```R
#Install devtools, if needed
install.packages("devtools")

#Install package from Github, with vignettes
library(devtools)
install_github("Smithsonian/EDANr", build_vignettes = TRUE)
```

EDANr requires the packages `httr`, `uuid`, `stringr`, `jsonlite`, `digest`, and `openssl`. These should be installed automatically when using `install_github("Smithsonian/EDANr")`. To install these manually:

```R
install.packages(c("httr", "uuid", "stringr", "jsonlite", "digest", "openssl"))
```

The package has two functions:

* searchEDAN()
* getContentEDAN()

Example of searching EDAN for orchid images: https://github.com/Smithsonian/EDANr/wiki/Searching-for-Images

### EDAN-python

The EDAN script has not been converted Save the file edan.py from the repository and load it as a module:

```python
import edan
```

There are two functions:

* searchEDAN()
* getContentEDAN()

There are some examples of querying the API here: https://github.com/Smithsonian/EDAN-python/blob/master/README.md

### EDAN API reference

The reference site has a lot of detail of the other routes available in the API:

https://edandoc.si.edu/
