# Reads in a very specific schedule excel spreadsheet and makes ical reservations from the reservations
# Assumptions about the scheduling excel spreadsheet:
# - First line has headers
# - There is a column titled "Display" with text about the reservation location. Only rows with text in the Display column will have ical events created.
# - There is a column for each date. The title of these columns is the date in Excel format (e.g. 44243 for Feb 16 2021) 

#install.packages(c("readxl","tidyverse", "uuid"))
library(tidyverse)
library(readxl)
library(uuid)


ical_event <- function(start, end, summary, location) {
  # This function is slightly modified from: https://stackoverflow.com/a/48281369
  # It returns the text for a ical event given start date, end date, text for a summary line and text for location 
  # This is intended for full-day events, there is no time associated with the start/end
  
  sprintf(
    "BEGIN:VEVENT
UID:%s
DTSTAMP:%s
X-MICROSOFT-CDO-BUSYSTATUS:FREE
DTSTART;VALUE=DATE:%s
DTEND;VALUE=DATE:%s
SUMMARY:%s
LOCATION:%s
END:VEVENT
", uuid::UUIDgenerate(),
    format(Sys.time(), "%Y%m%dT%H%M%SZ", tz="GMT"), 
    format(start, "%Y%m%d"), 
    format(end, "%Y%m%d"), 
    summary,
    location
  )
  
}


create_all_events <- function(df, outfile, facility){
  # Loops through each column in the df.
  # Column names that are 5 digits are the dates (in Excel date format)
  # Uses mutate() to call ical_event() to create an ical event for each row with a value in the "Display" column (those are the ones we care about)

  for (df_col in colnames(df)){
    if (grepl("^[[:digit:]]{5}$", df_col)){
      start_date <- as.Date(as.numeric(df_col), origin="1899-12-30")
      # Use mutate() to call ical_event() to create an ical event for each row with a value in the "Display" column (those are the ones we care about)
      # Note, if df_col is used in the select() wihtout all_of(), there's this warning: "Using an external vector in selections is ambiguous", with the suggestion to use `all_of(df_col`
      # .data[[df_col]] is used to get the value of the column name which is defined by df_col.
      sched_sub <- df %>%
                   select(all_of(df_col), Display) %>%
                   drop_na() %>%
                   mutate(ics = ical_event(start_date, start_date + 1, paste("(", facility, ") ", .data[[df_col]], sep = ""), paste("(", facility,") ", Display, sep = "") )) %>%
                   select(ics)
      # This is for showing what the two paste sections of the above mutate do:
      # sched_sub_test <- df %>%
      #   select(all_of(df_col), Display) %>%
      #   drop_na() %>%
      #   mutate(summary = paste("(", facility, ") ", .data[[df_col]], sep = "")) %>%
      #   mutate(location = paste("(", facility,") ", Display, sep = "") )
      
      # Write the results to the output file
      write.table (sched_sub, file = outfile, append = TRUE, quote = FALSE, col.names = FALSE, row.names = FALSE)
    }
  }
  
}


# Set input, output files
input <- "Scheduling_calendar_demo.xlsx"
output <- "sched.ics"

# Create ical file with headers
write("BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//rstats//NONSGML v1.0//EN
", file = output)

# Read in Excel Sheet
facility = "Building_1"
schedule <- read_excel(input, sheet=facility, col_names = TRUE)
# Process entries with create_all_events()
create_all_events (schedule, output, facility)

# Repeat for second Excel Sheet
facility = "Building_2"
schedule <- read_excel(input, sheet=facility, col_names = TRUE)
create_all_events (schedule, output, facility)

write("END:VCALENDAR", file = output, append = TRUE)

