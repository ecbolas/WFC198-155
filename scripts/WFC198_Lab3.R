#### Welcome to your third lab for WFC 198! ####
## Lab 3: Working with animal movement data ##

# Today we will learn about how to load, process, and visualize spatial animal movement
#   data in R.
# We will work in the package sf, which is a great new package that integrates with the 
#     tidyverse. 
# All of our animal movement track analysis will be conducted using the amt package.

## Lab 3 OBJECTIVES ##
# 1. Load spatial data in R - use R as a GIS (geographic information system)
# 2. Define the correct coordinate system for your dataset
# 3. Visualize animal movement data
# 4. Calculate and visualize movement parameters from animal movement data

# We need to install a few more packages for this week:
#install.packages("sf", dependencies=T)
#install.packages("amt", dependencies=T)
#install.packages("lubridate", dependencies=T)
#install.packages("mapview", dependencies=T)

library(tidyverse)
library(sf)
library(lubridate)
library(amt)
library(mapview)
rm(list=ls())
setwd("...")

#-----------------------------------#
#### GETTING STARTED WITH SPATIAL DATA ####

# Before we start, let's talk GIS!
# GIS stands for geographic information system. GISs let us analyze and visualize data that
#   are spatial in nature.
# What's different about spatial data than other data? Ultimately, not much! Spatial locations
#   can be depicted on x and y axes, just like other data. Want to include something like 
#   elevation? Well then we just use 3-dimentional data analysis and visualization techniques
# What sets spatial data apart are two main things:
#  1. We often want to know different things about spatial data than the kind of data we worked
#     with last week. Rather than knowing if x influences y, we more often want to know about
#     how spatial data points are related to one another - such as the distance between 
#     spatial locations, or how clustered spatial data points are.
#  2. Also, we can think about spatial data in terms of "layers" - elevation, slope, and
#     animal location data are all independent "layers" of data that provide different 
#     information about the same spatial locations. 
# Today, we're going to focus on #1 (relationships between locations). Next week, we'll
#   explore some spatial habitat layers.

# Unlike the last two weeks, when we got the penguin data from a package, 
#   we're going to be loading our own data today! That means we need to tell our computer
#   where our data file is.
# You can set up a working directory to make it easier to bring in your data files
# A working directory is essentially a single folder on your computer that RStudio looks in
#   to find files. You can also easily save outputs from RStudio into your working directory
#   folder.

# The first step is to make a folder that you want to use as your working directory. 
# You may want to include it in a WFC 198 folder (if you have one). I'll call mine 
#   "WFC198_labs"
# Then, make sure you download the data file for today ("Tsavo_lions.csv") 
#   and put it in that folder

# First, use "getwd()" to see the format for calling a file from your computer
getwd()

# We can set our working directory using the setwd() function
#   Your path might look a bit different than mine if you have a PC. Modify the path you 
#   saw when you ran getwd() to make sure the pathname can be read by your machine.
# Make sure to include the path name in quotes
setwd("/Users/justinesmith/WFC198/WFC198_labs")
setwd("...")

# Once our working directory is set up, we can easily pull in data files from that folder
#   using the read_csv() function
tsavo_lions <- read_csv("data/Tsavo_Lions.csv")
str(tsavo_lions)

# Check out what the dataframe looks like.
# This is a publicly available dataset on the movements of lions in southern Kenya
tsavo_lions

# If we want to see how many locations we have for each animal, we can quickly use the
#   tally() function after grouping by individual
tsavo_lions %>% 
  group_by(individual) %>% 
  tally()

# In our dataframe, we have info on the time, the name of the individual lion, and a 
#   bunch of spatial columns
# We need to correct our "timestamp" column so that it has the right time zone in Kenya
# That way, the actual times in our data will correctly match the times that the lion
#   locations were recorded in our study site
# Because Nairobi is in Eastern African Time, we can use it as a reference point to correct 
#   our timestamp column by using function force_tz()
tsavo_lions %>% 
  mutate(timestamp_local = force_tz(timestamp_local, tz = "Africa/Nairobi")) -> tsavo_lions

#tsavo2<- tsavo_lions %>% mutate(timestamp_local = with_tz(timestamp_local, tz = "Africa/Nairobi"))

# You'll also see columns for latitude and longitude, and other ones that start with "UTM"
# Both UTMs and Latitude/Longitude are "coordinate reference systems" (CRS). That means they
#   give us a way to understand the spatial location of things on our planet.
# CRSs are so important because the world is round! How do we grid out locations on a
#   spherical object? CRSs help us do that.
# "UTM" stands for universal transverse mercator. Like latitude and longitude, it's a 
#   way to distribute spatial coordinates around the world.
# What's the difference between latitude/longitude (latlongs, for short) and UTMs?
# Latlongs are fit to the globe as a three dimensional surface. UTMs slice the earth into 
#   sixty north-to-south strips, flattening each one (like a map!)
# (If you are curious about what UTM zones look like on the Earth, do a quick google image 
#   search for "UTM zones")
# UTMs are therefore sometimes easier to visualize on a 2-dimensional surface, but both
#   latlongs and UTMs are equally accurate. It's really just a matter of preference which you
#   choose to use!

# In our lion dataset, we have both latlongs and UTMs
# We can plot either by setting longitude/latitude or UTMeasting/UTMnorthing as our x/y
ggplot(data = tsavo_lions, aes(x = longitude, y = latitude, color = individual)) + 
  geom_path() + geom_point() 

ggplot(data = tsavo_lions, aes(x = UTMeasting, y = UTMnorthing, color = individual)) + 
  geom_path() + geom_point() 

# There's only one issue - by just plotting the coordinates as x and y's, our data
#   are not to scale. We need to officially make our data spatial so that they are plotted
#   correctly. To do that, we need to set our CRS.
# Because latlongs are fit to the entire globe, our CRS for latlongs is really simple:
# Here, we are defining a CRS with a latlong projection using the WGS84 datum
#   (you may learn about different datums in a GIS class. In this class, we'll stick to 
#     WGS84 becausee it's the most common)
myCRSlatlong <- ("+proj=longlat +datum=WGS84")

# Now, we assign the CRS to our data, so that out data are projected in the right location
#   on the globe:.
# We can do this with a pipe!
# First, reference your data, followed by the pipe operator
#   then, use st_as_sf to make your movement data spatial and assign the x and y coordinates
#   finally, assign the correct CRS and name your new tibble.
tsavo_lions %>%  
  st_as_sf(coords = c("longitude","latitude"), 
           crs = myCRSlatlong) -> tsavo_lions_latlong

# Now we have a spatial dataframe! In addition to our "tbl" and "data.frame" classes,
#   we also have data of class "sf", a type of spatial data
class(tsavo_lions_latlong)

# Let's look at the data! To plot spatial data of class "sf" in latlongs we use geom_sf() 
#   within the ggplot function. Unlike with our previous data visualizations, we don't need
#   to specify x and y variables. 
# We do need to make sure our machine knows our CRS, which we can specify with coords_sf()
ggplot(data = tsavo_lions_latlong) +
  geom_sf() + 
  coord_sf(datum = myCRSlatlong)

# Your turn!
# Remember how we can use the color command in ggplot to differentiate variables by color?
# Modify the above plot so that there are different colors for each individual.
# Hint: remember to add aes() within your ggplot function

ggplot(data = tsavo_lions_latlong, aes(color = individual)) +
  geom_sf() + 
  coord_sf(datum = myCRSlatlong)

##** QUESTION 1: Which individual do you think has the larger home range?
##      Export your plot for your lab write-up.

# Your current map is plotted using latlongs, but its sometimes preferable to use UTMs
#   (One benefit of UTMs is the axes mean something tangible - an increase of 1 corresponds
#   to 1 meter!)

# For UTMs, because it's split into 60 N-to-S strips, we need to tell the computer which
#   strip, or zone, our data are in. Check out what the UTM zone column says in your 
#   dataframe:
tsavo_lions

# Looks like we're in zone 37! We're also below the equator, so we have to add "+south" 
#   (and some other stuff that is standard for UTMs, such as "units")
myCRSutm <- ("+proj=utm +zone=37 +south +datum=WGS84 +units=m +no_defs")

# Your turn!
# Make a dataframe called "tsavo_lions_UTM" from the original tsavo_lions tibble
#   Make sure you use the correct coordinate columns and the new CRS
#   Hint: easting is on the x axis, and northing is on the y axis, so easting comes before
#     northing when you define your coordinates

tsavo_lions %>%  
  st_as_sf(coords = c("UTMeasting","UTMnorthing"), 
           crs = myCRSutm) -> tsavo_lions_utm
tsavo_lions_utm

#tsavo2 %>%  
 # st_as_sf(coords = c("UTMeasting","UTMnorthing"), 
  #         crs = myCRSutm) -> tsavo_lions_utm2
# Plot the location data in UTMs with the correct datum, but separate the individuals
#   into different plots using facet_wrap()
#   Hint: you may want to revisit Lab 2 to remind you how to use facet_wrap

ggplot(data = tsavo_lions_utm, aes(color = individual)) +
  geom_sf() + 
  coord_sf(datum = myCRSutm) +
  facet_wrap(~individual)

####** QUESTION 2:####
#Between Diana and Romeo, which traveled further to the west?
#       Export the plot for your lab write-up

# So far, we've looked at static plots of our data. 
# But, a new package called "mapview" allows us to actually zoom around to explore our data
# You can zoom in and out, change the background layer (click the box with the multiple 
#   overlapping squares), or look at data from individual points (click a location). Fun!
mapview(tsavo_lions_utm, zcol = "individual")


#-----------------------------------#
#### WORKING WITH ANIMAL TRACKS ####

# "tracks" are sequential animal locations - so far we've only looked at animal locations
#   as independent points, but you could imagine linking them together with steps (lines)
#   drawn between sequential points so you could see more clearly how the animal moved
#   through space.

# In order to make a track, we need to separate each individual animal within the dataframe
# For now, let's just make a separate dataframe for a single animal, Romeo

# Your turn!
# Use the filter command on the original tsavo_lions dataset so that we only have data for 
#   Romeo, and name the new tibble "tsavo_Romeo"
# Hint: use the double equals sign (==) to filter by a single value

tsavo_Romeo <- tsavo_lions %>% filter(individual == "Romeo")

# To make a "track" for Romeo, we'll use the mk_track() function from the amt package
# In this function, we give the following information: tbl (tibble), .x (x coordinates),
#   .y (y coordinates), .t (timestamp), and crs (our coordinate reference system, which 
#   we need to transform to a CRS object using the function CRS())
# Let's use UTMs rather than latlongs for this track
Romeo_track <- mk_track(tbl = tsavo_Romeo, .x = UTMeasting, .y = UTMnorthing, .t = timestamp_local, 
                        crs = CRS(myCRSutm))

# What does the track look like?
Romeo_track
class(Romeo_track)

# Basically what we have just looks like our coordinates and timestamp, but now that they 
#   are in a track_xyt class, we can do a lot more with them!

# To start, we can see how often locations were recorded on Romeo's GPS collar 
summarize_sampling_rate(Romeo_track)

# It looks like the median fix rate is 7 hours, according to summarize_sampling_rate()
# (A fix rate is how often locations are recorded)
# Look back at Romeo_track. How many hours are generally between locations?
Romeo_track

# Also 7! 
# However, according to summarize_sampling_rate(), the min time between points is 6 hours
# Why might we want to only use the 7-hour data when calculating movement parameters, like
#   step length (or the distance between two locations)?
# Well, for starters, a lion could probably move farther in 7 hours than it could in 6
# So, we want to "resample" our data, whereby we only keep locations at the 7 hour fix rate
#   We can also set a "tolerance", which allows 7-hour fixes to have a little wiggle room.
#   "Tolerance" is really helpful because usually locations aren't recorded exactly on the 
#     hour - it takes a few minutes to communicate with the satellites.
Romeo_track %>% 
  track_resample(rate = hours(7), tolerance = minutes(15))  -> Romeo_track_7
summarize_sampling_rate(Romeo_track_7)
# How do your sampling rates look now? 
####** QUESTION 3.#### 
#How has the minimum value changed? What about the number of locations (n) -
#       what was if before and what is it after we resampled our data?
#       Why did the value of n change after we resampled our data?

# Ok, so we've dealt with our fix rate, but we still have some locations that are greater
#   than our 7 hour fix rate. summarize_sampling_rate() indicates that our max is 28 hours
# To deal with this, we we have created "bursts" during the resample
# A burst is a series of locations in a row that all have the target fix rate (7 hours for us)
#   Once there is more than 7 hours between locations, we create a new "burst"
# This allows us to only calculate movement parameters (e.g. step length and turn angle)
#   for locations within 7 hours.
# Look back at the data to see the bursts
Romeo_track_7

# How much time passed between the end of burst 1 and the start of burst 2? Was is greater
#   than 7 hours? What about the first two locations in burst 2 - how much time passed
#   between them?

# Unfortunately, we have some bursts (like burst 1 and 3) that only have 1 location! That's
#   not very helpful for calculating the distances between locations within a burst.
# So, we can set a minimum number of locations/burst at 2 to filter out 1-location bursts
Romeo_track_7 %>% 
  filter_min_n_burst(min_n = 2) -> Romeo_track_clean

# Now, we only have bursts with more than one location!
Romeo_track_clean

# Finally, our data are sufficiently cleaned to calculate movement parameters.
# steps_by_burst() is a fun little shortcut that actually calculates step lengths and turn
#   angles for you!
# Since steps_by_burst() creates a new object that is not a track, we'll give it a new name:
Romeo_track_clean %>% 
  steps_by_burst() -> Romeo_steps

# What class is our new object?
class(Romeo_steps)

# So now we have an object of type "steps_xyt"! Rather than each row being a single location,
#   now every row is a step between two locations. So we now have information for the 
#   coordinates and time of the location at the start of the step, and for the coordinates
#   and time of the location at the end of the step.
# We also have cool summary data on step lenghts (sl_), turn angles (ta_), and the time 
#   between the start and end locations (dt_)
Romeo_steps

# One last piece of information we might want is which points occurred during the day and 
#   which ones occurred at night. 
Romeo_steps  %>% 
  time_of_day() -> Romeo_steps

# Now let's check out our data! One movement parameter we might expect to differ between
#   day and night is step length.
# We can go back to our trusty ggplot to look at how the distribution of step lengths
#   (called sl_ in our dataframe) are different between day and night.
# To look at this, we'll use geom_density(), which is basically a smoothed histogram
# I've also added alpha = 0.4 to make our curves more transparent (1 = opaque, 0 = 
#   completely see-through), and I've modified the color scheme with scale_fill_brewer()
# (Remember, we use "color" for lines and points, and "fill" for polygons that you fill in)
ggplot(Romeo_steps, aes(x = sl_, fill = tod_end_)) +
  geom_density(alpha = 0.4) +
  scale_fill_brewer(palette="Dark2")

####** QUESTION 4: ####
#By looking at your figure, does Romeo generally move more than 5 kilometers
#     in a movement step more during the day or at night? Did he move less than 1 kilometer 
#     in a step more during the day or at night?
#   Hint: our step length unit is in meters

# Your turn!
# You now have all the steps you need to construct an animal track, clean the data,  
#   calculate movement metrics, and plot the distributions of movement metrics.
# Do the same process for lion "Diana":
#   1. Start by filtering tsavo_lions and saving your new tibble as "tsavo_Diana"
#   2. Make a track from Diana's locations, called "Diana_track"
#   3. Find the median fix rate from summarize_sampling_rate() to assign as the resampling 
#       rate in the next step (it's not 7 hours this time!)
#   4. WRITE A PIPE to link up the resample, burst filtering, creating steps, and extracting
#       time of day in *one single pipe* by using the pipe operator.
#   5. Name the output "Diana_steps"

# filter diana


tsavo_Diana <- filter(tsavo_lions, individual == "Diana")

#tsavo_Diana2 <- filter(tsavo2, individual == "Diana")
# make track
Diana_track <- mk_track(tbl = tsavo_Diana, .x = UTMeasting, .y = UTMnorthing, .t = timestamp_local, 
                        crs = CRS(myCRSutm))

#Diana_track2 <- mk_track(tbl = tsavo_Diana2, .x = UTMeasting, .y = UTMnorthing, .t = timestamp_local, 
 #                       crs = CRS(myCRSutm))

# median fix rate (= 6)
summarize_sampling_rate(Diana_track)

# clean and create steps object
 Diana_track %>% 
  track_resample(rate = hours(6), tolerance = minutes(15)) %>% 
  filter_min_n_burst(min_n = 2) %>% 
  steps_by_burst() %>% 
   time_of_day()-> Diana_steps
  
Diana_steps

#Diana_track2 %>% 
  # track_resample(rate = hours(6), tolerance = minutes(15)) %>% 
  # filter_min_n_burst(min_n = 2) %>% 
  # steps_by_burst() %>% 
  # time_of_day()-> Diana_steps2
  
####** QUESTION 5:####
#Copy and paste your pipe (steps 4 & 5 above) into your lab report

# Plot Diana's distribution of step lengths separated by time of day. 
ggplot(Diana_steps, aes(x = sl_, fill = tod_end_)) +
  geom_density(alpha = 0.4) +
  scale_fill_brewer(palette="Dark2")

#ggplot(Diana_steps2, aes(x = sl_, fill = tod_end_)) +
 # geom_density(alpha = 0.4) +
  #scale_fill_brewer(palette="Dark2")

# Use the summarize() function from our first lab to calculate her mean step lengths
#   during the day and at night.

summarize(group_by(Diana_steps, tod_end_),
          count = n(),
          mean_tod = mean(sl_))


# summarize(group_by(Diana_steps2, tod_end_),
#           count = n(),
#           mean_tod = mean(sl_))
  
####** QUESTION 6: ####
#Does Diana move farther on average during the day or at night? What is her 
#     mean step length during the day? What about at night?
#   Export your plot to include in your lab report.


# Our last exercise for today is to compare Diana and Romeo's movement parameters.
# We'll start by adding columns containing their names using mutate()
Romeo_steps %>% 
  mutate(individual = "Romeo") -> Romeo_steps
Diana_steps %>% 
  mutate(individual = "Diana") -> Diana_steps

# Then we will use a function called rbind() to combine both objects together
R_and_D_steps <- rbind(Romeo_steps,Diana_steps)

# Scroll down our new object. Do we have data from both Romeo and Diana?
view(R_and_D_steps)

# You can also check the number of steps from each individual using tally()
R_and_D_steps %>% 
  group_by(individual) %>% 
  tally()

# Just like we plotted differences in step length distribution between day and night within
#     individuals, we can compare the distribution of step lengths between individuals
ggplot(R_and_D_steps, aes(x = sl_, fill = individual)) +
  geom_density(alpha = 0.4) +
  scale_fill_brewer(palette="Accent")

# Your turn!
# Make a plot comparing the turn angles (called ta_ in our dataframe) between Diana and Romeo
#   (You will get an error that some rows have been removed. Don't worry! Those are just 
#     the rows that don't have turn angles because they are at the beginning of a burst)

ggplot(R_and_D_steps, aes(x = ta_, fill = individual)) +
  geom_density(alpha = 0.4) +
  scale_fill_brewer(palette="Accent")

####** QUESTION 7: #### 
#Based on your turn angle plot, does Diana or Romeo have more movements
#     that look like "directed travel"? Explain how you arrived at your answer.

#--------------#
#### QUESTIONS FROM LECTURE AND READINGS ####

#** QUESTION 8: How does Dr. Terrie Williams measure cost of transport in captive animals?

#** QUESTION 9: If migratory animals are "surfing the green wave", what measure of
#         "green up" are they trying to maximize?

#--------------#
#### CONGRATS! ####
# You've learned how to work with spatial animal movement data in R
# Please reach out to your TA, Ellie Bolas (ebolas@ucdavis.edu) for questions about this lab