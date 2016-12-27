#!/bin/bash
######################################################################################
# Bash function to download PRISM and DAYMET data using a date text file as reference.
# A time lag can be decided
# $1 directory; $2 dates input (text file YYYYMMDD dates); $3 coords filealbo_coords1.csv; $4 seg number; $5 lag=30
# This function must be load in .grass.bashrc, then run in GRASS 
# GRASS must be compiled with --with-netcdf
# source function.sh
######################################################################################

function aedesenv ()
{

    # Define variables
    DIR=$1 # directories where $2,$3 are stored and where the output files are stored
    COORDS=$2 # input coords
    DATES=$3 # input dates
    LAG=${4-1} # time lag to evaluate
    SEG=${6:-1} # name of the file segment
    MERGE=${7:-1} # If MERGE == 1 than merge outputs
    #### To make an array a local variable ####
    # http://www.unix.com/shell-programming-and-scripting/61370-bash-ksh-passing-array-function.html
    # Setting the shell's Internal Field Separator to null
    OLD_IFS=$IFS
    IFS=''
    # Create a string containing "$5[*]"
    local VARS1="$5[*]"
    
    # Assign loc_array value to ${$5[*]} using indirect variable reference
    local VARS=(${!VARS1}) # considered climatic variables    
    
    # Resetting IFS to default
    IFS=$OLD_IFS

    ##########################################
    MSC=`g.gisenv MAPSET` # GRASS mapset name
    g.gisenv set="GRASS_VERBOSE=0" # GRASS low volume
    e=1

    # Import the file with coordinates (lat long)
    v.in.ascii format=point in=$DIR/$COORDS out=coords sep='|' columns="idd varchar, x double precision, y double precision" x=2  y=3 --o
    
    # Loop over each date in the input file 
    while ((ee++)); read DATE || [[ -n "$DATE" ]]
    do
    grassmaps=`g.list rast`; # save raster map list
    #echo $ee
    v.extract in=coords cats=$ee out=tempcoords$SEG --o # extract a single point
    X=`v.db.select tempcoords$SEG | cut -d"|" -f3| tail -1`; X=`printf %.2f $X`
    X1=$(echo $X - 0.1 | bc )
    Y=`v.db.select tempcoords$SEG | cut -d"|" -f4| tail -1`; Y=`printf %.2f $Y`
    Y1=$(echo $Y - 0.1 | bc )
    g.region vector=tempcoords$SEG res=0:00:30 # set the region on DAYMET resolution
    
    for VAR in "${VARS[@]}" # variable sequence
    do
        echo "###### Climatic variable $VAR ######"
        for ((ii=0;ii<=$LAG;ii++)) # time lag sequence
        do
            iii=`printf "%02d" $ii` # while index
            NEWDATE=`date -d "$DATE-$ii days" '+%Y%m%d'` # date with a lag
            YEAR=${NEWDATE:0:4};MONTH=${NEWDATE:4:2};DAY=${NEWDATE:6:4} # Extract year, month and day
            echo "###### Working on date $ee, $DATE - time lag $ii/$LAG days #####"
            
            if [[ $grassmaps != *"P"$VAR"_"$NEWDATE""* ]] || [[ $grassmaps != *"D"$VAR"_"$NEWDAss"_"$X"_"$Y""* ]] 
            then # check if map is already in the grass mapset
            mkdir -p /tmp/$VAR"_"$NEWDATE"_"$SEG
            
            if [ "$VAR" == "vpdmax" ] || [ "$VAR" == "vpdmin" ]; then S="PF"; elif [ "$VAR" == "ppt" ]; then S="PH"; elif [ "$VAR" == "tmin" ] || [ "$VAR" == "tmax" ] || [ "$VAR" == "tmean" ]; then S="PDH"; elif [ "$VAR" == "prcp" ] || [ "$VAR" == "vp" ]; then S="DH"; fi
                if [ "$S" == "PF" ] 
                then # FTP
                echo "###### Downloading PRISM data FTP ######"
                wget --limit-rate=3m -O /tmp/$VAR"_"$NEWDATE"_"$SEG/Pfile"_"$VAR"_"$NEWDATE".zip" "ftp://anonymous@prism.oregonstate.edu/daily/"$VAR"/"${NEWDATE:0:4}"/PRISM_"$VAR"_stable_4kmD1_"$NEWDATE"_bil.zip" &>>/tmp/wget_log$SEG.txt
            elif [ "$S" == "PH" ]
                    then # HTTP
                    echo "###### Downloading PRISM data HTTP ######"
                    wget --limit-rate=3m -O /tmp/$VAR"_"$NEWDATE"_"$SEG/Pfile"_"$VAR"_"$NEWDATE".zip" "http://services.nacse.org/prism/data/public/4km/$VAR/$NEWDATE" &>>/tmp/wget_log$SEG.txt
                elif [ "$S" == "PDH" ]
                    then # HTTP
                    echo "###### Downloading PRISM data HTTP ######"
                    wget --limit-rate=3m -O /tmp/$VAR"_"$NEWDATE"_"$SEG/Pfile"_"$VAR"_"$NEWDATE".zip" "http://services.nacse.org/prism/data/public/4km/$VAR/$NEWDATE" &>>/tmp/wget_log$SEG.txt
                    echo "###### Downloading DAYMET data ######"
                    wget --limit-rate=3m -O /tmp/$VAR"_"$NEWDATE"_"$SEG/Dfile"_"$VAR"_"$NEWDATE".nc4" "http://thredds.daac.ornl.gov/thredds/ncss/ornldaac/1328/${YEAR}/daymet_v3_${VAR}_${YEAR}_na.nc4?&var=${VAR}&north=${Y}&west=${X1}&east=${X}&south=${Y1}&disableProjSubset=on&horizStride=1&time_start=${YEAR}-${MONTH}-${DAY}T12:00:00Z&time_end=${YEAR}-${MONTH}-${DAY}T12:00:00Z&timeStride=1&accept=netcdf4" &>>/tmp/wget_log$SEG.txt
                elif [ "$S" == "DH" ]
                    then # HTTP
                    echo "###### Downloading DAYMET data HTTP ######"
                    wget --limit-rate=3m -O /tmp/$VAR"_"$NEWDATE"_"$SEG/Dfile"_"$VAR"_"$NEWDATE".nc4" "http://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/1328/${YEAR}/daymet_v3_${VAR}_${YEAR}_na.nc4?var=lat&var=lon&var=${VAR}&north=${Y}&west=${X1}&east=${X}&south=${Y1}&horizStride=1&time_start=${YEAR}-${MONTH}-${DAY}T12:00:00Z&time_end=${YEAR}-${MONTH}-${DAY}T12:00:00Z&timeStride=1&accept=netcdf4" &>>/tmp/wget_log$SEG.txt
                else
                 echo "Wrong variable name!"
            fi #fish data from webservice or ftp according to the variables
            if [[ -f /tmp/$VAR"_"$NEWDATE"_"$SEG/Pfile"_"$VAR"_"$NEWDATE".zip" ]] 
                    then # Decompress the archive
                    unzip -qq -o -d /tmp/$VAR"_"$NEWDATE"_"$SEG/ /tmp/$VAR"_"$NEWDATE"_"$SEG/Pfile"_"$VAR"_"$NEWDATE 
                    r.import in=` ls /tmp/$VAR"_"$NEWDATE"_"$SEG/"PRISM_"$VAR"_stable_4kmD"*"_"$NEWDATE"_bil.bil"` out=P$VAR"_"$NEWDATE
                fi
                if [[ -f /tmp/$VAR"_"$NEWDATE"_"$SEG/Dfile"_"$VAR"_"$NEWDATE".nc4" ]] 
                    then
                    #echo "$VAR"_"$NEWDATE"
                    gdal_translate -of GTiff netCDF:\"`ls /tmp/$VAR"_"$NEWDATE"_"$SEG/Dfile"_"$VAR"_"$NEWDATE.*`\":$VAR /tmp/$VAR"_"$NEWDATE"_"$SEG/Dfile"_"$VAR"_"$NEWDATE".tif"
                    r.import input=/tmp/$VAR"_"$NEWDATE"_"$SEG/Dfile"_"$VAR"_"$NEWDATE.tif out=D$VAR"_"$NEWDATE"_"$X"_"$Y --o
                fi
            rm /tmp/$VAR"_"$NEWDATE"_"$SEG/ -rf #remove data folder
        else 
            echo -e "\n ## Map already in GRASSDATA, skipping download ## \n"
        fi
             # Add columns according to the database
             if [ "$VAR" == "ppt" ] || [ "$VAR" == "vpdmax" ] || [ "$VAR" == "vpdmin" ]
                then #PRISM
                v.db.addcolumn map=tempcoords$SEG columns=P"$VAR"_lag_"$iii double precision" 
            elif [ "$VAR" == "prcp" ] || [ "$VAR" == "vp" ]
                then #DAYMET
                v.db.addcolumn map=tempcoords$SEG columns=D"$VAR"_lag_"$iii double precision" 
            elif [ "$VAR" == "tmin" ] || [ "$VAR" == "tmax" ] 
                then #PRISM and DAYMET
                v.db.addcolumn map=tempcoords$SEG columns=P"$VAR"_lag_"$iii double precision" 
                v.db.addcolumn map=tempcoords$SEG columns=D"$VAR"_lag_"$iii double precision" 
            fi
             # Check if map exists and sample it at coords
             g.findfile element=cell file="P$VAR"_"$NEWDATE" mapset=$MSC > /dev/null
             if [ $? -eq 0 ] 
                then
                v.what.rast map=tempcoords$SEG raster=P$VAR"_"$NEWDATE column=P$VAR"_lag_"$iii # extract the value at coords x,y
            fi
            g.findfile element=cell file="D$VAR"_"$NEWDATE"_"$X"_"$Y" mapset=$MSC > /dev/null
            if [ $? -eq 0 ]
                then
                v.what.rast map=tempcoords$SEG raster=D$VAR"_"$NEWDATE"_"$X"_"$Y column=D$VAR"_lag_"$iii
            fi
        done # End time lags
    done # End variables
    v.db.select tempcoords$SEG > $DIR/tempoutput$SEG.txt # Export the database 
    tail -n1 $DIR/tempoutput$SEG.txt >> $DIR/output$SEG.txt # Save values in a text document
done < $DIR/$DATES 2>&1 | tee /tmp/aedesenv_std_error_log$SEG.log # Redirect the standard error to a log file
# Add header to the final output
head -n1 $DIR/tempoutput$SEG.txt > $DIR/header$SEG.txt && cat $DIR/output$SEG.txt >> $DIR/header$SEG.txt && mv $DIR/header$SEG.txt $DIR/final_output$SEG.txt
if [ $MERGE -eq 1 ]
    then 
# Merge the three files in one output file
cat $DIR/final_output*.txt > $DIR/outfile.txt
sed -i '/^cat/d' $DIR/outfile.txt #Remove rows that begin with cat
sed -i -e "1i\ `head -n1 $DIR/tempoutput$SEG.txt`" $DIR/outfile.txt #Add header
# Cleaning
rm $DIR/final_output*.txt $DIR/tempoutput*.txt
fi
}