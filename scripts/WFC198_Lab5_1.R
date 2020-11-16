#### Welcome to your fifth lab for WFC 198! ####
## Lab 5: Estimating home ranges ##

# Today we will learn about how to estimate home ranges from animal location data
# We will work largely in the package adehabitatHR

# NOTE on the data we will be using today (accessed from MoveBank, an open source animal movement repository):
# Study License Information valid at 2020-09-22 21:35:34 Name: ABoVE: Boutin Alberta Grey Wolf Citation: Boutin S., H. Bohm, E. W. Neilson, A. Droghini, and C. de la Mare. 2015. Wildlife habitat effectiveness and connectivity: Final report. University of Alberta, Edmonton, AB.
# E. W. Neilson and S. Boutin. 2017. Human disturbance alters the predation rate of moose in the Athabasca oil sands. Ecosphere 8(8): e01913. DOI: 10.1002/ecs2.1913
# A. Droghini and S. Boutin. 2018. The calm during the storm: Snowfall events decrease the movement rates of grey wolves (Canis lupus). PLoS ONE 13(10):e0205742. DOI: 10.1371/journal.pone.0205742 
# Acknowledgments: Holger Bohm coordinated data collection and management. Grants Used: Collection of telemetry data was funded by the Canadian Oil Sands Innovation Alliance (COSIA). Additional support for fieldwork was provided by the Northern Scientific Training Program and the University of Alberta's Circumpolar/Boreal Alberta (C/BAR) Grant. EWN was partially funded through an NSERC Postgraduate Scholarship. AD was funded by a NSERC Masters Scholarship, les Fonds de recherche du Québec, and the University of Alberta. License Type: Custom License Terms: Please contact the data owners to discuss possible uses of the data. Principal Investigator Name: Stan Boutin

## Lab 5 OBJECTIVES ##
# 1. Estimate MCP and KDE home ranges
# 2. Visualize home ranges
# 3. Compare home range sizes and maps between home range estimators, KDE bandwidths (h), and 
#     95% vs. 50% home ranges
rm(list=ls())
setwd("...")

# We need to install one more package for this week:
install.packages("adehabitatHR", dependencies=T)

# Load in your packages
library(tidyverse)
library(sp)
library(sf)
library(mapview)
library(adehabitatHR)
library(ggplot2)

# Like the last 2 weeks, make sure you set your working directory to the folder where you 
#   downlaoded the files for lab this week
#setwd("/Users/justinesmith/WFC198/WFC198_labs")

#-----------------------------------#
#### PREPARING POINT VECTOR DATA AS AN "sp" OBJECT ####

# First, let's load in our data. 
# This dataset is a subset of wolves from a larger study on wolves in Alberta
#   These data are open source, which means they are freely available to download online
#   If you are interested in checking out some cool, open source animal movement datasets,
#   visit movebank.org
# We can start by using "read_csv()" to load our data
alberta_wolves <- read_csv("data/Alberta_Wolf.csv") 

# As always, check out your data before proceeding!
view(alberta_wolves)

# As with the lion dataset from lab 3, we have columns for the name of the individual animal,
#   latlongs, UTMs and UTM zone, UTC (Coordinated Universal Time) and local time,
#   and the local timezone

### A NOTE ON "sf" VS "sp" ###
# Both "sp" and "sf" are packages that create spatial layers from vector data (points, lines
#   and polygons)
# In Lab 3, we plotted animal location data in the package "sf". "sf" is awesome because it's
#   very fast and it works really well with the tidyverse (piping) and ggplot. 
# However, "sf" is really new, much newer than "sp". "sp" is the older way of dealing with 
#   spatial vector data in R. That means, some older packages only work with "sp" data, not
#   "sf" data (including the home range package we are using today). But ggplot only works 
#   with "sf" data! So we sometimes need to switch back and forth.
# A vector of animal locations in "sp" will be of class "SpatialPointsDataFrame", whereas the 
#   same vector data in "sf" will be of class "sf" and "tbl_df".
# Unfortunately, we need to work with both sf and sp, as confusing as that is! It's just the 
#   name of the game when using RStudio, where things are always changing and advancing

# We can start by making a copy of our dataset which we will turn into an "sp" object
alberta_wolves_sp <- alberta_wolves

# To make our dataset spatial in "sp", we assign it coordinates and a crs
# Unlike with the package "sf" that we used in Lab 3, in the "sp" package we assign the 
#   coordinates using "coordinates()" and the crs using "proj4string()". 
# Unfortunately, "sp" doesn't work nearly as well with the tidyverse as "sf", so we have
#    to run the functions one at a time instead of writing a pipe
coordinates(alberta_wolves_sp) <- ~ UTMeasting + UTMnorthing

# Remember, for UTMs we need to specify the zone. In our UTMzone column, you can see we are
#   in Zone 12 N (north). North is the default, so we only need to specify zone 12
proj4string(alberta_wolves_sp) <- "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs"

# Check the class of your new dataframe
class(alberta_wolves_sp)

# Now our data are in a SpatialPointsDataFrame! 
# I always like to visualize my animal locations before doing any analysis
# To plot these data using ggplot, we can convert them to an "sf" object inside of ggplot by 
#   using st_as_sf() around the data name, and geom_sf() to plot the spatial points
ggplot() + 
  geom_sf(data = st_as_sf(alberta_wolves_sp), aes(color = individual))

# Remember our very cool mapview() function? If you want to look closer at the data, 
#   you can color individuals using "zcol" within mapview
mapview(alberta_wolves_sp,zcol = "individual")

# What do you notice about our wolf dataset? How many wolves are there? Do they appear to 
#   be territorial? Do the home ranges appear to be different sizes?

#-----------------------------------#
#### ESTIMATING MINIMUM CONVEX POLYGONS ####

# Now we can start estimating home ranges with the "adehabitatHR" package

# First, make a new tibble called "wolf32253" by filtering alberta_wolves by 
#   individual "wolf_32253"
# Next, make wolf32253 an "sp" object using the coordinates() and proj4strong() functions

wolf32253<- filter(alberta_wolves, individual == "wolf_32253")
class(wolf32253)
wolf32253_sp<- wolf32253
coordinates(wolf32253_sp) <- ~ UTMeasting + UTMnorthing
proj4string(wolf32253_sp) <- "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs"
class(wolf32253_sp)

# Let's look at the area of the minimum convex polygon (MCP) home range for wolf 32253.
#   Remember from the home range lecture: an MCP is the smallest polygon with some percentage
#   of the animal locations inside it. Generally, ecologists use a 95% level. That means, 
#   the MCP of the animal is the smallest polygon that still contains 95% of the animal's 
#   locations. MCPs also can't have any inward-facing (concave) angles along the outside - 
#   all lines connecting points around the perimeter have to point out (convex)
# In only one line of code, we can calculate the MCP home range area across a bunch of 
#   different levels, so we can see how the home range size increases as we add more
#   of the animal's data.
# To do this, use function mcp.area()
#   Inside the function, we will call the column of individuals by writing "wolf32253[1]"
#   Then we can specify that the units of our data are in meters (because our spatial data
#     is in UTMs, which is in meters), and that we want home range estimates reported in 
#     square kilometers.
wolf32253_mcp_area <- mcp.area(wolf32253_sp[1], unin = c("m"), unout = c("km2"))

# What do you notice about how home range size increases with level?

# We can derive the outlines of MCP home ranges at different levels using the mcp() function
#   Again, we call the individuals column, and we also specify the percent (or level)
# Researchers usually use th 95% level to determine the home range and a 50% level to 
#   determine the core 
# We'll also calculate the 100% home range to see how it compares
wolf32253_mcp_100 <- mcp(wolf32253_sp[1], percent=100)
wolf32253_mcp_95 <- mcp(wolf32253_sp[1], percent=95)
wolf32253_mcp_50 <- mcp(wolf32253_sp[1], percent=50)

# We can plot the home ranges one at a time...
ggplot() + 
  geom_sf(data = st_as_sf(wolf32253_mcp_95), color = "blue", fill = NA)

# Or we can look at them all at once, with the location data as well!
#   I've added a bunch of details to the location data geom_sf() function:
#     cex = how big the points appear, pch = the shape of the points, alpha = transparency
ggplot() + 
  geom_sf(data = st_as_sf(wolf32253_mcp_100), fill = "orange", alpha = 0.5) +
  geom_sf(data = st_as_sf(wolf32253_mcp_95), fill = "blue") +
  geom_sf(data = st_as_sf(wolf32253_mcp_50), fill = "red") +
  geom_sf(data = st_as_sf(wolf32253_sp),cex = 0.8, pch = 21, col = "black", 
          fill = "yellow", alpha = 0.5)

####** QUESTION 1: ####
#Now that you can see why the 100% level is so much larger than the 95% level,
#     explain why you might  use the 95% level instead of 100% level when calculating home
#     range size
#     Hint: remember the concept of "repeated use" in the definition of a home range

#-----------------------------------#
#### KERNEL DENSITY ESTIMATION ####

# MCPs can be totally sufficient for calculating home ranges for some specific animals,
#   but for others, they may overestimate the home range (and size). 
# Look back at our last figure. Especially along the northern portion of wolf 32253's home
#   range, there is a lot of empty space included in the home range that is totally unused
#   by the wolf.
# Kernel density estimators (KDE), which are also called kernel utilization distributions 
#   (KUD) when talking specifically about home ranges, can do a better job of excluding areas
#   that are only very rarely used by the animal.
# Just as with the mcp() function, we can build a KUD with the kernelUD() function.
# There are 2 primary differences:
#   1. We need to specify the bandwidth around each kernel using "h". The default is "href",
#     which lets the computer calculate the bandwidth, aka "smoothing parameter"
#   2. KUDs create a density surface first, before we split it up by levels 
#     (whereas with MCPs we could include the level in the initial function)
wolf32253_kud_href <- kernelUD(wolf32253_sp[1], h = "href")

# We can visualize the density surface we've created using "image()"
#   This plot shows us what is essentially a heat map of the wolf's locations
image(wolf32253_kud_href)

# Now that we have a probability surface, we calculate the area of levels of the KUD
#   home range using kernel.area()
#   Note that the unin and unout arguments are the same as in mcp.area()
# We can't actually calculate a 100% KUD because that would be the entire area of the 
#   density surface, so our levels only go up to 95% this time
wolf32253_kud_area <- kernel.area(wolf32253_kud_href, unin = c("m"), unout = c("km2"))

# Again, we see that the home range size goes up as we include more of the wolf locations.
#   Makes sense! 
plot(wolf32253_kud_area)

# To pull the levels out of our density surface, we use getverticehr() and specity the percent
wolf32253_kud_95_href <- getverticeshr(wolf32253_kud_href, percent = 95) 
wolf32253_kud_50_href  <- getverticeshr(wolf32253_kud_href, percent = 50)

# YOUR TURN!
# Make a plot showing the wolf locations and the 95% and 50% KUDs for wolf 32253
#   Feel free to change the colors or other graphical specifications (cex, pch, alpha) if 
#     you want to improve your visualization!
ggplot() + 
  geom_sf(data = st_as_sf(wolf32253_kud_95_href), fill = "orange", alpha = 0.5) +
  geom_sf(data = st_as_sf(wolf32253_kud_50_href), fill = "blue") +
  geom_sf(data = st_as_sf(wolf32253_sp),cex = 0.8, pch = 21, col = "black", 
          fill = "yellow", alpha = 0.5)


####** QUESTION 2:#### 
#Let's say we are trying to preserve this wolf's home range, but we only have
#     enough money to protect the core. Which method, MCP or KUD, would you use to guide 
#     this land preservation effort (would you save the land in the 50% MCP core or the
#     50% KUD core)? Explain your reasoning.
# Export the plot to include in your lab report.


#-----------------------------------#
#### COMPARING HOME RANGE SIZE FROM DIFFERENT ESTIMATORS ####

# Now, we'll use the same technique we used to compare lions Romeo and Diana in lab 3 to 
#   compare MCP and KUD home range sizes across levels 
# We can make new columns in each of our area objects so that the home range estimator and 
#   levels are explicit. 
wolf32253_mcp_area$home_range_type <- "MCP"
wolf32253_kud_area$home_range_type <- "KDE"
view(wolf32253_kud_area)

# The area functions don't save the levels as a column, but instead as the names of the rows.
#   Therefore, we need to add the levels by making a new, numeric column from rownames()
# Check out the rownames to see for yourself
rownames(wolf32253_mcp_area)
wolf32253_mcp_area$home_range_level <- as.numeric(rownames(wolf32253_mcp_area))
wolf32253_kud_area$home_range_level <- as.numeric(rownames(wolf32253_kud_area))

# Finally, we combine the objects together using rbind to make them easier to plot together
wolf32253_area <- rbind(wolf32253_mcp_area,wolf32253_kud_area)

# Are MCPs of KUDs usually larger? It depends on how the animal moves.
# Let's plot how the sizes of MCP and KUD home ranges differ across levels using our new object.
#     We can distinguish MCPs from KUDs using color = home_range_type.
#     geom_line() and geom_point() can both be used to show your data points and how they  
#     increase with home_range_level. ylab() can be used to label the y axis "home range size"
ggplot(wolf32253_area,aes(x = home_range_level,y = wolf_32253, color = home_range_type))+
  geom_line() + geom_point() +
  ylab("home range size")
  
####** QUESTION 3:#### 
#For this individual wolf, is the MCP or KUD home range generally larger across
#     levels? Which estimator type creates a larger 95% home range?

#-----------------------------------#
#### COMPARING HOME RANGE SIZE FROM DIFFERENT KUD BANDWIDTHS ####

# We used "href" to allow the computer to define our bandwidth when we calculated wolf 32253's
#   KUD above. 
# However, we can also define our own bandwidths (aka smoothing parameters) if we want the 
#   extent of a KUD home range to be tighter (smaller h) or larger (bigger h) around the 
#   animal locations.
# Let's make some new 95% home ranges with some different values for h and see how they compare

# YOUR TURN!
# Use the kernelUD() function to make two new density surfaces, one called wolf32253_kud5000
#   and one called wolf32253_kud1000. For wolf32253_kud5000, set h to 5000 (no quotes). For 
#   wolf32253_kud1000, set h to 1000.

wolf32253_kud5000<- kernelUD(wolf32253_sp[1], h = 5000)
wolf32253_kud1000<- kernelUD(wolf32253_sp[1], h = 1000)

# Now use getverticeshr() to create 95% KUD home ranges for each density surface object. 
#   Name the KUDs wolf32253_kud_95_5000 and wolf32253_kud_95_1000 respectively.

wolf32253_kud_95_5000<- getverticeshr(wolf32253_kud5000, percent = 95)
wolf32253_kud_95_1000<- getverticeshr(wolf32253_kud1000, percent = 95)

# Finally, use ggplot() to plot wolf32253_kud_95_1000, wolf32253_kud_95_href, and
#   wolf32253_kud_95_5000 on the same plot. Also include the wolf32253 location data.
#   Make the home range where h = 1000 the color "green", and the where h = 5000 "white"
# Hint: If you can't see all the home ranges or animal locations, you may need to change the
#   order you listed them in ggplot. ggplot will layer the plots on top of one another, 
#   whereby the first layer is on the bottom and the last is on top.

ggplot() + 
  geom_sf(data = st_as_sf(wolf32253_kud_95_5000), fill = "white") +
  geom_sf(data = st_as_sf(wolf32253_kud_95_1000), fill = "green") +
  geom_sf(data = st_as_sf(wolf32253_kud_95_href), fill = "orange", alpha = 0.5) +
  geom_sf(data = st_as_sf(wolf32253_sp),cex = 0.8, pch = 21, col = "black", 
          fill = "yellow", alpha = 0.5)

####** QUESTION 4:#### 
#Export the plot for your lab report.


# YOUR TURN - again (already)!
# Reference the method we used to plot comparisons of home range size between our MCP and KUD
# Make a plot that shows how size of home range levels differs for our two new h values
#   (1000 and 5000)
# 1. Start by making home range size objects for both bandwidths using kernel.area()
wolf32253_5000_area <- kernel.area(wolf32253_kud5000, unin = c("m"), unout = c("km2"))
wolf32253_1000_area <- kernel.area(wolf32253_kud1000, unin = c("m"), unout = c("km2"))
view(wolf32253_1000_area)

# 2. Then, make 2 new columns in each of these objects: 1) home_range_level, and 2) bandwidth
#     (this time, we are making a "bandwidth" column instead of "home_range_type")
#     When you make the bandwidth columns, make sure that your values are in quotes ("1000", "5000")
wolf32253_5000_area$bandwidth <- "5000"
wolf32253_1000_area$bandwidth <- "1000"

wolf32253_5000_area$home_range_level <- as.numeric(rownames(wolf32253_5000_area))
wolf32253_1000_area$home_range_level <- as.numeric(rownames(wolf32253_1000_area))


# 3. Use rbind() to make a single dataframe out of your two objects

wolf32253_area2 <- rbind(wolf32253_5000_area,wolf32253_1000_area)
view(wolf32253_area2)

# 4. Make your plot! Use color = bandwidth to distinguish the different bandwidths. 
ggplot(wolf32253_area2,aes(x = home_range_level,y = wolf_32253, color = bandwidth))+
  geom_line() + geom_point() +
  ylab("home range size")

####** QUESTION 5:#### 
#Looking at this plot and your plot from QUESTION 4, describe a scenario in 
#     which you might calculate a home range with a large bandwidth rather than a small 
#     bandwidth. In one sentence, explain your reasoning.
# Export your plot for your lab report.


#-----------------------------------#
#### ESTIMATING HOME RANGES FOR ALL INDIVIDUALS IN A POPULATION ####

# So far we've been working with data from a single wolf. But all of the methods we have
#   used can be applied to our entire alberta_wolves_sp dataset!

# Let's make 95% MCPs for all wolves...
allwolves_mcp_95 <- mcp(alberta_wolves_sp[1], percent=95)

# ...and 95% KUDs for all wolves (with "href" as our bandwidth)
allwolves_kud <- kernelUD(alberta_wolves_sp[1], h = "href")
allwolves_kud_95 <- getverticeshr(allwolves_kud, percent = 95) 

# Check out your data:
allwolves_mcp_95
allwolves_kud_95

# In these objects, we can see the area of the home ranges for each individual wolf

# We can plot these home range using the same st_as_sf() function we've been using, with
#   adding fill = id to fill in the color of the home ranges by individual
# MCP:
ggplot() + 
  geom_sf(data = st_as_sf(allwolves_mcp_95), aes(fill = id))

# KUD:
ggplot() + 
  geom_sf(data = st_as_sf(allwolves_kud_95), aes(fill = id))
          
# Combined:
ggplot() + 
  geom_sf(data = st_as_sf(allwolves_mcp_95), aes(fill = id), color = "white") +
  geom_sf(data = st_as_sf(allwolves_kud_95), aes(fill = id), color = "black", alpha = 0.5)

# We can also compare the area plots across individuals
# MCP:
par(mar=c(1,1,1,1))
wolves_mcp_area <- mcp.area(alberta_wolves_sp[1], unin = c("m"), unout = c("km2"))
# KUD: 
wolf32253_kud_area <- kernel.area(allwolves_kud, unin = c("m"), unout = c("km2"))
plot(wolf32253_kud_area)

# For our last exercise today, we'll use mapview() to try to learb a little more about
#   our wolf home ranges.
mapview(allwolves_kud_95, zcol = "id")

####** QUESTION 6:#### 
#Which two individuals appear to be in the same wolf pack (they use the
#     same area)?

# Change the basemap (squares on the left under the zoom in (+) and zoom out (-) buttons) 
#   to OpenStreetMap and zoom in until you can see some gray areas with white x's. These
#   are areas of oil and gas extraction.

####** QUESTION 7:#### 
#Which individual overlaps the most oil and gas extraction in their home range?

#--------------#
#### QUESTIONS FROM LECTURE AND READINGS ####

#** QUESTION 8: How do Gaynor et al. 2019 define the "Landscape of Fear"?

#** QUESTION 9: In top-down regulated systems, are plants generally limited by nutrients?

#--------------#
#### CONGRATS! ####
# You've learned how to estimate home ranges in R
# Please reach out to your TA, Ellie Bolas (ebolas@ucdavis.edu) for questions about this lab