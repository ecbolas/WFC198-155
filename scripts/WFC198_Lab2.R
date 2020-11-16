#### Welcome to your second lab for WFC 198! ####
## Lab 2: Piping and data vizualization ##

# Today we will learn how to link up commands in the tidyverse by "piping"
# We will also explore the fundamentals of data visualization, both in base R and in ggplot,
#   which is in the tidyverse
# If you want to learn more about the tidyverse, check out https://www.tidyverse.org/

## Lab 2 OBJECTIVES ##
# 1. Learn how to link up tidyverse commands by 'piping'
# 2. Make new columns in a tibble dataset
# 3. Explore different visualization types in base R and ggplot
# 4. Understand how to use different types of color palettes for continuous and discrete data
# 5. Write your own code to create a ggplot data visualization

# We should already have the package 'tidyverse' installed from last week, so we just need to load it
library(tidyverse)

# Later, we'll also need this color package, so let's install it now
#install.packages("RColorBrewer",dependencies=T)

# Ok, let's get to piping!

#--------------#
#### PIPING ####

# What is piping? 
# Piping is the process of linking multiple operations (like 'filter','select' and 'arrange')
#   into a single command
# The great thing about piping is it makes it easier to make multiple changes or 
#   apply multiple functions to your data without having to overwrite your dataframe/tibble or
#   having to name a bunch of other objects.

# For example, let's use our penguin dataset again, with no NAs
library(palmerpenguins)
view(penguins)
filter(penguins, island == "Biscoe")

penguins <- drop_na(penguins)

# What if we want to filter by year == 2007 and select only the first three columns?
# Without piping, that would look like this:

penguins_2007 <- filter(penguins,year==2007)
penguins_select <- select(penguins_2007,1:3)

# Check your tibble!
penguins_select

# What if we could get this result without having to save 'penguins_2007' along the way?
# We can! With a pipe
# The 'pipe operator' is the magic link that ties your pipe together: %>% 
# You can use this operator to combine multiple functions into a pipe
# When piping, it's best practice to start with the original tibble, then assign
#   the name of the new tibble at the end with the "->" operator rather than put the name
#   at the beginning. That makes the command flow like a sentence: "Take the tibble 'penguins',
#     filter it by 'year', select columns 1 through 3, and name it 'penguins_select'."
# We start with our tibble, followed by the pipe operator:
penguins %>% 
  filter(year==2007) %>%    # Then we can filter it by year, followed by the pipe operator
  select(1:3) -> penguins_select     # And finally we select rows 1-3, and save the new tibble

# Did we get the same result? Compare the data values and dimensions (number of rows, columns)
penguins_select

# What was different about our functions in the pipe?
# We didn't have to include the name of the tibble in the functions
# That's because any function in the pipe defaults to be applied to the tibble you start with

# *Your turn!* Let's recall what we learned in our last lesson and apply it to writing a pipe.
# Below, write a pipe that selects the columns 'species', 'body_mass_g', and 'year', then
#   arrange it by 'body_mass_g' from largest to smallest.
# Name this new tibble: penguin_body_mass

penguin_body_mass <- penguins %>% 
  select(c(species, body_mass_g, year)) %>% 
  arrange(-body_mass_g)

# Let's look at your new tibble
penguin_body_mass

#** QUESTION 1: By looking at your tibble, find the record of the 5th largest penguin. 
#     What species is it? How much did it weigh? In which year was it measured? 

#-----------------------------------#
#### MAKING NEW VARIABLE COLUMNS ####

# We can also use pipes to add new columns to our dataset
# Why would we want to do that?
#   1. You have a vector of a variable that isn't already in your tibble (e.g. season or body length)
#   2. You want to make a calculation based on one or more columns in your tibble 
#       (e.g. body length - bill length)
#   3. You want a new variable based on a conditional statement
#       (e.g. if body mass is grater than 4000, write "large", otherwise write "small")
# Can you think of other reasons?

# The 'mutate' function is used to add a column to a tibble
# Sometimes body mass measurements are taken once an animal is already wearing a GPS tag
#   Let's say that the tags on the penguins weigh about 40 g
#   We may want to make a new column for body mass with the 40 g subtracted to get true mass
penguins %>% 
  mutate(body_mass_notag = body_mass_g - 40) -> penguins_2

# Is there a new column at the end?
penguins_2

# We can't see it! But, you might notice at the bottom that the tibble says we have 1 more
#   variable that isn't shown: body_mass_notag. 
# We can only view so many columns of a tibble unless we specifically call
#   more columns, or use our "view" function
view(penguins_2)

# Compare the body_mass_g and body_mass_notag columns. Is there a 40 g difference between them?

# You may remember in our first class that we made new columns using the '$' operator.
# For example, we could take our same command in 'mutate' to make a new column in base R
penguins_3 <- penguins # This makes a copy of the penguins tibble, named penguins_3
penguins_3$body_mass_notag <- (penguins_3$body_mass_g - 40) # Then we make a new column
view(penguins_3)

# As always, there are multiple ways to code things in R! But, we will primarily use pipes
#   for sequences of functions to reduce the number of local objects we need to make,
#   simplify our syntax, and make it easier to reproduce our results

# Using pipes, we can also add multiple new columns at once.
# Here we'll still add body_mass_notag, but we'll also create a column with a binary variable
#   for "large" and "small" penguins, seperated at 4000 g
# To do that, we just add a comma after our first new column and then start a second line
#   within the mutate function
# We will use an 'ifelse' function to make our new variable. 
#   The 'ifelse' function has three elements: the condition, the value if the condition is 
#   true, and the value if the condition is false. Each is separated by a comma.
# Below, our 'ifelse' statement reads: if body_mass_notag is greater than 4000, write "large"
#   in the new column 'body_mass_binary', otherwise write "small"
penguins %>% 
  mutate(body_mass_notag = body_mass_g - 40,
         body_mass_binary = ifelse(body_mass_notag > 4000, "large", "small")) -> penguins_4

# Does your new binary variable make sense with your body mass data?
view(penguins_4)

# *Your turn!* Make a pipe with the penguins tibble that:
# 1. filters by island Biscoe
# 2. selects columns 1, 2, 3, 4, 7, and 8
# 3. make a new column called bill_length_binary using the 'mutate' function, 
#     where bills over 45 mm are called "long" and bills under 45 mm are called "short" 
#       (HINT: use the 'ifelse' function)
# 4. name the final tibble 'my_penguin_tibble'

# We will use this new tibble to explore data visualization
names(penguins)
view(penguins)
str(penguins)

penguins %>% filter(year == "2007")

my_penguin_tibble <- penguins %>% 
  filter(island == "Biscoe") %>% 
  select(c(1:4, 7:8)) %>% 
  mutate(bill_length_binary = ifelse(bill_length_mm > 45, "long", "short"))

my_penguin_tibble

#--------------------------#
#### DATA VISUALIZATION ####

# We will primarily use 'ggplot' (in the tidyverse) to make vizualizations
# ggplot allows for easy customization of plots by adding individual commands (like pipes)
# However, unlike pipes, it links up commands with a '+' rather than the pipe operator '%>%'

# First, we need to get familiar with general ggplot syntax
#  "+" is your key to adding lines to your plot code!
# In ggplot we call the data first. That means that we use 'data =' followed by our tibble
#   or dataframe
# Then, we add the variables that will be plotted on the x and y axes using 'aes'
# Once we have the data, x, and y specified, we can assign a plot type, such a 
#   scatterplot (geom_point), bar plot (geom_bar), or boxplot (geom_boxplot) among others
# Let's start with a scatterplot!
ggplot(data = my_penguin_tibble, aes(x = bill_length_mm, y = bill_depth_mm)) + 
  geom_point()

# It looks like we might have a negative correlation in our data. What if we plot a 
#   trendline through our data?
# In case it's been a while since your last stats class - a trendline shows the overall
#   trend of a relationship between your x and y axes. How does y change as a function of x?
# (Remember, the x-axis is on the bottom and the y-axis is along the left)
# The x-axis plots the independent variable, which influences the y-axis (dependent variable)
# This means that we're interested in how the variable on the y-axis is influenced by 
#   the variable on x. For example, time is a common x-axis, because we're usually interested
#   in how something changes with time. If time was on the y-axis, it would mean that we 
#   could influence time! But we'll leave that to sci-fi...

# Let's see what the trend in our data is, using method = 'lm', 
#   which plots the best straight line through our data
# As mentioned above, we will link up elements of the plot with a '+'
ggplot(data = my_penguin_tibble, aes(x = bill_length_mm, y = bill_depth_mm)) + 
  geom_point() +
  geom_smooth(method = 'lm')

# The trendline shows a negative relationship - as bill length gets longer, bill depth
#   gets shorter. That seems weird!
# Maybe we are not getting the whole story here. What if we break the data down by
#   species of penguin?
# We can do this by making species different colors using the 'color' command
ggplot(data = my_penguin_tibble, aes(x = bill_length_mm, y = bill_depth_mm, color = species)) + 
  geom_point()

# Do we see a different pattern emerge?

# *Your turn!* Add a trendline to the above plot.
#** QUESTION 2: Describe the relationship between bill depth and bill length for each 
#   penguin species in your plot. Do these trends indicate a different relationship between
#   bill length and bill depth than our trend that used all the data together?

# As in lab 1, save the plot by clicking "Export" in the Plots quadrat of Rstudio
# You will need this image to insert into your lab write-up

# In addition to color, we can also distinguish a variable by size...
ggplot(data = my_penguin_tibble, aes(x = bill_length_mm, y = bill_depth_mm, size = species)) + 
  geom_point()
# ...or shape...
ggplot(data = my_penguin_tibble, aes(x = bill_length_mm, y = bill_depth_mm, shape = sex)) + 
  geom_point()
# ...or transparency (called 'alpha')....
ggplot(data = my_penguin_tibble, aes(x = bill_length_mm, y = bill_depth_mm, alpha = year)) + 
  geom_point()
# ...or multiple features (for multiple variables in your data)!
ggplot(data = my_penguin_tibble, aes(x = bill_length_mm, y = bill_depth_mm, color = species,
  shape = sex)) + 
  geom_point()

# What if we want to plot the two species seperately? We can split our plot into panels
# To do this, we can use a command called 'facet_wrap' two split the data into multiple 
#   panels based on a factor
ggplot(data = my_penguin_tibble,aes(x = bill_length_mm, y = bill_depth_mm)) + 
  geom_point() + 
  facet_wrap(~ species)
# In order to split your data even further, you can add more factors into the facet_wrap
#   line using a '+'
ggplot(data = my_penguin_tibble,aes(x = bill_length_mm, y = bill_depth_mm)) + 
  geom_point() + 
  facet_wrap(~ species + sex)

# *Your turn!* Let's bring our original 'penguins' tibble back in
# Use the same dependent variable (bill depth) and independent variable (bill length) to
#     make a figure with your 'penguins' dataset that:
#   1. shows different colors for males and females
#   2. shows different shapes for species
#   3. has different panels for each island

ggplot(data = penguins, aes(x = bill_length_mm, y = bill_depth_mm, color = sex, shape = species)) +
  geom_point() +
  facet_wrap(~island)

#** QUESTION 3: ####
# Based on looking at the figure you made, on Dream Island, is there a 
#   difference in the range of bill depths between Adelie and Chinstrap penguins? If so, 
#   which penguin tends to have greater bill depth? What about bill length? If so, which
#   penguin tends to have greater bill length?

# Export your plot for your lab write-up.

#--------------#
#### MOVING BEYOND SCATTERPLOTS: BOXPLOTS AND BAR PLOTS ####

# Two other kinds of plots will be useful to us in this course: boxplots and barplots
# Both boxplots and barplots are good for examining how data are distributed across factors.

# Boxplots use *raw data* to plot distributions of variables
#   A boxplot will display quartiles of your data, as well as the maximum and minimum values.
#   Quartiles divide your data into 4 equal parts. Therefore, boxplots display the median
#     of your variable as well as the 1st and 3rd quartiles. Outliers are sometimes
#     depicted above/below the maximum and minimum values as individual dots.
ggplot(data = penguins, aes(x = island, y = body_mass_g)) + 
  geom_boxplot()

# We can also add means and standard errors to our boxplots to see how they map onto 
#   the variable distributions
ggplot(data = penguins, aes(x = island, y = body_mass_g)) + 
  geom_boxplot()+
  stat_summary(fun.data = "mean_se")

# If we want to separate our data out further, we can use 'fill' to color by a factor
# NOTE: 'color' is used when we are applying color to a dot or line. 'fill' is used 
#   when we are applying color to an area (i.e. filling in a shape)
ggplot(data = penguins, aes(x = island, y = body_mass_g, fill = species)) + 
  geom_boxplot()

# Unlike boxplots, bar plots display summarized data. 
#   So, if we are interested in comparing summary statistics across factors, we use bar plots
#   In order to make a bar plot, we need to create some a summary tibble.
#   Here we'll calculate the mean and standard deviation of body mass for each species
#     (we use 'group_by()' to calculate different values by species)
penguins %>%
  group_by(species) %>% 
  summarize(mean_body_mass = mean(body_mass_g),
            sd_body_mass = sd(body_mass_g)) -> penguin_mass_summary

# Now that we have our summary data, we can use 'geom_bar' to plot our means.
# As above, we'll use 'fill' to differentite the species by color
# We can also add error bars using geom_errorbar to show one standard deviation above and
#   below each mean
# We need to add the specification stat = "identity" so that the bar plot shows the value
#   of our variable of interest
ggplot(data = penguin_mass_summary,aes(x = species, y = mean_body_mass, fill = species)) + 
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = mean_body_mass - sd_body_mass, ymax = mean_body_mass + sd_body_mass),
                width = 0.2)

# We can see that Gentoo penguins seem to have greater body mass than the other species

# Let's take our barplots to the next level! We can group by multiple factors to look deeper
#   at differences among groups in our data
# Here we'll group by both species and sex, and look at differences in body mass across both
#   factors
penguins %>%
  group_by(sex,species) %>% 
  summarize(mean_body_mass = mean(body_mass_g),
            sd_body_mass = sd(body_mass_g)) -> penguin_mass_sex

# We'll add position = "dodge" so that the bars show up next to each other
ggplot(data = penguin_mass_sex,aes(x = species, y = mean_body_mass, fill = sex)) + 
  geom_bar(stat = "identity", position = "dodge") +
  geom_errorbar(aes(ymin = mean_body_mass - sd_body_mass, ymax = mean_body_mass + sd_body_mass),
                position = "dodge")

#** QUESTION 4: Which species seems to have the least sexual dimorphism (differences
#   between males and females) in body mass?

#--------------#
#### USING COLOR IN DATA VISUALIZATION ####

# Color palettes are series of colors that are used in data visualizations or plots
# For example, the color palette for our last plot included coral, green, and blue
# Choosing a color palette can be really important in communicating your data because
#   some kinds of palettes are better suited to show specific data types.
# As such, palettes can be one of three types:
#   1. sequential: gradients that indicate high-to-low variables (e.g. temperature)
#   2. diverging: gradients that diverge from a middle neutral point (e.g. temperature anomaly)
#   3. qualitative: unrelated colors for nominal or categorical data (e.g. dog breed)

# Let's try some palettes!
library(RColorBrewer)
display.brewer.all()
# Look in the plot quadrant of Rstudio - you should see a bunch of color palettes
#   that are available in RColorBrewer
# The palettes in the top group are sequential, the middle group are qualitative, and
#   the bottom group are diverging.
# Note the names of the colors along the left. We'll be using these names in the following
#   exercises. You can always use the display.brewer.all() command again if you need a 
#   reminder about the color palette names.

# First, let's plot categorical/qualitative data
#  For these kind of data, we want to use colors that are unrelated
#  To start, we can look at how the relationship between body mass and flipper length 
#     vary by species:
ggplot(data = penguins, aes(x = body_mass_g, y = flipper_length_mm, color = species)) + 
  geom_point() +
  scale_color_brewer(palette = "Accent")

# You can see that it's very clear that the colors represent different species
# What if you used a sequential color palette for the same data?
ggplot(data = penguins, aes(x = body_mass_g, y = flipper_length_mm, color = species)) + 
  geom_point() +
  scale_color_brewer(palette = "OrRd")

# Sure, we can see the colors for the different species, but the color scheme implies that
#   the species represent a gradient of some kind. That's not what we intended to show.

# However, sequential color schemes are great for showing continuous data
# Let's see how bill length predicts flipper length:
#   (Note that the way we assign colors is a little different for continuous data. Instead
#    of using scale_color_brewer, we use scale_color_gradientn and we have to assign how
#    many breaks there are in the continuous color scheme.)
ggplot(data = penguins) + 
  geom_point(aes(x = bill_length_mm, y = flipper_length_mm, color = body_mass_g)) +
  scale_color_gradientn(colors = brewer.pal(n = 8, name = "OrRd"))

# First, what is the relationship between bill length and flipper length?
#   -> It looks like flipper length increases as bill length increases
# We have added a continuous color for body mass. What do the colors tell us?
#   -> Generally, animals with greater body mass have longer flipper and bill lengths

# Sequential color schemes are great when we are looking at a continuous variable that 
#   increases from a common point (often 0).
# When we are dealing with data that splits from a common point, we prefer to use diverging
#   color palettes.
# For example, let's make a new column that is the difference between body mass and the 
#   mean body mass across the whole dataset. As before, we'll use 'mutate' to make a column
penguins %>% 
  mutate(body_mass_diftomean = mean(body_mass_g)-body_mass_g) -> penguins_4

# Now, we can plot the same data as before, but with a diverging color palette
#   We'll use our new tibble and will color by our new column 
ggplot(data = penguins_4) + 
  geom_point(aes(x = bill_length_mm, y = flipper_length_mm, color = body_mass_diftomean)) +
    scale_color_gradientn(colors = brewer.pal(n = 8, name = "RdBu"),limits = c(-2100,2100))

# How is the message different with the diverging color palette?
# -> We can see that animals above an average body mass generally have greater bill
#     and flipper lengths than those with lower than average body mass.

# *Your turn!* 
# Make a new tibble that has only Adelie pengiuns
# Make two scatterplots with this new tibble, both of which have body mass on the x-axis and 
#   bill depth on the y-axis:
#   1. Color by island
#   2. Color by bill depth
# For both figures, specify an appropriate color palette from RColorBrewer. Please use
#    palettes that we haven't used in this lesson (find the names using display.brewer.all())

# The palettes in the top group are sequential, the middle group are qualitative, and
#   the bottom group are diverging.

adelie_tib<- penguins %>% filter(species == "Adelie")
names(adelie_tib)
display.brewer.all()

# use a color pallete that is qualitative (middle group) bc island is factor/categorical data
ggplot(data = adelie_tib, aes(x = body_mass_g, y = bill_depth_mm, color = island)) +
  geom_point() +
  scale_color_brewer(palette = "Dark2")

# use a color pallete that is sequential (top group) bc bill_depth is continuous
ggplot(data = adelie_tib, aes(x = body_mass_g, y = bill_depth_mm, color = bill_depth_mm)) +
  geom_point() +
  scale_color_gradientn(colors = brewer.pal(n = 6, name = "PuBuGn"))

####** QUESTION 5: ####
#Describe what the colors tell you about the relationship between body mass
#   and bill depth for each of your two plots.
# Export your plots for your lab write-up.

#--------------#
#### QUESTIONS FROM LECTURE AND READINGS ####

#** QUESTION 6: How can the scale of the sampling of available points affect the results 
#               of a habitat selection analysis?

#** QUESTION 7: According to the marginal value theorem, when should an animal leave a 
#               foraging patch?

#--------------#
#### CONGRATS! ####
# You've learned how to pipe and plot in R
# Please reach out to your TA, Ellie Bolas (ebolas@ucdavis.edu) for questions about this lab