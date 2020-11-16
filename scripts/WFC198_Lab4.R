#### Welcome to your fourth lab for WFC 198! ####
## Lab 4: Measuring habitat and working with rasters ##

# Today we will learn about how to load, process, and visualize habitat data in R.
# We will work largely in the packages raster and sp

## Lab 4 OBJECTIVES ##
# 1. Load and visualize raster and vector layers in R
# 2. Create new topographic raster layers from an elevation layer
# 3. Generate random points on your raster layers
# 4. Extract habitat data from layers and examine their relationships

# We need to install a few more packages for this week:
# install.packages("raster", dependencies=T)
# install.packages("rgdal", dependencies=T)
# install.packages("sp", dependencies=T)
# install.packages("rgeos", dependencies=T)
# install.packages("tidyverse", dependencies = T)
# Load in your packages
rm(list=ls())
setwd("...")
library(raster)
library(rgdal)
library(sp)
library(mapview)
library(rgeos)
library(ggplot2)

# Like last week, make sure you set your working directory to the folder where you downlaoded
#   the files for lab this week
#setwd("/Users/justinesmith/WFC198/WFC198_labs")
getwd()
#-----------------------------------#
#### GETTING STARTED WITH RASTER DATA ####

# Today we will be working with visualizing and analyzing habitat data
# Last week, we learned how to process "vector" data in R. Vector data take the form of 
#   polygons, lines, or points.
# Vectors are essentially identifiable features that are part of the landscape, like roads, 
#   park boundaries, or animal GPS locations
# Today, we will also work with "raster" data. Rasters are continuous surfaces of data, so 
#   they represent a characteristic of a habitat that is present but variable across an entire
#   area (such as elevation, habitat type, or canopy height)
# Rasters, like a photograph, show information in grid cells (like pixels). Therefore, how 
#   much detail you can see in a raster is directly related to the size of each grid cell.
# In our rasters for today, we have a resolution of 30 meters, so each 30 m x 30 m grid cell
#   on our map shows one unit of data.

# Let's get started by pulling in the three raster files for lab this week, elevation, NDVI,
#   and habitat class
# Rasters are often stored as Geotiff files, which end in ".tif"
# All of our environmental layers today are from the area in and around Sant Guillermo National
#   Park in the Argenine Andes (where vicunas live!)
# To load our raster files, we get to use the very intuitive function "raster()"
# We have rasters for Digital Elevation Model (DEM), normalized difference vegetation index
#   (NDVI), and habitat class
elevation <- raster("data/lab4/sgnp_DEM.tif")
NDVI <- raster("data/lab4/sgnp_NDVI.tif")
habitat_class <- raster("data/lab4/sgnp_habitat.tif")

# Ok, our data are loaded! We can use class() to check the format of our data and crs() to check
#   the coordinate reference system
class(elevation)
crs(elevation)

# Use class() and crs() to check our NDVI and habitat class layers as well. Do the crs's match?

class(NDVI)
crs(NDVI)
class(habitat_class)
crs(habitat_class)

# In addition to these rasters, we will also use some vector data today
# Specifically, we have "shapefiles" for the border of San Guillermo National Park (hereafter
#   SGNP) and for the roads in and near the park
# You may have noticed that there are multiple files associated with each "shapefile". That's
#   because different information about the shapefile is stored separately. You need to download
#   all the associated files to be able to load these shapefiles.
border <- readOGR("data/lab4/sgnp_border.shp")
roads <- readOGR("data/lab4/sgnp_roads.shp")

# Check the classes and crs's of our layers. 
#   How are the classes different? Why are they different classes?
# Do the crs's match our rasters? In order to analyze or visualize multiple layers together,
#   they all need to have the same coordinate reference system.
class(border)
class(roads)
crs(border)
crs(roads)

# We can check on how our layers look by plotting them together
# Unfortunately, ggplot is not great with raster data - it needs to be transformed into a 
#   different file type to plot. So instead we can use the base R function "plot()" to check 
#   out how our layers look.
# Adding "add = TRUE" makes the layers show on the same plot, rather than making new plots for
#   each layer
plot(NDVI)
plot(border,add = TRUE)
plot(roads,add = TRUE)

# What do you see? The x and y axes show our coordinates, the plot shows the variation in NDVI
#   continuously across the study area, and the park border and roads are overlaid
# Also, there's a legend on the right side. The higher the number, the greater value of our
#   layer, which in this case is vegetation greenness. We can see that it looks like the west
#   side of the park is slightly "greener" (higher NDVI) than the east side of the park.

# YOUR TURN!
# Make a plot like the one above, but instead plot elevation with just the border layer on top. 
plot(elevation)
plot(border,add = TRUE)

plot(border)
plot(elevation, add = TRUE)

####** QUESTION 1: ####
# Where is the highest elevation area inside the park? Where is the lowest
#     elevation outside the park? Estimate these locations by looking at the coordinates 
#     on the map. Remeber that when you report coordinates, easting (x axis) comes before 
#     northing (y axis)
#   Export your map for your lab report.

# One incredible thing we can do with an elevation layer is create a whole host of other 
#   topographic layers
# Topographic layers essentially tell us about the shape of the land - how high, steep, and
#   uneven it is.
# The "terrain()" function easily creates these layers for us. Let's start with slope, or the 
#   steepness of the land. We can do this by specifying opt = "slope". We also need to make sure
#   we specify that we want slope in units of degrees, where 0 is flat and 90 is vertical
slope <- terrain(elevation, opt = "slope", unit = "degrees")

plot(slope)
plot(border,add = TRUE)
# You might notice that the steepest areas are actually around the edges of the park, but there
#   are a lot of flat areas (slope close to 0) within the park

# Now we'll make some other topographic layers:
#   Terrain Ruggedness Index (TRI): the mean difference between a cell and the 8 cells touching
#     it. Imagine a 3 x 3 grid, where the central cell is compared to all the adjacent cells.
#   Aspect: which direction the slope is facing. This can be important for thinking about 
#     vegetation. In the northern hemisphere, south-facing slopes get more sun and are therefore
#     often drier, so they can host different plant communities than north-facing slopes.
ruggedness <- terrain(elevation, opt="tri")
aspect <- terrain(elevation, opt="aspect", unit="degrees")
aspect

plot(ruggedness)
plot(border, add = TRUE)

plot(aspect)
plot(border, add = TRUE)


# Use plot() to look at each of your new layers.

#-----------------------------------#
#### EXTRACTING DATA FROM RASTERS AND VECTORS ####

# Oftentimes in habitat analyses, we want to know the habitat features associates with individual
#   locations (e.g. survey plots or animal movement locations)
# To illustrate how to extract habitat data, we can randomly sample points across our study area
#   using the "spsample()" function. You can think of this process as sampling the "available"
#   habitat, like we've talked about for RSFs or SDMs in lecture.
# To start, we can set a common starting point (set.seed(); I've picked 14 for no real reason)
#   so that even though we will all be randomly sampling the landscape, we all get the same 
#   random locations.  
set.seed(14)

# To run spsample(), we tell the function where to sample, how many points to sample, and how
#   to sample
# In the function below, we have told the function to sample within the border of SGNP, 100
#   random locations, randomly sampled
available_points <- spsample(border, n = 100, type = "random")

# We can plot these points using the base R plot() function as we did above. Plot the points
#   on your ruggedness layer with the border of the park
plot(ruggedness)
plot(border,add = TRUE)
plot(available_points,add = TRUE)

# We can also zoom in on the points with our trusty mapview package.
# First, we can turn our border into a line from a polygon so it's easier to see in mapview
border_lines <- as(border, 'SpatialLines')

# We can use mapview to look at just vectors...
mapview(roads, color = "yellow") +
  mapview(border_lines)

# Or also rasters
#     (Don't worry ahout the error message - it's just telling us that it reduced our 
#       resolution to make it easier to plot)
mapview(slope) +
  mapview(border_lines) +
  mapview(roads, color = "yellow") 


# Your turn!
# Use mapview to plot NDVI, roads, the SGNP border, and your new vector of available_points
#   Make available points appear in the color "red"
mapview(NDVI)+
    mapview(roads, color = "yellow")+
    mapview(border_lines)+
    mapview(available_points, color = "red")
    
    
# Zoom in on the northernmost road intersection and find the sideways-hourglass-shaped area with  
#   higher NDVI. This meadow is a primary foraging ground for vicunas and hunting ground for  
#   pumas in the park.
  ####** QUESTION 2:#### 
#About how far away, to the nearest kilometer, is the random point that is 
#     closest to that meadow?
# Export your plot for your lab report

# Now that we have our random (available) points, we can extract the habitat information at
#   each location.
# The raster package has a function called "extract()" which lets us get raster values at
#   individual points. 
# We will use extract by first entering our raster, then our vector (where we want to get
#   habitat values), and finally we'll include df = TRUE so our data exports as a dataframe
# Let's start with slope
slope_values <- extract(slope, available_points, df = TRUE)

# To check out the data, we can use "head()" to look at just the first few lines of our data
#   and see the column names
head(slope_values)

# Now that we know the name of the slope column (which was pulled from the raster itself) to 
#   enter as our "x" value, we can use our trusty ggplot histogram to look at the distribution 
#   of the data.
ggplot(slope_values, aes(x = slope)) +
  geom_histogram()

# You probably notice that most of the slope values are generally concentrated at the lower
#   end of the range of slopes in our sample.
# This indicates that most areas are relatively flat, although there are some rare steep areas

# Your turn!
# Extract values of elevation at our available points and make a histogram of the data.
elev_values <- extract(elevation, available_points, df = TRUE)
head(elev_values)
ggplot(elev_values, aes(x = sgnp_DEM)) +
  geom_histogram()

####* QUESTION 3: ####
# What is the "mode" (i.e. highest frequency) of elevations in our sample? Think
#   through what this distribution of elevations says about the topography of the landscape.
#   Describe what the landscape might look like given the distribution that you found (think
#     in terms of the distribution of mountains, etc).
# Export your plot for your lab report

# So far, we have only extracted habitat variables fro one raster at a time.
# But, we can do them all at once if we "stack" our raster layers together
# The key to a raster stack is that all the layers have to be the same extent (which ours are)
# You can see this if you compare the maximum and minimum coordinates for our layers
extent(elevation)
extent(NDVI)

# To make a stack, all we have to do is use the stack() function with all our rasters inside
habitat_stack <- stack(elevation,slope,ruggedness,aspect,NDVI,habitat_class)

# Now plot your whole stack
plot(habitat_stack)

# Now you can see all your layers. You might notice one we haven't visualized yet: habitat class
# We'll be working with that one soon. In our habitat class layer, 1 = canyons, 2 = meadows,
#   and 3 = plains.

# Just as we used extract() on a single raster, we can use it on the whole stack
habitat_covariates <- extract(habitat_stack, available_points, df = TRUE)  

# Take a look at the structure of your dataframe
head(habitat_covariates)

# We now have an entire dataframe populated with values from our spatial layers at our 
#   random locations. Some of the column names are kind of weird, so we can rename them:
colnames(habitat_covariates) <- c("ID","elevation","slope","ruggedness",
                                  "aspect","NDVI","habitat_class")

# There's one more habitat covariate that we can add with our data, and that's distance
#   to the nearest road.
# We often want to know how close the nearest road is to understand how animals interact
#   with human disturbances. For example, in habitat selection analyses, an animal that is 
#   sensitive to human disturbances might avoid roads, or in otherwards, select for larger
#   distances to the nearest road.
# To add a distance to road covariate, we first need to merge our roads vector layer from many
#   roads into just one road feature. This simplifies our analysis becasue we can calculate 
#   distance to just the closest road, not to every single road. See how the number of road
#   features goes down after we use gLineMerge() to merge all the roads
roads
roads2 <- gLineMerge(roads)
roads2

# The next step is a little messy, since our function to calculate distance saves the output as
#   a matrix (a different kind of object that we are not using in this class). Therefore, we 
#   need to turn it into a dataframe, and then attach it to our covariates dataframe using
#   the "$" operator.
# You might be thinking, what about mutate() for adding new columns?? That's definitly an option
#   too. But since we have a traditional dataframe rather than a tibble, "$" works fine as well.
dist_to_road_matrix <- gDistance(available_points,roads2, byid=TRUE)
dist_to_road_df <- data.frame(dist_to_road = dist_to_road_matrix[1,])
habitat_covariates$dist_to_road <- dist_to_road_df[,1]

# Make sure the column is now part of your habitat covariates dataframe. Our covariate for
#   distance to the nearest road shows up in meters.
head(habitat_covariates)

####* QUESTION 4:#### 
# Make a histogram of distance to road. Are most random locations within 5 km 
#   of a road? Explain what your answer might mean for wildlife in SGNP.
# --> (Ignore the warning. the default binwidth is fine for our purposes)
# Export your plot for your lab report.
#ggplot(dist_to_road_df, aes(x = dist_to_road)) +
 # geom_histogram()

ggplot(habitat_covariates, aes(x = dist_to_road)) +
  geom_histogram()
hist(habitat_covariates$dist_to_road)
#-----------------------------------#
#### RELATIONSHIPS BETWEEN HABITAT COVARIATES ####

# Now that we have a bunch of data on our random locations, we can look for patterns in 
#   the relationships between covariates.

# For example, we can hypothesize that NDVI is function of elevation in the park. We might
#   predict that NDVI decreases as elevation increases if we think that high elevations will 
#   be too cold or dry for plants. Let's  check that relationship out using our ggplot 
#   trendlines from Lab 2.
ggplot(habitat_covariates, aes(x = elevation, y = NDVI))+
  geom_point()+
  geom_smooth(method = "lm")

# Hmm, our scatterplot is pretty messy, but it does seem like there might be a trend 
#   where NDVI actually increases, not decreases (as I predicted), with elevation. Why might 
#   that be?

# Your turn!
####* QUESTION 5:#### 
# Make a hypothesis and prediction about which covariate (aside from habitat class)
#   might predict distance to the nearest road at our random locations. In your prediction, 
#   explain your logic - why did you make that prediction? Make a scatterplot with a trendline
#   to see if there is preliminary evidence supporting your hypothesis. Does your plot 
#   indicate that your hypothesis and prediction might be supported?


## distance to road is on y axis
# H: dist_to_road a function of elevation
# P: as elevation increases, distance to road increases 
# plot
ggplot(habitat_covariates, aes(x = elevation, y = dist_to_road))+
  geom_point()+
  geom_smooth(method = "lm")
# interp: (bc hard to build roads up high), my plot supports my hypothesis

ggplot(habitat_covariates, aes(x = slope, y = dist_to_road))+
  geom_point()+
  geom_smooth(method = "lm")

ggplot(habitat_covariates, aes(x = ruggedness, y = dist_to_road))+
  geom_point()+
  geom_smooth(method = "lm")

# Lastly, let's look at how the habitat covariates differ among habitat types. First we need
#   to make sure our habitat class is a factor, not a number, because it represents discrete
#   classes of habitat (canyons, meadows, and plains)
# First we convert our variable to a factor using the as.factor() function
habitat_covariates$habitat_class <- as.factor(habitat_covariates$habitat_class)

# Then we can look at the names of the levels
levels(habitat_covariates$habitat_class)

# "1", "2", and "3" are not super inuitive! Luckily, we can rename the levels to be more descriptive
levels(habitat_covariates$habitat_class) <- c("canyon","meadow","plains")

# Check out how the habitat class column has changed
head(habitat_covariates)

# Your turn!
####* QUESTION 6:#### 
#Just like in Question 5, write a hypothesis, prediction, and justification 
#   about a coviariate that you think would differ across habitat types. Make a boxplot to 
#   evaluate preliminary support for your hypothesis and prediction (use "fill" to color by 
#   habitat class). Explain why you think the box plot does or does not support your
#   hypothesis and prediction.

# H: I think slope differs across habitat types (habitat type = y)
# P: canyons have steepest slopes, plains have flatest slopes 
# plot
ggplot(data = habitat_covariates, aes(x = habitat_class, y = slope, fill = habitat_class)) + 
  geom_boxplot()
# I: I was right.

ggplot(data = habitat_covariates, aes(x = habitat_class, y = NDVI, fill = habitat_class)) + 
  geom_boxplot()

ggplot(data = habitat_covariates, aes(x = habitat_class, y = elevation, fill = habitat_class)) + 
  geom_boxplot()

#--------------#
#### QUESTIONS FROM LECTURE AND READINGS ####

#** QUESTION 7: Why did the pika SDM discussed in lecture overestimate the distribution of the 
#         species?

#** QUESTION 8: What did guest lecturer Rachel Smith find was the best way to move
#     ecosystem engineer gopher tortoises to prevent translocation failure?

#--------------#
#### CONGRATS! ####
# You've learned how to work with spatial habitat data in R
# Please reach out to your TA, Ellie Bolas (ebolas@ucdavis.edu) for questions about this lab
