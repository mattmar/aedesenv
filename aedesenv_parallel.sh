#!/bin/bash
export s
#Homemade parallelisation
function aedesenv_par ()
{
# Define variables
#s=$1 #number of the job to be defined through qsub
export s
#### 1) PREPARATION
# First we generate a script which contains the command(s) to be executed:
# for convenience, we save the file in our HOME directory
## You may use also a text editor for this, here we use the "echo" shell command
echo "#!/bin/bash
export GRASS_MESSAGE_FORMAT=plain
# Source function 
source /data/home/matteo/GitHub/aedesenv/aedesenv.sh
# set computational region, here: UTM32N coordinates
clm=( tmin tmax ppt vpdmax vpdmin vp prcp )
DIR='/data/home/matteo/prism_data/'
aedesenv /data/home/matteo/prism_data/ albo_coords1.csv dates_new$s 30 clm $s 0" > $HOME/my_grassjob$s.sh

# verify the content of the file
cat $HOME/my_grassjob$s.sh

# make it user executable (this is important, use 'chmod' or via file manager)
chmod u+x $HOME/my_grassjob$s.sh

# create a directory (may be elsewhere) to hold the location used for processing
mkdir -p $HOME/grassdata

# create new temporary location for the job, exit after creation of this location
grass72 -e -c EPSG:4269 $HOME/grassdata/NAD83/PRISM$s

#### 2) USING THE BATCH JOB
# define job file as environmental variable
export GRASS_BATCH_JOB="$HOME/my_grassjob$s.sh"

# now we can use this new location and run the job defined via GRASS_BATCH_JOB
grass72 $HOME/grassdata/NAD83/PRISM$s

#### 3) CLEANUP
# switch back to interactive mode, for the next GRASS GIS session
unset GRASS_BATCH_JOB

# delete temporary location (consider to export results first in your batch job)
#rm -rf $HOME/grassdata/mytemploc_utm32n
}
# Now you can use the resulting SHAPE file "mymap3000.shp" elsewhere.
