## Polars and DuckDB

**Is your data too big for pandas or dplyr?**

Get past those limitations by using [Polars](https://www.pola.rs/) or [DuckDB](https://duckdb.org/) to work with huge tabular data in Python or R.

### Presentation

Mike gave a very short presentation in Google Slides, but it's probably just as fine in outline form here:

* The Problem
    * When you use `read_csv` in Pandas (Python) or Dplyr (R), you read the entire contents of the file into memory. This is fine for most use cases, but can cause a real issue with multi-GB files.
* Solution: lazy evaluation
    * Both Polars and DuckDB first read in a "query", and then plan out which portions of a file they need to read in before processing.
* Not written in Python or R
    * Polars is written in Rust, which is bright new and shiny. DuckDB is written in C++, which is tried-and-true, and fast.
* Apache Arrow exchange format
    * Both libraries use [Apache Arrow](https://arrow.apache.org/) to exchange optimized versions of dataframes in memory. Ironically, this project was created by the creator of Pandas (which typically has inefficiant memory issues).
* Parquet file format
    * Data Science has largely settled on the [Parquet file format](https://parquet.apache.org/) for tabular data, which is columnar (meaning you can access it column-by-column, instead of reading line-by-line from the top).
* R Story
    * Most of the demos I show are based on Python. R does have its own Polars library (since it's just a wrapper of the Rust library), but it's not very user-friendly.
    * However, the DuckDB library for R is almost identical to the Python version, and is heavily used in the R world.
* Demos
    * I started off showing how to use `pandas`, `polars`, and `duckdb` to run the same query on the surveys.csv dataset that we use in the Data Carpentry workshop: [start_with_surveys.ipynb](start_with_surveys.ipynb)
    * Then I use the LAION Art dataset from HuggingFace to demonstrate working with the Parquet format: [Polars with laion.ipynb](Polars with laion.ipynb)