## Geolocation analysis with Open Source Tools
## 2016 North American Ornithological Congress, Washington D.C.

## Sponsored by: 

## Migrate Technology LLC.-- www.migratetech.co.uk

## The Cooper Ornithological Society

## The National Science Foundation

### ------------------------------------------------------------

# Tell R where to find files.
setwd("~/Documents/GitHub/NAOC_Geos_2016")

### Read in data

####################################################################
#### Read in data from a .lig file from a Migrate Technology tag ###
####################################################################

library("TwGeos")
d.tag<-readMTlux("data/A2_raw_data.lux")     #read the data into a dataframe called d.lux
head(d.tag)         #view the first few lines
max(d.tag$Light)    #note the maximum value
min(d.tag$Light)    #note the minimum value

d.tag$Light <- log(d.tag$Light) # Log transform for better representation of low light values
head(d.tag)         #view the first few lines
max(d.tag$Light)    #note the maximum value
min(d.tag$Light)    #note the minimum value

## Lets view the data.

## NOTE: The choice of the light threshold and min max light values for plotting will be
## different between tags. The code below is optimized for the .lux file

## You can use the plot function to look at small pieces of the dataset.
plot(d.tag$Date[3000:5000], d.tag$Light[3000:5000], type = "o", pch = 16, cex = 0.5)

## For a more complete view use the lightimage() function in the BAStag package.
## In this graph each vertical line is a day (24 hours) of data.
## Low light levels are shown in dark shades of gray and high levels are light shades.
## The offset value of 17 adjusts the y-axis to put night (dark shades) in the middle.
lightImage(d.tag, offset = 12, zlim = c(0, 12), dt = 120) 
## Note the dark spots near the end of the dataset. These are probably associated with nesting (in a dark box).

## Options for editing twilights.
##   preprocessLight() from the BAStag package
##   twilightCalc() from the GeoLight package
##   TAGS - a web-based editor

## Establish a threshold for determining twilights (what light value separates day and night?)
## The best choice is the lowest value that is consistently above any noise in the nighttime light levels
## For many Migrate Technology data sets, 0.5 is a good threshold (on log-transformed lux values)
threshold = 0.5

## preprocessLight() is an interactive function for editing light data and deriving twilights
## Unfortunately, it does not work with an RStudio web interface (i.e. a virtual machine)
## Note: if you are working on a Mac set gr.Device to X11 and install Quartz first (https://www.xquartz.org)
## See help file for details on the interactive process.

## for pc
twl <- preprocessLight(d.tag, threshold = threshold, offset = 18, lmax = 12, gr.Device = "default")

## for mac
twl <- preprocessLight(d.tag, threshold = threshold, offset = 18, lmax = 12, gr.Device = "x11")

## The findTwilights function in TwGeos package also allows to just find the twiligth times (without individual insepction and without editing)
## A so called 'seed' (see help file: ?findTwilights()), date and time at night is required

plot(d.tag$Date[3000:5000], d.tag$Light[3000:5000], type = "o", pch = 16, cex = 0.5)
seed <- as.POSIXct(locator(n=1)$x, origin  = "1970-01-01", tz = "GMT")
twl  <- findTwilights(d.tag, threshold, include = seed)

lightImage(d.tag, offset = 12, zlim = c(0, 12), dt = 120)
tsimagePoints(twl$Twilight, offset = 12, pch = 16, cex = 0.5,
              col = ifelse(twl$Rise, "dodgerblue", "firebrick"))

## The function twilightEdit may help to find outliers and either remove or edit them according to one rule:
## rule: if a twilight time is 'outlier.mins' (e.g. 45) minutes different to its sourrounding twilight times, 
## defined by 'window' - the number of sourrounding twilight times (e.g. 4), and the sourrounding twiligth times 
## are within 'stationary.mins' (e.g. 15) minutes, the outlayer will be moved in between the two neighboring twilights
## or deleted if the sourrounding twilights are > 'stationary.mins'.

## This allows fast and easily reproducable definition of twilight times.
twl <- twilightEdit(twl, window = 4, outlier.mins = 45, stationary.mins = 25, plot = T)

  ## Plot: grey points are either deleted (crossed) or edited (moved) twiligth times

## Plot the edited data on ligthImage
lightImage(d.tag, offset = 12, zlim = c(0, 12), dt = 120)
tsimagePoints(twl$Twilight[!twl$Deleted], offset = 12, pch = 16, cex = 0.5,
              col = ifelse(twl$Rise[!twl$Deleted], "dodgerblue", "firebrick"))


## adjust twilight data since BAS tags record maximum values over time (in this case every 2 minutes)
twl <- twilightAdjust(twl, 2*60)


## You can use the twilightCalc() function in GeoLight to go through the data a bit at a time.
## This can take a few minutes.
## twilightCalc tries to choose the most likely twilights, but it can be wrong.
## If you want to trust the function and not look at the data (not recommended) the set "ask" to "FALSE."
library(GeoLight)    #load the GeoLight package
twl <- findTwilights(datetime = d.tag$Date, light = d.tag$Light,
                    LightThreshold = threshold, ask = T, preSelection = TRUE, 
                    nsee = 5000, allTwilights = F)

## The allTwilight=TRUE option causes the function to save two dataframes in a list
## The first dataframe  ("allTwilights") contains all the light data with twilight instances added in (Useful for FlightR and SGAT)
## The second ("consecTwilights") is just the twilight events and is useful for GeoLight

#Let's truncate the data to cut off the messy data at the end
#and save it to a csv file for later use.
datetime <- as.POSIXct(twl$tFirst, "UTC")  #Get datestamps into a format R can work with
twl <- twl[datetime < as.POSIXct("2012-05-20", "UTC"),] 
write.csv(twl, file = "data/749_twl.csv", quote = FALSE, row.names = FALSE)


## You can also use the online data editing tools in TAGS
## at tags.animalmigration.org
## To pre- process the dataset with TAGS it may be necessary 
## to compress the data (i.e. remove repeated light levels)
d.lig.TAGS <- export2TAGS(d.tag, path = "~/Desktop")


## Process the data with TAGS and read it back into R.

twl <- read.csv("data/749_TAGS_twl.txt")
## This data set was only edited up until April 20, 2012. 
## (By then the birds were back on the breeding grounds and going in and out of next boxes)
## So lets remove the unedited data (everything later than April 20).
datetime <- strptime(twl$datetime, "%Y-%m-%dT%H:%M:%OSZ", "GMT")     #Get datestamps into a format R can work with
twl <- twl[datetime < as.POSIXct("2012-05-20", "GMT"),]              #Remove data logged after Apr 20, 2012
## These data are in TAGS format, which FlightR can work with. So lets save them.
write.csv(twl, file = "data/749_twl_FlightR.csv", quote = FALSE, row.names = FALSE)




####################################################################
#### Read in data from a .lig file #################################
####################################################################

## Preprocessing a .lig file

## First reduce the data down to just datestamps and light levels
## use the readLig function in BAStag to read in the data

library("TwGeos")                                 #load the TwGeos package
d.tag <- readLig("data/749_000.lig", skip = 0)    #read the data into a dataframe called d.tag
d.tag <- subset(d.tag,select=c("Date","Light"))   #reduce the dataframe to just Date and Light

## Lets view the data.

## NOTE: The choice of the light threshold and min max light values for plotting will be
## different between tags. The code below is optimized for the .lux file

## You can use the plot function to look at small pieces of the dataset.
plot(d.tag$Date[3000:5000], d.tag$Light[3000:5000], type = "o", pch = 16, cex = 0.5)

## For a more complete view use the lightimage() function in the BAStag package.
## In this graph each vertical line is a day (24 hours) of data.
## Low light levels are shown in dark shades of gray and high levels are light shades.
## The offset value of 17 adjusts the y-axis to put night (dark shades) in the middle.
lightImage(d.tag, offset = 18, zlim = c(0, 12), dt = 120) 
## Note the dark spots near the end of the dataset. These are probably associated with nesting (in a dark box).

## Options for editing twilights.
##   preprocessLight() from the BAStag package
##   twilightCalc() from the GeoLight package
##   TAGS - a web-based editor

## Establish a threshold for determining twilights (what light value separates day and night?)
## The best choice is the lowest value that is consistently above any noise in the nighttime light levels
## For many BAS data sets, 2.5 is a good threshold
threshold = 2.5

## preprocessLight() is an interactive function for editing light data and deriving twilights
## Unfortunately, it does not work with an RStudio web interface (i.e. a virtual machine)
## Note: if you are working on a Mac set gr.Device to X11 and install Quartz first (https://www.xquartz.org)
## See help file for details on the interactive process.

## for pc
twl <- preprocessLight(d.tag, threshold = threshold, offset = 18, lmax = 12, gr.Device = "default")

## for mac
twl <- preprocessLight(d.tag, threshold = threshold, offset = 18, lmax = 12, gr.Device = "x11")






