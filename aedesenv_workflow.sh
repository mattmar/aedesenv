#!/bin/bash
#Bash script to prepare the user to run aedesenv script correctly
#####################################################################

# Define working directory and data file
DIR='/data/matteo/prism_data/'
DATA='aedes_data_downloaded_20170803.txt'

# Remove carriage return in the data file
tr -d '\r' < $DIR/$DATA > $DIR/albo_new.csv

# Change separator in the data file ONLY IF SEPARATOR IS DIFFERENT THAN |
#cat $DIR/albo_new.csv | tr [,] '[|]' > $DIR/albo_new1.csv
mv $DIR/albo_new.csv $DIR/albo_new1.csv

# Remove problematic words in the data file
sed -i -- 's/| Alhambra\"/ Alhambra\"/g' $DIR/albo_new1.csv
sed -i -- 's/| Pomona\"/ Pomona\"/g' $DIR/albo_new1.csv
sed -i -- 's/| West Covina\"/ West Covina\"/g' $DIR/albo_new1.csv

# Extract only id, x and y column from the data file
cut -d"|" -f3,6,7 $DIR/albo_new1.csv > $DIR/albo_coords.csv

# Remove column header from the coords file
tail -n +2 $DIR/albo_coords.csv > $DIR/albo_coords1.csv

# Format data, extract and save them in a separate file
cut -d"|" -f11 $DIR/albo_new1.csv > $DIR/dates.csv
cat $DIR/dates.csv | tr '[/]' '[,]' | tail -n +2 > $DIR/dates1.csv
#Only if data is not already in YYYY-MM-DD
#awk -F, '{ printf "20%s%02d%02d\n", $3,$1,$2}' $DIR/dates1.csv > $DIR/dates_only.csv
mv $DIR/dates1.csv $DIR/dates_only.csv

# Create a test data set for testing purposes
head $DIR/dates_only.csv -n3 > $DIR/dates_t
head $DIR/albo_coords1.csv -n3 > $DIR/coords_t

# Run a test
grass73 -e -c EPSG:4269 $HOME/grassdata/NAD83/
grass73 $HOME/grassdata/NAD83/PRISMtest
array=( tmin tmax ppt vpdmax vpdmin vp prcp )
DIR='/data/matteo/prism_data/'
aedesenv /data/matteo/prism_data/ coords_t dates_t 30 array

# Divide dataset in different segments to speed up the process 
cat $DIR/dates_only.csv | wc -l
split -dl 10000 $DIR/dates_only.csv $DIR/dates_new

# Multiple call of the function aedesenv in different GRASS mapsets
grass73 -c EPSG:4269 $HOME/grassdata/NAD83/PRISMsoul001
array=( tmin tmax ppt vpdmax vpdmin vp prcp )
aedesenv '/data/matteo/prism_data/' albo_coords1.csv dates_new00 1 30 array 0
grass73 -c EPSG:4269 $HOME/grassdata/NAD83/PRISM1soul001
array=( tmin tmax ppt vpdmax vpdmin vp prcp )
aedesenv '/data/matteo/prism_data/' albo_coords1.csv dates_new01 2 30 array 0
grass73 -c EPSG:4269 $HOME/grassdata/NAD83/PRISM2soul001
array=( tmin tmax ppt vpdmax vpdmin vp prcp )
aedesenv '/data/matteo/prism_data/' albo_coords1.csv dates_new02 3 30 array 0
grass73 -c EPSG:4269 $HOME/grassdata/NAD83/PRISM3soul001
array=( tmin tmax ppt vpdmax vpdmin vp prcp )
aedesenv '/data/matteo/prism_data/' albo_coords1.csv dates_new03 4 30 array 1

# Download data for elmonte 
grass73 -c EPSG:4269 $HOME/grassdata/NAD83/elmonteT/
clm=( tmin tmax vpdmax vpdmin vp)
aedesenv '/data/matteo/prism_data/elmonte/' elmonte_coords elmonte_dates 0 clm 1 1
