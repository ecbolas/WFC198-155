#### Welcome to your sixth lab for WFC 198! ####
## Lab 6: Habitat selection ##

# Today we will learn about how to estimate habitat selection from animal location and
#   habitat class data

# NOTE on the data we will be using today (accessed from MoveBank, an open source animal movement repository):
# Study License Information valid at 2020-11-13 20:45:45 Name: Site fidelity in cougars and coyotes, Utah/Idaho USA (data from Mahoney et al. 2016) 
# Citation: Mahoney PJ, Young JK (2016) Uncovering behavioural states from animal activity and site fidelity patterns. Methods in Ecology and Evolution 8(2): 174–183. doi:10.1111/2041-210X.12658 
# Acknowledgements: We would like to thank M. Ebinger and M. Jaeger for access to the Idaho coyote dataset (all animal IDs beginning with 'IdCoy_'). 
# Grants Used: Utah Division of Wildlife Resources and USDA-WS-NWRC Predator Research Center License Type: Custom License Terms: These data have been published by the Movebank Data Repository with DOI 10.5441/001/1.7d8301h2. 
# Principal Investigator Name: Julie Young, PhD

## Lab 6 OBJECTIVES ##
# 1. Create a dataset of used and available locations within an animal home range
# 2. Extract habitat class data at used and available locations, and calculate selection ratios
# 3. Interpret data from selection ratio plots to make inferences about animal habtiat selecion

# Load in your packages. No new ones today!
library(tidyverse)
library(raster)
library(sf)
library(sp)
library(adehabitatHR)
library(ggplot2)
library(lattice)
library(rasterVis)


# Like usual, make sure you set your working directory to the folder where you 
#   downloaded the files for lab this week
#setwd("/Users/justinesmith/WFC198/WFC198_labs")
rm(list=ls())
setwd("...")
#-----------------------------------#
#### LOADING THE DATA ####

# First, we can load in our environmental layer
# Today, we have one raster layer: the National Land Cover Database (NLCD)
#   The NLCD is a national database of habitat classes with a 30 meter resolution
#   (meaning each raster cell, or pixel, is 30 m x 30 m)
utah_NLCD <- raster("data/utah_NLCD.tif")

# First, we need to know the crs of our raster. Looks like it's in UTMs, Zone 12
crs(utah_NLCD)

# Now let's look at the layer
plot(utah_NLCD)

# Not very satisfying! What are all these numbers? What do they mean?
#   Each number corresponds with a habitat class, but we can't tell what those are from
#   this plot
# In order to see the habitat classes, we need to do a little more processing
# Our habitat class layer (NLCD) is "ratified" which means it has categorical data instead
#   of continuous data
# We can see the categories by using levels()
levels(utah_NLCD)

# I've saved these levels in a file that we can use to add habitat class names to our plot
# All we need to do is load in the landcoverkey csv file and assign the colors associated
#   with each class to col.regions in our raster plotting command: levelplot()
landcoverkey <- read_csv("data/landcoverkey.csv")
landcoverkey
levelplot(utah_NLCD, col.regions=c(landcoverkey$colortable))

# Our movement dataset is a subset of carnivores from a larger study in Utah
#   These data are open source, which means they are freely available to download online
#   If you are interested in checking out some cool, open source animal movement datasets,
#   visit movebank.org

# Now we can load in our movement data.
#   We haven't loaded in data from a pipe before, but it can be a great way to bring in 
#   spatial data as a spatial object with the crs and coordinates specified
# To do this, we'll start with read_csv(), followed by our command to make our data an 
#   "sf" spatial object with the coordinates and crs specified
# We'll use the same crs as our raster so they can be plotted on top of each other
# You might notice that our crs is the same as with the wolf dataset! We are quite a bit 
#   further south today, but our Utah carnivores are in the same UTM zone as the Alberta wolves
read_csv("data/Utah_carnivores.csv") %>% 
  st_as_sf(coords = c("UTMeasting","UTMnorthing"), 
           crs = "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs") -> utah_carnivores_sf

# As always, we'll check out our data
# If we color by individual and change the shape by species we can see how many individuals
#   of each species are in our dataset.
# How many cougars do we have? How many coyotes?
ggplot() + 
  geom_sf(data = utah_carnivores_sf, aes(color = individual, shape = species))

# Like last week, we sometimes need an "sp" object (e.g for calculating home ranges)
#   So let's also store an sp version of our data
utah_carnivores_sp <- as_Spatial(utah_carnivores_sf)

# With our sp object, we can add a "layer()" function to our levelplot to see the animal
#   movement data on the habitat classes
levelplot(utah_NLCD, col.regions=c(landcoverkey$colortable)) +
  layer(sp.points(utah_carnivores_sp))

####** QUESTION 1:#### 
#Which habitat type is most abundant across our entire NLCD layer? Which 
#     habitats seem most abundant in the area that we have carnivore movement data? What
#     might this tell us about carnivore habitat selection at Johnson's 2nd order of selection?

#-----------------------------------#
#### CREATING A DATASET OF USED AND AVAILABLE POINTS ####

# See if you can remember way back to our habitat selection lectures! What data do we need
#   for habitat selection analyses at the home range (Johnson's 3rd order) level?
#     For an RSPF: Used and unused locations
#     For a selection ratio (SR) or RSF: Used and available locations
# What kind of habitat data do we use for different kinds of habitat selection analyses?
#     For RSF or RSPF: multiple habitat variables, can be categorical (e.g. habitat class)
#         or continuous (e.g. elevation, slope, NDVI)
#     For SR: categorical/discrete habitat classes only
# Today, we'll be calculating SRs for individual animals within their home ranges
# That means, we need to calculate proportions of "available" habitat inside each home range
# So to start, we need to calculate individual home ranges

# Your turn!
# Make 95% KUDs for all our individuals in a single home range layer (see how we calculated
#     allwolves_kud in Lab 5) using the utah_carnivores_sp object
# Note that this time our column for "individual" is column 2 in this dataset, not column 1
#   Make sure to specify h = "href"
# Name the final 95% KUD object "carnivores_kud_95"
# (if you get some error messages about the proj4string, don't worry about it)

carnivores_kud <- kernelUD(utah_carnivores_sp[2], h = "href")
carnivores_kud_95 <- getverticeshr(carnivores_kud, percent = 95)

# Let's check out your home ranges by plotting the home ranges first (with 40% tranparency,
#   specified as alpha = 0.4), and the plotting our movement data on top with the same 
#   categorical distinctions for color and shape
ggplot() + 
  geom_sf(data = st_as_sf(carnivores_kud_95), aes(fill = id), alpha = 0.4) +
  geom_sf(data = utah_carnivores_sf, aes(color = individual, shape = species))

# Now we get to sample available habitat within the home range
# We'll do this analysis by choosing just one of our animals to focus on: the coyote (C028)
# For simplicity, we can make an sf object of the coyote alone by re-loading in our dataset
#   In this pipe, we do the following:
#   1. filter by individual - this sf object will only have locations from C028
#   2. select the columns we want to keep. We need our coordinates (UTMs) for sure. I've also
#       saved "daynight" so we can look at habitat selection between day and night later
#   3. add a column specifying that these locations are "used". This will help when we combine
#       these data with our "available" points later
#   4. make the data an sf object with coordinates and a crs (like above)
# (How awesome are pipes?!)
read_csv("data/Utah_carnivores.csv") %>% 
  filter(individual == "C028") %>% 
  dplyr::select(UTMeasting, UTMnorthing, daynight) %>% 
  mutate(Used = "used") %>% 
  st_as_sf(coords = c("UTMeasting","UTMnorthing"), 
           crs = "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs")-> coyote_used

# You know the drill! Check out your data
coyote_used
ggplot(st_geometry(coyote_used)) + 
  geom_sf()

# Hmm, there seems to be a bit of a hole in the middle of the home range! May reflect avoidance
#   of a particular habitat type

# We will sample the same number of available points as we have used points. Therefore, we
#   need to save how many used points we have. We can do that with nrow(), which returns the
#   number of rows, or number of observations, in our dataset
coyote_n <- nrow(coyote_used)
coyote_n

# We also need to isolate only the coyote's home range. Check your home range object to see
#   which layer is storing the coyote's home range
carnivores_kud_95

# Looks like the first one! So, we can pull out the coyote HR with [1,] and save it as an 
#   sf object using st_as_sf()
coyote_95_HR <- st_as_sf(carnivores_kud_95)[1,]

# Do the location data map onto the coyote home range?
ggplot() + 
  geom_sf(data = coyote_95_HR, alpha = 0.4) +
  geom_sf(data = coyote_used)

# Finally, we're ready to sample available locations from the home range.
# First, we set the seed so we can reproduce our results - and so your results match mine
#   (otherwise the random sampling will produce a different sample every time)

set.seed(53)

# Then we use st_sample() to sample randomly within the coyote HR. size is the number of points
#   we're sampling, so we enter in our saved number of coyote location observations 
# Next, we add st_sf() to save the sf coordinates of the sampled points
# Finally, we need to add columns that match our coyote location dataset.
#   Remember that we have a "daynight" and a "Used" column in our coyote location data, so we 
#   need those in our available data too
# The Used column is obvious. If our location data are "used", these data are "available"
# The daynight column is trickier - how do we assign random locations to be in day or night?
#   To randomly assign each point as day or night, we can use rbinom, which randomly samples
#   from a binomial distribution (i.e. 0 or 1), with a 0.5 probability of either option - 
#   like a coin flip!
# Lastly, we save our available data as coyote_available
st_sample(coyote_95_HR, size = coyote_n) %>% 
  st_sf(geometry = .) %>%
  mutate(daynight = rbinom(coyote_n,c(0,1),prob = 0.5),
         Used = "available") -> coyote_available

# You can see that our available data is saved as an sf object
class(coyote_available)

# To make one dataset with both used and available locations, we use our trusty rbind()
#   function to combine them. Remember, rbind only works if the column names of both
#   datasets are identical
coyote_used_available <- rbind(coyote_available,coyote_used) 

# Let's check out the spatial distribution of our available points
# You can see how much more equal coverage we get within the home range with the available points
ggplot() + 
  geom_sf(data = coyote_used_available, aes(color = Used), alpha = 0.4)

# In order to plot our new data on our NLCD raster, we can transform our original used and
#   available datasets to sp objects
coyote_available_sp <- as(coyote_available, "Spatial")
coyote_used_sp <- as(coyote_used, "Spatial")

# We can crop our raster to the extent of our data so it's more zoomed in and we can see it
#   better. Then, we can add layers of the available and used data to see how they map
#   onto the habitat classes. First, we can just look at the used locations:
levelplot(crop(utah_NLCD,extent(coyote_available)), col.regions=c(landcoverkey$colortable)) +
  layer(sp.points(coyote_used_sp,col = alpha("black",0.3),pch = 20))

# Your turn!
#   Make a similar plot to the one above but with available locations (color "yellow")
levelplot(crop(utah_NLCD,extent(coyote_available)), col.regions=c(landcoverkey$colortable)) +
  layer(sp.points(coyote_available_sp,col = alpha("yellow",0.3),pch = 20))


####** QUESTION 2:#### 
#Name one habitat type that you think has more available points than used,
#     and one that you think has more used points than available. You may want to use the 
#     "Zoom" button at the top of your plot viewer to get a better look at your maps.
# Export both used and available plots to include in your lab write-up


#-----------------------------------#
#### CALCULATING SELECTION RATIOS ####

# Now that we have used an available data, there's one last step to prepare our dataset
#   to calculate selection ratios for our coyote
# We need to get the habitat class underneath each used and available location.
# The extract() function does just that - it extracts the spatial data associated with
#   our point locations
# You may notice that this time (unlike in lab 4), we added "raster::" in front of extract
#   That's because we have another package loaded that also has an extract() function! So the
#   poor computer gets confused, and we have to tell it which package to use.
# By extracting within the sf object using mutate(), we simply add an NLCD column to our dataframe
coyote_used_available %>% 
  mutate(NLCD = raster::extract(utah_NLCD, as(.,"Spatial"))) -> coyote_habitat

coyote_habitat

# Unfortunately extract() saved the habitat number, not name. So we can use our land cover key
#   to match the number to the habitat name and replace it in our dataframe
coyote_habitat$NLCD = landcoverkey$landcover[match(coyote_habitat$NLCD,landcoverkey$ID)]

# All better!
coyote_habitat

# Now we have the habitat class at every point. All that's left is to calculate the proportion
#   of each habitat type within the used and available datasets
# (Remember, the selection ratio for a given habitat type is the proportion of used locations
#   divided by the proportion of available locations)
# First, we turn our dataset into a tibble using as_tibble() to make it work better with 
#   our tidyverse functions
# How do we calculate proportions? We have to think way back to Lab 2, where we learned the 
#   summarize() function.
# We need to summarize total counts separately for Used and NCLD (habitat) using group_by()
#   and summarize(), then we create a new column for proportions in which we divide the habitat
#   counts by the total number of locations in the used and available datasets (coyote_n)
coyote_habitat %>% 
  as_tibble() %>% 
  group_by(Used, NLCD) %>% 
  summarize(count = n()) %>% 
  mutate(proportion = count/coyote_n) -> coyote_sum

# Now we've got it! Proportions of each habitat type with our used and available groups.
coyote_sum

# Your turn!
# Make a barplot from the coyote_sum dataset with NLCD on the x axis, proportion on the y, and 
#   fill the bars according to the column Used. Make sure to include stat and position commands
#   in your geom_bar() function so that you are plotting the proportion values for used and
#   available datasets next to each other
# add + theme(axis.text.x = element_text(angle = 50, hjust = 1)) to the end of your ggplot
#   script so that you can read the habitat class names

ggplot(data = coyote_sum, aes(x = NLCD, y = proportion, fill = Used)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme(axis.text.x = element_text(angle = 50, hjust = 1))
  

####** QUESTION 3:#### 
#Which two habitat types are most available in coyote C028's home range? Which
#     two habitat types are most used by coyote C028? Of these two, which appears to be 
#     selected for by the coyote?
# Export your plot to include in your lab report

# To calculate our actual SRs, we need separate proportion columns for our used and available
#   habitat proportions. To transform our dataframe, we "pivot" it - i.e. we can create
#   two proportion columns out of one!
coyote_sum %>%
  pivot_wider(names_from = Used, values_from = c(count,proportion)) -> coyote_sum2

# Now we have a dataframe of 8 habitat types with their proportion of available and used points
coyote_sum2

# Your turn!
# Add a column to coyote_sum using mutate() of the calculated SRs. name the column selection_ratio
coyote_sum2 %>% 
  mutate(selection_ratio = proportion_used/proportion_available) -> coyote_sum3

# What do our selection ratios look like?
#   We can add a horizontal line at SR = 1 so we can see how habitats are selected:
#     Any bar over the line is selected for, and bar under the line is selected against (avoided)
ggplot(coyote_sum3,aes(x = NLCD,y = selection_ratio,fill = selection_ratio)) +
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 50, hjust = 1)) +
  geom_hline(yintercept = 1, linetype="dashed")

####** QUESTION 4:#### 
#Which habitats were selected for? Which would you say seems to be the most 
#     important habitat to conserve for C028 based on this plot? Now look back at your 
#     plot for Question 3 - does it change your opinion on the most important habitat for
#     this coyote? Why or why not?
# Export your plot for your lab report

#-----------------------------------#
#### COMPARING SELECTION RATIOS BETWEEN DAY AND NIGHT ####

# Your turn! For the last two lab questions, you will go through the entire habitat selection
#   analysis yourself, from start to finish
# We're going to examine how puma F53 selects habitat differently between day and night
# To start you off, I've provided the set.seed, the function to isolate F53's home range
#   polygon, and the input commands for a day dataset and a night dataset



# get f53 HR
puma53_HR <- st_as_sf(carnivores_kud_95)[2,]

# puma select during day
read_csv("data/Utah_carnivores.csv") %>% 
  filter(individual == "F53", daynight == 1) %>% 
  dplyr::select(UTMeasting, UTMnorthing) %>% 
  mutate(Used = "used", daynight = "day") %>% 
  st_as_sf(coords = c("UTMeasting","UTMnorthing"), 
           crs = "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs")-> puma53_used_day

# puma select at night
read_csv("data/Utah_carnivores.csv") %>% 
  filter(individual == "F53", daynight == 0) %>% 
  dplyr::select(UTMeasting, UTMnorthing) %>% 
  mutate(Used = "used", daynight = "night") %>% 
  st_as_sf(coords = c("UTMeasting","UTMnorthing"), 
           crs = "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs")-> puma53_used_night

#visualizing, checking they are different!
ggplot() + 
  geom_sf(data = puma53_HR, alpha = 0.4) +
  geom_sf(data = puma53_used_day)

ggplot() + 
  geom_sf(data = puma53_HR, alpha = 0.4) +
  geom_sf(data = puma53_used_night)

# Conduct a habitat selection analysis for each dataset by calculating habitat SRs for
#   puma F53 during the day and at night.
# To do this, you will need to do the following for each dataset (day and night):
#     (Side note: feel free to copy-paste the existing code and just modify it to accommodate
#        your new variable and dataframe names! Coding in R is all about copy-pasting) 
# 1. save the number of used locations

n_used_day<- nrow(puma53_used_day)
n_used_night<- nrow(puma53_used_night)

# 2. randomly sample available locations within F53's home range (same number as used locations)



# day available
st_sample(puma53_HR, size = n_used_day) %>% 
  st_sf(geometry = .) %>%
  mutate(daynight = 1,
         Used = "available") -> day_available

# night available
st_sample(puma53_HR, size = n_used_night) %>% 
  st_sf(geometry = .) %>%
  mutate(daynight = 0,
         Used = "available") -> night_available


# 3. make a combined used and available dataframe using rbind for both day and night datasets (separately)
day_used_available <- rbind(puma53_used_day, day_available)
night_used_available <- rbind(puma53_used_night, night_available)

# 4. extract the habitat classes at each used and available location
# day habitat
day_used_available %>% 
  mutate(NLCD = raster::extract(utah_NLCD, as(.,"Spatial"))) -> day_habitat

# night habitat
night_used_available %>% 
  mutate(NLCD = raster::extract(utah_NLCD, as(.,"Spatial"))) -> night_habitat


# 5. rename the values in the NLCD column in your used_available dataframe as habitat class
#     names rather than numbers

#day rename
day_habitat$NLCD = landcoverkey$landcover[match(day_habitat$NLCD,landcoverkey$ID)]

#night rename
night_habitat$NLCD = landcoverkey$landcover[match(night_habitat$NLCD,landcoverkey$ID)]


# 6. summarize the used and available habitat counts and make a new proportion column (for
#     both day and night datasets)

# day summary
day_habitat %>% 
  as_tibble() %>% 
  group_by(Used, NLCD) %>% 
  summarize(count = n()) %>% 
  mutate(proportion = count/n_used_day) -> day_sum




#night summary
night_habitat %>% 
  as_tibble() %>% 
  group_by(Used, NLCD) %>% 
  summarize(count = n()) %>% 
  mutate(proportion = count/n_used_night) -> night_sum



# 7. plot the used and availble proportions in ggplot for day and night (two plots)
ggplot(data = day_sum, aes(x = NLCD, y = proportion, fill = Used)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme(axis.text.x = element_text(angle = 50, hjust = 1))

ggplot(data = night_sum, aes(x = NLCD, y = proportion, fill = Used)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme(axis.text.x = element_text(angle = 50, hjust = 1))


# 8. use pivot_wider to reshape your dataframe and create a new SR column
# day pivot
day_sum %>%
  pivot_wider(names_from = Used, values_from = c(count,proportion)) -> day_sum2

# day proportion
day_sum2 %>% 
  mutate(selection_ratio = proportion_used/proportion_available) -> day_sum3


# night pivot
night_sum %>%
  pivot_wider(names_from = Used, values_from = c(count,proportion)) -> night_sum2

# night proportion
night_sum2 %>% 
  mutate(selection_ratio = proportion_used/proportion_available) -> night_sum3

# 9. plot the selection ratios in ggplot for day and night (two plots)
# day plot
ggplot(day_sum3,aes(x = NLCD,y = selection_ratio,fill = selection_ratio)) +
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 50, hjust = 1)) +
  geom_hline(yintercept = 1, linetype="dashed")

#night plot
ggplot(night_sum3,aes(x = NLCD,y = selection_ratio,fill = selection_ratio)) +
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 50, hjust = 1)) +
  geom_hline(yintercept = 1, linetype="dashed")


# NOTE: if any of your SR plots have the warning message, "Removed 1 rows containing missing values 
#     (position_stack)", that means that there were either no used or no available locations
#     for that habitat class, so an SR cannot be calculated. You can go back to your plots
#     in step 7 to validate that those habitat types only have values within either the used
#     or available categories.

####** QUESTION 5:#### 
#Look at your plots from step 7. Do you notice any differences in proportion
#     of used habitats between day and night? If so, what are they?

####** QUESTION 6:### 
#Look at your plots from step 9. Which habitat(s) were selected for at night
#     that were not selected for during the day? Why do you think there might have been a
#     shift in selection for that/those habitat type(s) between day and night?

#--------------#
#### QUESTIONS FROM LECTURE AND READINGS ####

#** QUESTION 7: Was Yellowstone empty when it was designated a National Park? Who had
#     rights to the land where Yellowstone was designated before it became a park?

#** QUESTION 8: From Deniss Martinez's lecture, name three reasons why cultural burning by 
#     California Native tribes is an essential cultural or ecological practice.

#--------------#
#### CONGRATS! ####
# You've learned how to conduct habitat selection analyses in R
# Please reach out to your TA, Ellie Bolas (ebolas@ucdavis.edu) for questions about this lab
