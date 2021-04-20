# Cleaning Data is (Not!) for the Birds!

Carpentries Brown Bag, January 27, 2021

### Title Slide

I wanted to talk today about a data cleaning task that one of my Global Genome Initiative colleagues and I recently undertook as part of a project that we’re currently working on. We had a really messy dataset that needed to be cleaned up, and we were able to accomplish this entirely with Excel and OpenRefine. So my goal with this talk is to explain the question we were trying to answer, the dataset we used, and the general approach we took to cleaning the data. Then, I just want to demo a couple of things in Excel and OpenRefine that folks might not be familiar with, but which can be really helpful.

Firstly, to give credit where credit is due, my GGI colleague Julia Steier was actually the one who did the hard work of cleaning this dataset. I was able to provide some helpful hints along the way, and I get the fun task of talking to you all about it today.

### Research Question

Julia and I are part of a team working on a paper that is still in its initial stages, so I won’t go into too much detail about it now. But one of the questions that we want to look at is how birds are distributed across the globe, and we wanted to produce a figure showing the number of bird families, genera, and species on each continent. It was suggested that one good resource for obtaining bird geographic distributions would be a source called the IOC World Bird List.

### IOC World Bird List

The International Ornithological Congress, or IOC, publishes a resource called the IOC World Bird List. This list is meant to be an authoritative source on the names and evolutionary classifications of all birds worldwide. This source also provides a geographic range for each species, which was the data that we were particularly interested in looking at. The range data consist of a broad geographical region, such as North America, South America, or Africa, and then additional qualifiers and details. Because different levels of detail are provided for different species, we chose to focus on the broad geographical region data.

I want to say right now that I think it’s really impressive what the IOC have managed to provide in this dataset. The data are updated twice a year, and there is a wealth of information for each of the ~34,000 species and subspecies in the list. This list is the product of a lot of effort and expertise, and I’m grateful that it was available to us for this project. However, as you will see on the next slide, the formatting of the original dataset was not ideal, and we had to do significant restructuring before we could use it for further analysis.

### Raw Data

Here is the raw Excel file provided on the IOC website. As you can see, these data violate many of the principles of tidy data that we cover in our Data Carpentry workshops. For example, the formatting of this file is crucial for conveying information – each species and subspecies record is dependent on the rows above it to provide necessary taxonomic information. In addition, individual cells contain multiple types of information – for example, cell G10 contains both the name of the subspecies, and the fact that this subspecies is extinct. Furthermore, other cells contain multiple values for the same field. For example, cell J5359 contains three distinct values for the broad geographic range of the species, separated by commas. Another thing is that the same data are spread out over multiple columns. For example, column J contains “breeding range” data while column L contains “non-breeding range” data, but both of these columns really contain different flavors of range data.

All of these structural elements of the file make it impossible for a computer to read the data and summarize it in a way that answers our research question.

### Dataset Improvement

Before Julia started the actual data cleaning process, we had to figure out the specific analytical tasks we actually wanted to do with these data, and then what the corresponding cleaning task would need to be in order to accomplish this. I won’t go through these in detail, but in general, we wanted the ability to easily group, summarize, and filter by the different fields in the dataset, similar to the kinds of tasks we do in the Data Carpentry workshops. One of the things I always try to stress when I'm talking about data wrangling is that it really helps to know the question you are trying to answer. If you know your question, then you can do only the tasks you need to do to answer that question specifically. It provides a nice laser-guided focus, and prevents you from doing unnecessary work.

### Cleaned Dataset

This the cleaned dataset that Julia produced. She made sure that each species record includes its full taxonomic lineage. She combined the breeding region and nonbreeding region columns into one column, region, and then added a second column indicating the region type. She split multi-value region cells into multiple records – the highlighted rows are all for the same species, and show the three ranges in which it occurs. At the end, we had a tidy dataset that we could use to accomplish our desired analytical tasks and answer our question, which will be forthcoming when we finish our project.

So that was pretty much an overview of our process. There were a lot of nuts and bolts and moving pieces, and there was a lot of work that went into figuring out specifically the geographic region values, but Julia did a really good job of keeping everything organized perfectly. I don't have time to walk through the entire cleaning process, but I did want to demonstrate a couple of useful tricks that we figured out in Excel and OpenRefine, to clean the taxonomic names and to deal with the multi-value region cells.

### Demo: Fill down blank values in Excel

1. Fill all intentionally blank cells with a dummy value, e.g. zzzBLANK
2. Select range of cells that need to be “filled down”
3. Select all blank cells in range: Home → Find & Select → Go To Special… → Blanks
4. In active cell, type **=`<up arrow key>`** to set the cell equal to the one above it
5. Use Ctrl + Enter (or Cmd + Enter) to fill every blank cell with a reference to the one above it
6. Paste Special to replace formulas with values
7. Use Home → Replace to replace dummy value with an empty string

For more details: https://www.ablebits.com/office-addins-blog/2014/05/02/fill-blanks-excel/

### Demo: Split multi-value cells into separate rows with OpenRefine

1. **Important! Show as: records** 
2. On the column containing the multi-value cells: Edit cells → Split multi-valued cells…
3. Optional: trim extra whitespace and convert to standard upper or lowercase
4. For each field that you would like to fill down: Edit cells → Fill down. **Important: save the first data column for last!**

For another method of handling this: https://kb.refinepro.com/2012/03/fill-down-right-and-secure-way.html