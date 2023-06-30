#!/bin/bash

###################################### Description #################################################
#
# This script analyses Raman spectra of PVC, by fitting Voigt distributions to nine peaks, 
# as well as correcting for a linear background.
# The input is taken from a series of text files as produced by a Renishaw Raman spectrometer using
# Wire software. Proprietary .wxd files can be converted into two-column space-separated text files 
# (wavenumber intensity) using the "Wire Batch Convert" program. The text files should be contained 
# within one single folder, or grouped into sub-folders.
#
# The script outputs three graphs, containing the raw spectra with linear background identified,
# raw spectra with overalll fit superimposed and a residual shown, and the spectra following the fitting,
# showing the fitted peaks after the background has been removed. The fitting parameters (peak locations,
# amplitudes, widths and areas, as well as characteristic area ratios) are outputted to a summary file 
# for further analysis
#
# The script requires the following software to run:
# - A Unix / Linux environment (tested with Ubuntu)
# - Bash terminal program
# - Dos2unix text file conversion software
# - Gnuplot graphing software. 
#     - Version 4.5 or above is required
# - Ghostscript PostScript and PDF manipulation software
# - The script "prepraman.sh" should be run before the first files in a given folder are analysed.
#   This script creates folders and initiates some datafiles for the subsequent fits
# - Both this fitting script and "prepraman.sh" require permission to execute as programs
#
# The script executes from the command line, in the form
# $ sparkesfitraman.sh [options] [input files]
#
# The options are
# -q Quiet mode - graphs appear on screen but immediately disappear
# -d Delete - removes previous files from "acombinedresults.txt"
# -t[value] Threshold - the signal-to-noise ratio below which a peak is too noisy to process
#
# Input files can be listed individually, or selected all at once using a wildcard (e.g. *.txt)
# After analysis the results are written to a file entitled "acombinedresults.txt". Any filename
# already in this file will be ignored and not re-fitted, hence the delete option.
#
# Example code to prepare for and then analyse all samples with "taiwan" in the file name:
# $ prepraman.sh 
# $ sparkesfitraman.sh -d -q -t 5 taiwan*.txt
#
#
##################################################################################################


# First the options are collected


quiet=false
persist=-persist
delete=false
delans=n

while getopts 'dq' option
do
case $option in
	d) delete=true;;
	q) quiet=true;;

esac
done
shift $(($OPTIND - 1))

if [ "$delete" = "true" ] ; then
	echo "Really delete all records? (y/n)"
	read delans
	if [ "$delans" = "y" ] ; then
		echo "name" > acombinedresults.txt

		echo "Records deleted!"
	else
		echo "Records saved!"	
	fi
fi

echo "This file reports in FWHM" >> acombinedresults.txt

echo Quiet? $quiet

if [ "$quiet" = "true" ] ; then
persist=""
fi

echo $#
echo $@


########  This is the start of the main function    #################

function processsample {
#Prepare input file
filename=$1
dos2unix $filename
nicename=${filename%\.*}
echo $nicename


###### Test whether the sample has been processed before    ###############
outputresult=`awk 'match($1, '/$nicename/')' acombinedresults.txt`
if [ "$outputresult" = "" ]; 
then 

########### If a new sample, then go ahead and fit it  ##############

rm fit.log

########################    Read basic spectrum parameters     ##########################
yinit2=`awk 'END {print $2}' $1`
yend=`awk 'NR==1 {print $2}' $1`
xinit=`awk 'END {print $1}' $1`
xend=`awk 'NR==1 {print $1}' $1`

grad=`echo "scale=2; ($yend - $yinit2)/($xend - $xinit)" | bc`

yinit=`echo "scale=2; $yinit2 - ($grad * $xinit)" | bc`

echo background = $grad x + $yinit

##### Alternative: flat background, non movable. Uncomment elsewhere too to enable  ###########
ymin=`awk 'BEGIN { min = 10000 } { if ( min > $2 ) min = $2 } END { print min }' $1`






############################ GNUPlot Curve Fitting  ###########################################

carbonate_1_loc=713
carbonate_1_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$pvc_1_loc' - 5) && ($1 < '$pvc_1_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

carbonate_2_loc=1087
carbonate_2_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_2_loc' - 5) && ($1 < '$pvc_2_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`


###### Report parameters to command line ##################
echo carbonate_1_loc = $carbonate_1_loc
echo carbonate_1_height = $carbonate_1_height

echo carbonate_2_loc = $carbonate_2_loc
echo carbonate_2_height = $carbonate_2_height



########### Enter parameters into fitting dataset #####################

########### Uncomment to use a floating background ###################
#echo grad = $grad > param.txt
#echo int = $yinit >> param.txt

#### Uncomment to use a flat, non moving background  ################
echo grad = 0$'\t'# FIXED > param.txt
echo int = ${ymin}$'\t'# FIXED >> param.txt
#####################################################################

echo carbonate_1_loc = ${carbonate_1_loc}$'\t'# FIXED >> param.txt
echo carbonate_1_height = $carbonate_1_height >> param.txt
echo carbonate_1_width = -25  >> param.txt

echo carbonate_2_loc = ${carbonate_2_loc}$'\t'# FIXED >> param.txt
echo carbonate_2_height = $carbonate_2_height >> param.txt
echo carbonate_2_width = -25  >> param.txt

gnuplot $persist<<EOF

# Restrict all peaks to their single defined location, a positive peak height, and a maximum width of 10 wavenumbers
h(x) = sqrt(x**2)
w(x) = 5/pi*(atan(x)+pi/2)+0.1


# Set up fitting peaks
bg(x) = int + grad * x

carbonate_1_peak(x) = h(carbonate_1_height) * voigt( x - (carbonate_1_loc) , w(carbonate_1_width) )
carbonate_2_peak(x) = h(carbonate_2_height) * voigt( x - (carbonate_2_loc) , w(carbonate_2_width) )

# Define curve as sum of peaks, with and without baseline
f(x) = carbonate_1_peak(x) + carbonate_2_peak(x) + bg(x)
p(x) = carbonate_1_peak(x) + carbonate_2_peak(x) 


# Perform the fit
FIT_LIMIT = 1e-6
FIT_MAXITER = 1000
fit f(x) '$1' using 1:2:(1) via 'param.txt'

save fit 'param_after.txt'


############ Output data to text files



set table "data.xy"
plot [x=500:1290] '$1' using 1:2
#set terminal png
#set output "data.png"
#replot

set table "carbonate_1_peak.xy"
plot [x=500:1290] carbonate_1_peak(x)

set table "carbonate_2_peak.xy"
plot [x=500:1290] carbonate_2_peak(x)

set table "fit.xy"
plot [x=500:1290] f(x)

set table "all_carbonate_peaks.xy"
plot [x=500:1290] p(x)

set table "residual.xy"
plot [x=500:1290] '$1' using 1:(\$2 - f(\$1))

set table "background.xy"
plot [x=500:1290] bg(x)

set table "bgremoved.xy"
plot [x=500:1290] '$1' using 1:(\$2 - bg(\$1))

unset table

plot 'data.xy', 'carbonate_1_peak.xy' with lines, 'carbonate_2_peak.xy' with lines, 'fit.xy' with lines, 'background.xy' with lines

set terminal png
set output "peaks.png"
replot

set output "residual.png"
plot 'data.xy', 'residual.xy' with lines

set output "bgremoved.png"
plot 'data.xy', 'background.xy' with lines, 'bgremoved.xy' with lines

set output "fit.png"
plot 'data.xy', 'fit.xy' with lines, 'residual.xy' with lines


set print 'widths.txt'
pr "carbonate_1_width ", w(carbonate_1_width)
pr "carbonate_2_width ", w(carbonate_2_width)

EOF


##### Remove scientific notation
#sed 's/e-/\*10\^-/' param_after.txt > ${1}_param_after.txt

##### Find final parameters ######
#pvc_1_loc=`awk ' $1 ~ /pvc_1_loc/ { print sqrt( $2 ^ 2 ) } ' param3.txt `
#pvc_1_height=`awk ' $1 ~ /pvc_1_height/ { print $2 } ' param3.txt `
#pvc_1_width=`awk ' $1 ~ /pvc_1_width/ { print $2 } ' param3.txt `
#pvc_1_area=`awk ' ( NR > 4) $1 ~ /pvc_1_area/ { print $2 } ' param3.txt `


#ps2pdf combined.ps ${nicename}combined.pdf
#rm combined.ps

mv peaks.png ${nicename}peaks.png
mv fit.png ${nicename}fit.png
mv bgremoved.png ${nicename}bgremoved.png
mv residual.png ${nicename}residual.png
mv param_after.txt ${nicename}_carbonatefit_param.txt


######  Output to list of processed files     ##########
echo $nicename >> acombinedresults.txt

	echo Congratulations, new sample analysed 
	echo
return

else
	echo $outputresult
	echo Sample already processed
	echo
fi
}


function tidy {

echo foo
Tidy up

mv *.png jpg
mv *combined.pdf pdf
mv *.xy xy_chart_files
rm param*.txt
rm fit.log
rm *.xy
rm *.plt

#Make combined output
#gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=allanalysedraman.pdf pdf/*combined.pdf
}



while :
do
echo $# to go
if [[ "$#" > "0" ]]
then 

echo $# files left to process
processsample $1
shift

else 

tidy

exit
fi
done
