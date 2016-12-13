# Description
## 7 options, the order is rigorous
## aedesenv 1 2 3 4 5 {6 7}
1= directory where the file with coordinates and dates are stored
2= file with dates. Dates must be organised in rows as follows
YYYYMMDD
YYYYMMDD
YYYYMMDD

3= file with coordinates in the following format
1|-118.02|34.073
2|-118.02|32.073
.|.......|....

4= time lag in days
5= array with the name of the cliamtic variables to be downloaded. The names must be compliant with DAYMET and PRISM variables. The array must be specyfied as follows:

clm=( tmin tmax ppt vpdmax vpdmin vp prcp )

##How to run it
#Compile GRASS with NETCDF: https://grasswiki.osgeo.org/wiki/Compile_and_Install
#Save aedesenv.sh in grass bash profile
touch ~/.grass.bashrc
echo "source(~/Github/aedesenv/aedesenv.sh)" >> ~/.grass.bashrc

# Define working directory
DIR='/data/matteo/prism_data/'

# File with dates
seq 1 365 | xargs -I {} date -d "2000-01-01 {} days" +%Y-%m-%d > $DIR/dates.txt

# File with coordinates in lat long and | as separator
 yes "1|-118.0275|34.073333" | head -n 365 > $DIR/xy.txt

# Create GRASS location with custom EPSG
grass73 -c EPSG:4263 $HOME/grassdata/latlong/

# Create a mapset, define the climatic variables to download and run the function with custom options
grass73 -c $HOME/grassdata/latlong/mymapset
clm=( tmin tmax ppt vpdmax )
aedesenv $DIR $DIR/xy.txt $DIR/dates.txt 30 clm
