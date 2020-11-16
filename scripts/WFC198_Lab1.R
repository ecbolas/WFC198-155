#### Welcome to your first lab for WFC 198! ####
## Lab 1: Introduction to R language, RStudio, and data manipulation ##

# Today we'll be going through some of the fundamentals of programming in R
# We will do some basic commands and learn about syntax and data types

## Lab 1 OBJECTIVES ##
# 1. Use fundamental symbols in R, including <-, [], c(), ==, !=, and $
# 2. Understand the difference between vectors, dataframes, and tibbles
# 3. Check the class and structure of your data, and check the distribution of your variables
# 4. Use tidyverse data manipulation commands: arrange, filter, and select
# 5. Extract statistics from data using 'summarize'


# A brief introduction to RStudio:
# RStudio has 4 panels. Clockwise from this box, you have the source panel, workplace
#   browser, plots, and console.
# The source panel (this one) is where you draft your code
# The console (below this one) is where you run your code
# The workplace environment (to the right) keeps track of your saved objects 
# The plot panel (bottom right) shows your plots, and also can be used to look for packages
#   and access R help
# Packages are pre-written code to make it easier to program without having to write 
#   everything yourself! We'll start using some packages today.
#   We will use packages by installing them (using 'install.packages') and loading them
#   (using 'library')
# Because you are using RStudio, you can navigate through the sections of the lab by
#   clicking on "Welcome to your first lab for WFC 198" at the bottom of the source box and 
#   selecting the section you want to jump to.

# Let's get started!

#-------------------------#
#### FUNDAMENTAL SYNTAX ####

# As you may have noticed, the 'hashtag' or number symbol is what we use to write comments
# If a hashtag is in front of a line of code, it will not run

# R can function directly as a calculator. 
# Try running the next line by placing your cursor anywhere on the line and pressing 
#   command-return (if you have a mac) or control-enter (if you have a pc)
2 + 3

# An arrow is used to name objects. Run the code below in the console
my_object <- 2 + 4

# To see what is in your named object, you can call it by typing it into to console
my_object

# In the above case, your object is simply a single value.
# But objects can take many forms! Some common ones that we will use are vectors and dataframes
# A vector is a string of numbers. You can make a vector by using the c() function to combine numbers into a vector
c(1,3,6)

# Notice that any time we open parentheses, we have to close them!

# *Your turn!* Name a vector "my_vector" with the values 2, 5, and 9. We'll look back 
#   at this vector later.

# A dataframe organizes data into columns. Each row represents a single data observation
# We can make our own dataframe by naming the columns and entering the data as vectors
my_dataframe <- data.frame("columnA" = c(1,3,5), "letters" = c("A","B","A"))
my_dataframe

# Note that we had to put the letters in quotes. 
# R can't understand words or letters (i.e. "characters") without quotes.
# Try running each of the next two lines of code. Which one gives you an error message?
Hello world
"Hello world"

# Another important symbol is $. The $ symbol can be used to isolate a column of a dataframe
my_dataframe$columnA

# Let's use the $ symbol to make a new column in our dataframe that doubles the values in column.A
my_dataframe$newcolumn <- my_dataframe$columnA * 2
my_dataframe

# Another way to isolate a column, row, or cell is to use brackets. 
# dataframes take the form of [rows,columns]
my_dataframe[1,]
my_dataframe[1,2]
my_dataframe[,c(1,3)] # we can use our c() function to isolate just columns 1 and 3
my_dataframe[,2:3] # or we can use the ":" to pull out all the values from column 2 to 3

# *Your turn!* Name the 2nd and 3rd rows of the dataframe as my_dataframe_2. We will use
#   this object in a moment to look at the dataframe structure

my_dataframe_2 <- my_dataframe[2:3,]
my_dataframe_2
# We can check out the class and structure of our objects by using the class and str functions
class(my_object)
str(my_object)
class(my_vector)
str(my_vector)

# Look at the structure and class of your dataframe. How are the columns different?
class(my_dataframe_2)
str(my_dataframe_2)

# Some final syntax tricks!
# "==" means "is equal to" and "!=" means "is not equal to"
# We will come back to these commands later when we are working on data manipulation
# For now, let's just ask if our value my_object is equal to a specific number
# Which command says that it is false?
my_object != 4
my_object == 4
my_object == 5

#----------------------#
#### DATA STRUCTURE ####

#install.packages("palmerpenguins")
library(palmerpenguins)
library(tidyverse)

# We will use the penguins dataset from package "palmerpenguins" to practice exploring data
# Let's first see what class our data are
class(penguins)

# What on earth is a "tbl"??
# "tbl" stands for tibble, which is a modern dataframe with more functionality, 
#     especially for large data sets. 
# tibbles are also really easy to manupulate!
# tibbles are the building block of the "tidyverse", a modern syntax in R
# We will mostly be coding using tidyverse syntax in this class
# To fully work with tibbles, we need to install the tidyverse package

#install.packages("tidyverse", dependencies = TRUE)
library(tidyverse)
# Loading library "tidyverse" will load the core packages in the tidyverse
# Some of these packages are:
#   readr: the package that imports data into tibbles (enhanced dataframes)
#     key commands: read_csv
#       We will use this one in a few lessons.
#   tibble: creates tibbles from dataframes
#     key commands: tibble
#       Our data from today are already in a tibble, so we don't need this right now.
#       However, you can use it to transform a dataframe to a tibble
#   dplyr: assists in data manipulation
#     key commands: mutate, filter, summarise, arrange, select
#       We will focus on this one today.
#   ggplot2: the data vizualization package
#     key commands: ggplot
#       Next week we will dive into ggplot.


# Because some of the data observations are not complete, we can use "drop_na" to get
#   rid of the rows that don't have data in every column
penguins <- drop_na(penguins)

# We can see what format our columns are in using the str command
str(penguins)

# Note that the columns for species, island, and sex are all considered "factors" 
#   because they are categorical variables.

# What else might we want to know about our data before we analyze it? 

# One important feature of a dataset is the sample size. We can see the sample size 
#   using nrow...
nrow(penguins)

# ... or by simply viewing the tibble and looking at the dimentions at the top
# (That's a special thing about tibbles that traditional dataframes don't have!)
penguins

# What about how many variables we have? We can approach this question in the same way
ncol(penguins)

# Another trick you can use if you need to reference the full dataset repeatedly is 
#   the "view" function
# view will open a new file with your data in it that you can easily scroll through
view(penguins)

# We also may be interested in the distribution of partiular variables 
# It is always a good idea to look at your data and make sure it is formatted correctly 
#     before proceeding with analyses!
# We can learn about the spread of our data both numerically and graphically
# For starters, we can use the "summary" command to get some summary statistics about 
#   a particular variable
summary(penguins$flipper_length_mm)

# The summary gives us a sense of the data distribution, but we can also look at it
#   with a histogram
# Histograms show us how many occurrences there are of each value
# For example, you can see in the histogram of flipper length that about 30 penguins
#   have a flipper length of 180-185 mm
hist(penguins$flipper_length_mm)


#-------------------------#
#### MANIPULATING DATA ####

# Oftentimes our dataset has more data than we need for a particular analysis
# We may want to get rid of specific columns or rows, or order the data in a specific way
# The tidyverse provides some easy functions to help us clean up our data so it can 
#   be most useful to us!
# That means it's time to go through some data manupulation functions

# ARRANGE #

# What if we want to sort our data by a variable?
# In this case, we'll sort our data by increasing bill depth
arrange(penguins, bill_depth_mm)

# Or, we can use a "-" to sort in decreasing order
arrange(penguins,-bill_depth_mm)

# We can also sort by multiple variables
arrange(penguins,-year,bill_depth_mm)


# SELECT #

# What if we only want to see certain columns from the tibble?
# We can use "select" to get rid of extraneous columns
# In this case, we'll only keep species, island, and body mass
select(penguins,c(species, island, body_mass_g))

# Or, we can exlude some columns specifically.
# In this case, we'll get rid of sex and year by using a "-" before the column name vector
select(penguins,-c(sex, year))

# We can also rename columns within the "select" function. Here we are renaming body_mass_g
#   to bodymass
select(penguins,c(species, island), bodymass = body_mass_g)

# If you'd rather rename a column without selecting columns, you can use "rename"
rename(penguins, bodymass = body_mass_g)

# In R, there's often not only one way to do things! 
# When we select columns, we can also do so with the column numbers rather than names
select(penguins,c(1,2,4:6))
# Can you recall how we selected columns with brackets earlier? We can do the same thing
#   with the penguins dataset.
penguins[,c(1,2,4:6)]
# Note the difference between the use of brackets and parentheses:
#   Brackets help you isolate a column, row, or cell in a dataframe
#   Parentheses simply allow you to execute any function. In this case the function is to 
#     select specific columns
# The brackets are what we call "base R" syntax, whereas 'select' is in "tidyverse" syntax
# You can select certain columns either way! But, it's best practice to keep base R syntax
#   with traditional dataframes and tidyverse syntax for tibbles
# So, since our penguins dataset is a tibble, 'select' is the preferred method 


# FILTER #

# What if we want to only look at data from a specific species, individual, site, or year?
# We can use "filter" to only include specific data that we want
# In this case, we only want to look at Gentoo penguins
filter(penguins, species=="Gentoo")

# With any of these commands, we can save our manipulated data as a new tibble that we can
#   work with later:
gentoo_only <- filter(penguins, species=="Gentoo")

# *Your turn!* Filter the dataset by a specific island, sex, or year and save it as a new
#     tibble. 
# Hint: you will need to change both the column name and the specific character string that 
#     you are filtering by
# (Remember, a character string just means plain text that does not call an object or function!
#     In the above line of code, it is "Gentoo")
# You may also want to change the assigned name of the tibble, since "gentoo_only" will
#   no longer represent the data in your new filtered tibble
biscoe_only <- filter(penguins, island=="Biscoe")
dream <- filter(penguins, island == "Dream")
tr<- filter(penguins, island == "Torgersen")
male <-filter(penguins, sex == "male")
female <- filter(penguins, sex == "female")

#** QUESTION 1: Create a histogram of flipper length for the new dataset and paste it into 
#   your assingment. Based on what you can see just by looking at the historgram,
#     about how many individuals had 210-215mm long flippers? Estimate from the figure.

hist(biscoe_only$flipper_length_mm)
hist(dream$flipper_length_mm)
hist(tr$flipper_length_mm)
hist(male$flipper_length_mm)
hist(biscoe_only$flipper_length_mm)
hist(female$flipper_length_mm)
hist(penguins$flipper_length_mm)

# Save the histogram by clicking "Export" --> "Save as image" in the Plots quadrat of Rstudio
# You will need this image to insert into your lab write-up

#------------------------#
#### SUMMARIZING DATA ####

# Now that we have a pretty good handle on the structure of our data, we can start
#     asking questions about the data itself

# One really easy way to summarize data is by using the "table" function
# table allows us to count the number of unique values in a specific column
table(penguins$species)

# A very cool thing about table is that you can use it to look at multiple variables!
table(penguins$species,penguins$year)

# *Your turn!* Use the table function to figure out how many observations of each penguin
#     species we have per island

table(penguins$species, penguins$island)
filter(penguins, island == "Dream") %>% select(penguins, species == "Adelie")
table(penguins$body_mass_g)

#** QUESTION 2: Using the table function, how many penguin species were found 
#     on more than one island?
table(penguins$species, penguins$island)

# table is a great tool, but it is limited to counting the frequency of occurrences
# We may want to extract other kinds of information from our data!
# To do that, we can use command "summarize"

# SUMMARIZE
# What if we want to know summary information about our data?
# There are a number of built in summary commands we can use, like mean, sd (for standard
#   deviation), max, min, or n (for frequency)
# Let's start by taking the mean of bill depths across our whole dataset
#   We can name the resulting variable "mean_bill_depth" so we remember what the 
#   value represents
summarize(penguins, mean_bill_depth = mean(bill_depth_mm))

# We can also use summarize to look at summary info by a factor
# Remember, a factor is a categorical variable in your dataframe
# To do this, we have to group our data by a factor
# Here, we are grouping our data by species
summarize(group_by(penguins, species), mean_bill_depth = mean(bill_depth_mm))

# We can make a new tibble with multiple summary columns if we want to save our summary info
penguin_year_summary <- summarize(group_by(penguins,year), 
          count = n(),
          mean_bill_depth = mean(bill_depth_mm),
          sd_bill_depth = sd(bill_depth_mm),
          max_bill_depth = max(bill_depth_mm),
          min_bill_depth = min(bill_depth_mm))
penguin_year_summary
#base r
penguins[,2:3]
#tidyverse
select(penguins, island, bill_length_mm)

# *Your turn!* Summarize our penguin dataset, grouped by island, and calculate the mean and 
#   standard deviation of body mass

penguin_island_summary<- summarize(group_by(penguins, island),
                                   count = n(),
                                  mean_body_mass = mean(body_mass_g),
                                   sd_bodymass = sd(body_mass_g))
penguin_island_summary
#** QUESTION 3: On which island is penguin body mass the largest on average? What about 
#   standard deviation? What is the mean and standard deviation of body mass on Dream Island?

#--------------#
#### QUESTIONS FROM LECTURE AND READINGS ####

#** QUESTION 4: What kind of home range estimator is best for capturing migration paths? Why?

#** QUESTION 5: If you wanted to understand how a red fox selected habitat in its home range,
#   which of Johnson's orders of selection would you be evaluating? Over what temporal scale
#   would you likely evaluate this pattern?

#--------------#
#### CONGRATS! ####
# You've learned how to manipulate data in R
# Please reach out to your TA, Ellie Bolas (ebolas@ucdavis.edu) for questions about this lab