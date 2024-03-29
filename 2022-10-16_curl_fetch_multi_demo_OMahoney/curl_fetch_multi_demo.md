------------------------------------------------------------------------

## Documentation of `curl_fetch` functions

### [Link to thorough package walkthrough](https://cran.r-project.org/web/packages/curl/vignettes/intro.html)

### Description

These functions are low-level bindings to write data from a URL into
memory, disk or a callback function. These are mainly intended for
`httr`, most users will be better off using the `curl` or
`curl_download` function, or the http specific wrappers in the `httr`
package.

### Usage

    curl_fetch_memory(url, handle = new_handle())

    curl_fetch_disk(url, path, handle = new_handle())

    curl_fetch_stream(url, fun, handle = new_handle())

    curl_fetch_multi(
      url,
      done = NULL,
      fail = NULL,
      pool = NULL,
      data = NULL,
      handle = new_handle()
    )

    curl_fetch_echo(url, handle = new_handle())

### Arguments

-   **url** - A character string naming the URL of a resource to be
    downloaded.
-   **handle** - A curl handle object defined by the user to send a
    customized request
    -   See
        [`curl_easy_setopt`](https://curl.se/libcurl/c/curl_easy_setopt.html)
        for more details
-   **path** - Path where the response is written
-   **fun** - Callback function. Should have one argument, which will be
    a raw vector.
-   **done** - Callback function for completed request. Single argument
    with response data in same structure as `curl_fetch_memory`.
-   **fail** - Callback function called on failed request. Argument
    contains error message.
-   **pool** - A multi handle created by `new_pool`. Default uses a
    global pool.
-   **data** - *(advanced)* Callback function, file path, or connection
    object for writing incoming data. This callback should only be used
    for *streaming* applications, where small pieces of incoming data
    get written before the request has completed. The signature for the
    callback function is `write(data, final = FALSE)`. If set to NULL
    the entire response gets buffered internally and returned by in the
    done callback (which is usually what you want).

### Examples

#### curl\_fetch\_memory

    res <- curl_fetch_memory("http://httpbin.org/cookies/set?foo=123&bar=ftw")
    str(res)
    res$content

#### curl\_fetch\_disk

    res <- curl_fetch_disk("http://httpbin.org/stream/10", tempfile())
    res$content
    readLines(res$content)

#### curl\_fetch\_stream

    res <- curl_fetch_stream("http://www.httpbin.org/drip?duration=3&numbytes=15&code=200", function(x){
      cat(rawToChar(x))
    })

### `curl_fetch_multi`

It is the asynchronous equivalent of `curl_fetch_memory`. It wraps
`multi_add` to schedule requests which are executed concurrently when
calling `multi_run`. For each successful request the `done` callback is
triggered with response data. For failed requests (when
`curl_fetch_memory` would raise an error), the `fail` function is
triggered with the error message. Note that failure here means something
went wrong in performing the request such as a connection failure, it
does not check the http status code. Just like `curl_fetch_memory`, the
user has to implement application logic.

It is also important to note that raising an error within a callback
function stops execution of that function but does not affect other
requests.

Requests are created in the usual way using a curl handle and added to
the scheduler with `multi_add`. This function returns immediately and
does not perform the request yet. The user needs to call `multi_run`
which performs all scheduled requests concurrently. It returns when all
requests have completed, or case of a timeout or SIGINT

#### Example

    data <- list()
    success <- function(res){
      cat("Request done! Status:", res$status, "\n")
      data <<- c(data, list(res))
    }
    failure <- function(msg){
      cat("Oh noes! Request failed!", msg, "\n")
    }
    curl_fetch_multi("http://httpbin.org/get", success, failure)
    curl_fetch_multi("http://httpbin.org/status/418", success, failure)
    curl_fetch_multi("https://urldoesnotexist.xyz", success, failure)
    multi_run()
    str(data)

------------------------------------------------------------------------

## AphiaID Retrieval Script

This script is designed to retrieve **AphiaIDs** from the World Register
of Marine Species [(WoRMS)](https://www.marinespecies.org/). An AphiaID
is a unique identifier given to each species in the WoRMS database. They
are generated using the Life Science Identifiers
[(LSID)](https://sourceforge.net/projects/lsids/) protocol and are
structured like:

> <a href="urn:lsid:\" class="uri">urn:lsid:\</a>&lt;Authority&gt;:&lt;Namespace&gt;:&lt;ObjectID&gt;\[:&lt;Version&gt;\]

So the AphiaID for *Polycirrus brutus* would be:

> <urn:lsid:marinespecies.org:taxname:867804>

WoRMS not only stores accepted and unaccepted taxonomies, but also
maintains the relationships between these names. This makes it
incredibly useful for performing taxonomic quality control like updating
synonymized taxa.

WoRMS supports a number of tools for querying their database.
Descriptions and examples of these web services can be found here:
<https://www.marinespecies.org/aphia.php?p=webservice>

### Required packages

You will need to install these packages if they are not already on you
setup

    install.packages("geomedb") # used to query GEOME and retrieve input data
    install.packages("jsonlite") # used to convert between JSON and R objects
    install.packages("curl") # used to make requests asynchronously
    install.packages("progress") # used to create progress bar

Load the libraries

    library(geomedb)
    library(jsonlite)
    library(curl)
    library(progress)

### Input data

Get the data from GEOME and prepare it

    # Query GEOME metadata and store all scientificNames of samples in the BOEM Project (44)
    df <- queryMetadata('Sample', 
                        projects = list(44), 
                        source = list(
                          "materialSampleID",
                          "subProject",
                          "bcid",
                          "phylum",
                          "scientificName",
                          "wormsID",
                          "taxonRank",
                          "institutionCode",
                          "eventID",
                          "sampleEnteredBy"
                        ),
                        limit = 1000000
    )

    # Convert df from a list of lists into a dataframe
    df <- as.data.frame(do.call(rbind, df))

    # Return a list of unique scientificNames
    unique_taxa <- unique(df$scientificName)

    # Limit the taxa to 300 for demo
    unique_taxa <- unique_taxa[1:300]

    # Split list of unique taxa into lists of 100
    unique_taxa_split <- split(unique_taxa, ceiling(seq_along(unique_taxa) / 100))

### Function 1: WoRMS URL Generator

Generate the formatted URLs from the `unique_taxa` vector from the
previous code snippet

    gen_worms_urls <- function(data) {
      
      # Split list of taxa into lists of 10
      data_split <- split(data, ceiling(seq_along(data) / 10))
      
      # run lapply to append query language to each value in each list
      # then collapse the 10 values in the sublists into 1 value
      url_names_part <- lapply(data_split, function(x) paste0("&scientificnames[]=", x, sep = '', collapse = ''))
      
      # Remove spaces and other characters that URLs do not like
      url_names_part <- URLencode(url_names_part)
      
      #The dyanmic build of the URL causes an obsolete '&' at the beginning of the string, so remove it
      url_names_part <- substring(url_names_part, 2)
      
      #Build the final REST-urls
      urls <- sprintf("http://www.marinespecies.org/rest/AphiaRecordsByMatchNames?%s%s", url_names_part, "&marine_only=true")
      
      return(urls)
    }

### Function 2: WoRMS Taxonomy Query

Create pool of requests using the URLs generated by the previous
function

    worms_taxa_query <- function(data) {
      
      # Call function to generate querystrings from taxonomy list
      url <- gen_worms_urls(data)
      
      # Empty dataframe to store final output
      output <- vector() 
      
      # Create pool 
      pl <- new_pool()
      
      # Create a new instance of the progress bar with ETA
      pb <- progress_bar$new(
        format = " downloading [:bar] :percent | time elapsed::elapsedfull",
        total = length(url), clear = FALSE, width = 70
      )
      
      # Create done function
      done_function <- function(x) { 
        # Initiate progress bar with elapsed time
        pb$tick(0)
        # Update progress bar each time the function is run
        pb$tick()
        
        # Append the returned JSON to output
        output <<- append(output, fromJSON(rawToChar(x$content), flatten = TRUE))
        
        # Put system to sleep to avoid a 429 Too Many Requests Error
        Sys.sleep(1/100)
      }
      
      # populate pool with curl_fetch_multi requests 
      lapply(url, function(x) { curl_fetch_multi(x, done = done_function, pool = pl) })
      
      # Run the REST requests in parallel
      multi_run(pool = pl)
      
      # format the output as a dataframe
      output <- as.data.frame(do.call(rbind, output))
    }

### Execution

Create an empty dataframe to store the output. Then execute the
`for loop` using the `unique_taxa_split` variable as input to create the
request pool of 100 taxonomies for each run.

    # Create empty data.frame for output to append to
    output <- data.frame()

    # Run each taxa chunk as input for worms_taxa_query function
    for (i in 1:length(unique_taxa_split)) {
      Sys.sleep(1/50)
      progress <- sprintf("Download: %s of %s", i, length(unique_taxa_split))
      print(progress)
      input <- unlist(unique_taxa_split[i])
      worm_out <- worms_taxa_query(input)
      output <- rbind(output, worm_out)
      
    }

### Merge and Write

Merge the resulting output with the original dataframe from GEOME. Then
create two new dataframes containing records with AphiaIDs and records
without AphiaIDs. Write them as tsvs.

    # Perform a left outer join between df and output
    df_merge <- merge(df, output,
                      by.x = c('scientificName', 'taxonRank'),
                      by.y = c('scientificname', 'rank'), all.x = TRUE)

    # Store AphiaIDs in the wormsID column
    df_merge$wormsID <- df_merge$AphiaID

    # Create new dataframes for samples with wormsIDs and those with null wormsIDs
    df_merge_id <- df_merge[!is.na(df_merge$wormsID),]
    df_merge_na <- df_merge[is.na(df_merge$wormsID),]

    # Write out the above data frames
    write.table(df_merge_id,
                file = "GEOME_AphiaID.tsv",
                sep = "\t", 
                row.names = FALSE, 
                col.names = TRUE,
                na = "NA",
                fileEncoding = "UTF-8")

    write.table(df_merge_na,
                file = "GEOME_AphiaID_NA.tsv",
                sep = "\t", 
                row.names = FALSE, 
                col.names = TRUE,
                na = "NA",
                fileEncoding = "UTF-8")

## Looking Forward

-   Try to incorporate exception handling to prevent the program from
    exiting when the connection is refused.
-   [Michael Koohafkan’s research
    blog](https://hydroecology.net/asynchronous-web-requests-with-curl/)
    has a great entry for generating unique IDs for each request that
    makes it easier to pair request responses with requests. This would
    make merging the data a bit more seamless.
