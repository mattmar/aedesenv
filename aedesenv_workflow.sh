#!/bin/bash
#Bash script to prepare the user to run aedesenv script correctly
#####################################################################

# Define working directory and data file
DIR='/data/matteo/prism_data/'
DATA='aegypti_albopictus_grla_sgva_20110101-20160525.csv'

# Remove carriage return in the data file
tr -d '\r' < $DIR/$DATA > $DIR/albo_new.csv

# Change separator in the data file
cat $DIR/albo_new.csv | tr [,] '[|]' > $DIR/albo_new1.csv

# Remove problematic words in the data file
sed -i -- 's/| Alhambra\"/ Alhambra\"/g' $DIR/albo_new1.csv
sed -i -- 's/| Pomona\"/ Pomona\"/g' $DIR/albo_new1.csv
sed -i -- 's/| West Covina\"/ West Covina\"/g' $DIR/albo_new1.csv

# Extract only id, x and y column from the data file
cut -d"|" -f1,6,7 $DIR/albo_new1.csv > $DIR/albo_coords.csv

# Remove column header from the coords file
tail -n +2 $DIR/albo_coords.csv > $DIR/albo_coords1.csv

# Format data, extract and save them in a separate file
cut -d"|" -f10 $DIR/albo_new1.csv > $DIR/dates.csv
cat $DIR/dates.csv | tr '[/]' '[,]' | tail -n +2 > $DIR/dates1.csv
awk -F, '{ printf "20%s%02d%02d\n", $3,$1,$2}' $DIR/dates1.csv > $DIR/dates_only.csv

# Testing
head $DIR/dates_only.csv -n50 > $DIR/dates_t

# Divide dataset in three segment to speed up the process
split -dl 20000 $DIR/dates_only.csv $DIR/dates_new

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
