#!/bin/bash

###################################### Description #################################################
#
# This script analyses Raman spectra of p4008, by fitting Voigt distributions to nine peaks, 
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
		echo "name pvc_height carbonate_height dotp_height fluorescence_height" > acombinedresults.txt

		echo "Records deleted!"
	else
		echo "Records saved!"	
	fi
fi


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
charttitle=${nicename//_/}


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
#ymin=`awk 'BEGIN { min = 10000 } { if ( min > $2 ) min = $2 } END { print min }' $1`

##### Alternative: dog-leg background, flat section and sloped section. Uncomment elsewhere too to enable  ###########

xinit=900
xend=1250
yinit3=`awk 'BEGIN { max = 1000000000 } (($1 > ('$xinit' - 200) && ($1 < '$xinit' + 5))) { if ( max > $2 ) max = $2 } END { print max }' $1`
yend3=`awk 'BEGIN { max = 1000000000 } (($1 > ('$xend' - 5) && ($1 < '$xend' + 5))) { if ( max > $2 ) max = $2 } END { print max }' $1`


grad=`echo "scale=2; ($yend3 - $yinit3)/($xend - $xinit)" | bc`
yinit=$yinit3

echo baseline = $yinit
echo slope = $grad
echo corner = $xinit

############################ GNUPlot Curve Fitting  ###########################################

##### PVC #########


pvc_1_loc=614
pvc_2_loc=637
pvc_3_loc=696
pvc_4_loc=843
pvc_5_loc=965
pvc_6_loc=1103
pvc_7_loc=1103
pvc_8_loc=1175
pvc_9_loc=1259

pvc_1_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$pvc_2_loc' - 5) && ($1 < '$pvc_2_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`
pvc_1_scale=0.225764
pvc_2_scale=1
pvc_3_scale=0.799785
pvc_4_scale=0.070374
pvc_5_scale=0.225948
pvc_6_scale=0.197714
pvc_7_scale=0.188872
pvc_8_scale=0.227134
pvc_9_scale=0.342367

pvc_1_width=7.52
pvc_2_width=14.444
pvc_3_width=15.947
pvc_4_width=15.212
pvc_5_width=25
pvc_6_width=25
pvc_7_width=25
pvc_8_width=16.124
pvc_9_width=25



########### Enter parameters into fitting dataset #####################

########### Uncomment the right bits to use a fixed/floating dogleg background ###################
#echo grad = ${grad} > param.txt
echo grad = ${grad}$'\t'# FIXED > param.txt

#echo int = ${yinit} >> param.txt
echo int = ${yinit}$'\t'# FIXED >> param.txt

#echo corner = ${xinit} >> param.txt
echo corner = ${xinit}$'\t'# FIXED >> param.txt

#### Uncomment to use a flat, non moving background  ################
#echo grad = 0$'\t'# FIXED > param.txt
#echo int = ${ymin}$'\t'# FIXED >> param.txt
#####################################################################

echo pvc_height = $pvc_1_height >> param.txt

echo pvc_1_loc = ${pvc_1_loc}$'\t'# FIXED >> param.txt
echo pvc_1_scale = ${pvc_1_scale}$'\t'# FIXED >> param.txt
echo pvc_1_width = ${pvc_1_width}$'\t'# FIXED >> param.txt

echo pvc_2_loc = ${pvc_2_loc}$'\t'# FIXED >> param.txt
echo pvc_2_scale = ${pvc_2_scale}$'\t'# FIXED >> param.txt
echo pvc_2_width = ${pvc_2_width}$'\t'# FIXED >> param.txt

echo pvc_3_loc = ${pvc_3_loc}$'\t'# FIXED >> param.txt
echo pvc_3_scale = ${pvc_3_scale}$'\t'# FIXED >> param.txt
echo pvc_3_width = ${pvc_3_width}$'\t'# FIXED >> param.txt

echo pvc_4_loc = ${pvc_4_loc}$'\t'# FIXED >> param.txt
echo pvc_4_scale = ${pvc_4_scale}$'\t'# FIXED >> param.txt
echo pvc_4_width = ${pvc_4_width}$'\t'# FIXED >> param.txt

echo pvc_5_loc = ${pvc_5_loc}$'\t'# FIXED >> param.txt
echo pvc_5_scale = ${pvc_5_scale}$'\t'# FIXED >> param.txt
echo pvc_5_width = ${pvc_5_width}$'\t'# FIXED >> param.txt

echo pvc_6_loc = ${pvc_6_loc}$'\t'# FIXED >> param.txt
echo pvc_6_scale = ${pvc_6_scale}$'\t'# FIXED >> param.txt
echo pvc_6_width = ${pvc_6_width}$'\t'# FIXED >> param.txt

echo pvc_7_loc = ${pvc_7_loc}$'\t'# FIXED >> param.txt
echo pvc_7_scale = ${pvc_7_scale}$'\t'# FIXED >> param.txt
echo pvc_7_width = ${pvc_7_width}$'\t'# FIXED >> param.txt

echo pvc_8_loc = ${pvc_8_loc}$'\t'# FIXED >> param.txt
echo pvc_8_scale = ${pvc_8_scale}$'\t'# FIXED >> param.txt
echo pvc_8_width = ${pvc_8_width}$'\t'# FIXED >> param.txt

echo pvc_9_loc = ${pvc_9_loc}$'\t'# FIXED >> param.txt
echo pvc_9_scale = ${pvc_9_scale}$'\t'# FIXED >> param.txt
echo pvc_9_width = ${pvc_9_width}$'\t'# FIXED >> param.txt








######## Carbonate ########



carbonate_1_loc=713
carbonate_2_loc=1087

carbonate_1_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$carbonate_2_loc' - 5) && ($1 < '$carbonate_2_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

carbonate_1_scale=0.0400859
carbonate_2_scale=1

carbonate_1_width=5.10
carbonate_2_width=2.64


########### Enter parameters into fitting dataset #####################

echo carbonate_height = $carbonate_1_height >> param.txt

echo carbonate_1_loc = ${carbonate_1_loc}$'\t'# FIXED >> param.txt
echo carbonate_1_scale = ${carbonate_1_scale}$'\t'# FIXED >> param.txt
echo carbonate_1_width = ${carbonate_1_width}$'\t'# FIXED >> param.txt

echo carbonate_2_loc = ${carbonate_2_loc}$'\t'# FIXED >> param.txt
echo carbonate_2_scale = ${carbonate_2_scale}$'\t'# FIXED >> param.txt
echo carbonate_2_width = ${carbonate_2_width}$'\t'# FIXED >> param.txt




######## DOTP #########


dotp_1_loc=636
dotp_2_loc=707
dotp_3_loc=798
dotp_4_loc=837
dotp_5_loc=872
dotp_6_loc=905
dotp_7_loc=963
dotp_8_loc=1048
dotp_9_loc=1066
dotp_10_loc=1106
dotp_11_loc=1117
dotp_12_loc=1174
dotp_13_loc=1280

dotp_1_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$dotp_13_loc' - 5) && ($1 < '$dotp_13_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

dotp_1_scale=0.296348
dotp_2_scale=0.162378
dotp_3_scale=0.092358
dotp_4_scale=0.855067
dotp_5_scale=1
dotp_6_scale=0.32969
dotp_7_scale=0.598019
dotp_8_scale=0.157361
dotp_9_scale=0.171557
dotp_10_scale=0.248966
dotp_11_scale=0.407597
dotp_12_scale=0.391529
dotp_13_scale=1

dotp_1_width=2.443
dotp_2_width=2.883
dotp_3_width=3.671
dotp_4_width=25
dotp_5_width=9.230
dotp_6_width=12.464
dotp_7_width=25
dotp_8_width=5
dotp_9_width=5
dotp_10_width=5
dotp_11_width=5
dotp_12_width=5
dotp_13_width=11.243



########### Enter parameters into fitting dataset #####################

echo dotp_height = $dotp_1_height >> param.txt

echo dotp_1_loc = ${dotp_1_loc}$'\t'# FIXED >> param.txt
echo dotp_1_scale = ${dotp_1_scale}$'\t'# FIXED >> param.txt
echo dotp_1_width = ${dotp_1_width}$'\t'# FIXED >> param.txt

echo dotp_2_loc = ${dotp_2_loc}$'\t'# FIXED >> param.txt
echo dotp_2_scale = ${dotp_2_scale}$'\t'# FIXED >> param.txt
echo dotp_2_width = ${dotp_2_width}$'\t'# FIXED >> param.txt

echo dotp_3_loc = ${dotp_3_loc}$'\t'# FIXED >> param.txt
echo dotp_3_scale = ${dotp_3_scale}$'\t'# FIXED >> param.txt
echo dotp_3_width = ${dotp_3_width}$'\t'# FIXED >> param.txt

echo dotp_4_loc = ${dotp_4_loc}$'\t'# FIXED >> param.txt
echo dotp_4_scale = ${dotp_4_scale}$'\t'# FIXED >> param.txt
echo dotp_4_width = ${dotp_4_width}$'\t'# FIXED >> param.txt

echo dotp_5_loc = ${dotp_5_loc}$'\t'# FIXED >> param.txt
echo dotp_5_scale = ${dotp_5_scale}$'\t'# FIXED >> param.txt
echo dotp_5_width = ${dotp_5_width}$'\t'# FIXED >> param.txt

echo dotp_6_loc = ${dotp_6_loc}$'\t'# FIXED >> param.txt
echo dotp_6_scale = ${dotp_6_scale}$'\t'# FIXED >> param.txt
echo dotp_6_width = ${dotp_6_width}$'\t'# FIXED >> param.txt

echo dotp_7_loc = ${dotp_7_loc}$'\t'# FIXED >> param.txt
echo dotp_7_scale = ${dotp_7_scale}$'\t'# FIXED >> param.txt
echo dotp_7_width = ${dotp_7_width}$'\t'# FIXED >> param.txt

echo dotp_8_loc = ${dotp_8_loc}$'\t'# FIXED >> param.txt
echo dotp_8_scale = ${dotp_8_scale}$'\t'# FIXED >> param.txt
echo dotp_8_width = ${dotp_8_width}$'\t'# FIXED >> param.txt

echo dotp_9_loc = ${dotp_9_loc}$'\t'# FIXED >> param.txt
echo dotp_9_scale = ${dotp_9_scale}$'\t'# FIXED >> param.txt
echo dotp_9_width = ${dotp_9_width}$'\t'# FIXED >> param.txt

echo dotp_10_loc = ${dotp_10_loc}$'\t'# FIXED >> param.txt
echo dotp_10_scale = ${dotp_10_scale}$'\t'# FIXED >> param.txt
echo dotp_10_width = ${dotp_10_width}$'\t'# FIXED >> param.txt

echo dotp_11_loc = ${dotp_11_loc}$'\t'# FIXED >> param.txt
echo dotp_11_scale = ${dotp_11_scale}$'\t'# FIXED >> param.txt
echo dotp_11_width = ${dotp_11_width}$'\t'# FIXED >> param.txt

echo dotp_12_loc = ${dotp_12_loc}$'\t'# FIXED >> param.txt
echo dotp_12_scale = ${dotp_12_scale}$'\t'# FIXED >> param.txt
echo dotp_12_width = ${dotp_12_width}$'\t'# FIXED >> param.txt

echo dotp_13_loc = ${dotp_13_loc}$'\t'# FIXED >> param.txt
echo dotp_13_scale = ${dotp_13_scale}$'\t'# FIXED >> param.txt
echo dotp_13_width = ${dotp_13_width}$'\t'# FIXED >> param.txt



######## Fluorescence #########

fluor_1_height=100
fluor_1_loc=1123
fluor_1_scale=1
fluor_1_width=15

echo fluor_height = $fluor_1_height >> param.txt
echo fluor_1_scale = ${fluor_1_scale}$'\t'# FIXED >> param.txt
echo fluor_1_loc = ${fluor_1_loc}$'\t'# FIXED >> param.txt
echo fluor_1_width = ${fluor_1_width}$'\t'# FIXED >> param.txt


######################################################
######################################################
############### Main GNUPlot program  ################
######################################################

gnuplot $persist<<EOF

load "param.txt"

set print "-"
print "Starting GNUPlot script"
# Restrict all peaks to their single defined location, a positive peak height, and a maximum width of 10 or 50 wavenumbers
pvc_h(x) = pvc_height * x
carbonate_h(x) = carbonate_height * x
dotp_h(x) = dotp_height * x
fluor_h(x) = fluor_height * x

print "Heights defined"
print fluor_height
print fluor_1_scale
print fluor_1_width
print fluor_1_loc
print fluor_h(2)

# Optional restricted bg function
# Restrict corner to the range of [800:1000]
corn(x) = (1000-800)/pi*(atan(x)+pi/2)+800

# Set up background options. Uncomment the right version
#bg(x) = int + grad * x
bg(x) = (x > corner) ? ((grad * (x - corner)) + int) : int
#bg(x) = (x > corn(corner)) ? ((grad * (x - corn(corner))) + int) : int

# Set up fitting curves

pvc_1_peak(x) = pvc_h(pvc_1_scale) * voigt( x - (pvc_1_loc) , (pvc_1_width) )
pvc_2_peak(x) = pvc_h(pvc_2_scale) * voigt( x - (pvc_2_loc) , (pvc_2_width) )
pvc_3_peak(x) = pvc_h(pvc_3_scale) * voigt( x - (pvc_3_loc) , (pvc_3_width) )
pvc_4_peak(x) = pvc_h(pvc_4_scale) * voigt( x - (pvc_4_loc) , (pvc_4_width) )
pvc_5_peak(x) = pvc_h(pvc_5_scale) * voigt( x - (pvc_5_loc) , (pvc_5_width) )
pvc_6_peak(x) = pvc_h(pvc_6_scale) * voigt( x - (pvc_6_loc) , (pvc_6_width) )
pvc_7_peak(x) = pvc_h(pvc_7_scale) * voigt( x - (pvc_7_loc) , (pvc_7_width) )
pvc_8_peak(x) = pvc_h(pvc_8_scale) * voigt( x - (pvc_8_loc) , (pvc_8_width) )
pvc_9_peak(x) = pvc_h(pvc_9_scale) * voigt( x - (pvc_9_loc) , (pvc_9_width) )

carbonate_1_peak(x) = carbonate_h(carbonate_1_scale) * voigt( x - (carbonate_1_loc) , (carbonate_1_width) )
carbonate_2_peak(x) = carbonate_h(carbonate_2_scale) * voigt( x - (carbonate_2_loc) , (carbonate_2_width) )

dotp_1_peak(x) = dotp_h(dotp_1_scale) * voigt( x - (dotp_1_loc) , (dotp_1_width) )
dotp_2_peak(x) = dotp_h(dotp_2_scale) * voigt( x - (dotp_2_loc) , (dotp_2_width) )
dotp_3_peak(x) = dotp_h(dotp_3_scale) * voigt( x - (dotp_3_loc) , (dotp_3_width) )
dotp_4_peak(x) = dotp_h(dotp_4_scale) * voigt( x - (dotp_4_loc) , (dotp_4_width) )
dotp_5_peak(x) = dotp_h(dotp_5_scale) * voigt( x - (dotp_5_loc) , (dotp_5_width) )
dotp_6_peak(x) = dotp_h(dotp_6_scale) * voigt( x - (dotp_6_loc) , (dotp_6_width) )
dotp_7_peak(x) = dotp_h(dotp_7_scale) * voigt( x - (dotp_7_loc) , (dotp_7_width) )
dotp_8_peak(x) = dotp_h(dotp_8_scale) * voigt( x - (dotp_8_loc) , (dotp_8_width) )
dotp_9_peak(x) = dotp_h(dotp_9_scale) * voigt( x - (dotp_9_loc) , (dotp_9_width) )
dotp_10_peak(x) = dotp_h(dotp_10_scale) * voigt( x - (dotp_10_loc) , (dotp_10_width) )
dotp_11_peak(x) = dotp_h(dotp_11_scale) * voigt( x - (dotp_11_loc) , (dotp_11_width) )
dotp_12_peak(x) = dotp_h(dotp_12_scale) * voigt( x - (dotp_12_loc) , (dotp_12_width) )
dotp_13_peak(x) = dotp_h(dotp_13_scale) * voigt( x - (dotp_13_loc) , (dotp_13_width) )

fluor_1_peak(x) = fluor_h(fluor_1_scale) * voigt( x - (fluor_1_loc) , (fluor_1_width) )

print "Peaks defined"

# Define each ingredient as its own function
pvc(x) = pvc_1_peak(x) + pvc_2_peak(x) + pvc_3_peak(x) + pvc_4_peak(x) + pvc_5_peak(x) + pvc_6_peak(x) + pvc_7_peak(x) + pvc_8_peak(x) + pvc_9_peak(x)

carbonate(x) = carbonate_1_peak(x) + carbonate_2_peak(x) 

dotp(x) = dotp_1_peak(x) + dotp_2_peak(x) + dotp_3_peak(x) + dotp_4_peak(x) + dotp_5_peak(x) + dotp_6_peak(x) + dotp_7_peak(x) + dotp_8_peak(x) + dotp_9_peak(x) + dotp_10_peak(x) + dotp_11_peak(x) + dotp_12_peak(x)

fluor(x) = fluor_1_peak(x)

print "Curves defined"

# Define curve as sum of peaks, with and without baseline
p(x) = pvc(x) + carbonate(x) + dotp(x) + fluor(x)
f(x) = p(x) + bg(x)

print "Fit defined"

# Perform the fit
FIT_LIMIT = 1e-20
FIT_MAXITER = 1000
fit [x=600:1150] f(x) '$1' using 1:2 via 'param.txt'

save fit 'param_after.txt'


############ Output data to text files



set table "data.xy"
plot [x=600:1150] '$1' using 1:2

set table "pvc_peaks.xy"
plot [x=600:1150] pvc(x)

set table "carbonate_peaks.xy"
plot [x=600:1150] carbonate(x)

set table "dotp_peaks.xy"
plot [x=600:1150] dotp(x)

set table "fluor_peaks.xy"
plot [x=600:1150] fluor(x)

set table "fit.xy"
plot [x=600:1150] f(x) - bg(x)

set table "residual.xy"
plot [x=600:1150] '$1' using 1:(\$2 - f(\$1))

set table "background.xy"
plot [x=600:1500] bg(x)

set table "bgremoved.xy"
plot [x=600:1500] '$1' using 1:(\$2 - bg(\$1))

unset table

#plot [x=500:1300] 'data.xy', 'background.xy' with lines
plot [x=500:1300] 'data.xy', 'background.xy' with lines, 'pvc_peaks.xy' with lines, 'carbonate_peaks.xy' with lines, 'dotp_peaks.xy' with lines, 'fluor_peaks.xy' with lines, 'fit.xy' with lines


set terminal png
set output "peaks.png"
replot

set output "residual.png"
plot [x=500:1150] 'data.xy', 'residual.xy' with lines

set output "bgremoved.png"
plot [x=500:1150] 'data.xy', 'background.xy' with lines, 'bgremoved.xy' with lines

set output "fit.png"
plot [x=500:1150] 'data.xy', 'fit.xy' with lines, 'residual.xy' with lines

reset

set term post landscape color solid 8
set output 'combined.ps'

# Uncomment the following to line up the axes
# set lmargin 6

#set size ratio 1.5 1.5,1
set origin 0,0

set multiplot title '$charttitle'

set title "Calculation of linear background"

set size 0.33,0.5
set origin 0,0.5
plot [x=500:1300] 'data.xy' title "Data", 'background.xy' title "Background" with lines

set title "Fitting PVC, DOTP and carbonate curves, plus fluorescence"

set size 0.67,1
set origin 0.33,0
plot [x=500:1300] 'bgremoved.xy' title "Data", 'fit.xy' title "Fit" with lines, 'pvc_peaks.xy' title "PVC" with lines, 'dotp_peaks.xy' title "DOTP" with lines, 'carbonate_peaks.xy' title "Carbonate" with lines, 'fluor_peaks.xy' title "Fluorescence" with lines

set title "Residual"

set size 0.33,0.5
set origin 0,0
plot [x=500:1300] 'bgremoved.xy', 'residual.xy' with lines

unset multiplot
reset

EOF

##### Extract heights 

pvc_height=`awk ' $1 ~ /pvc_height/ { print $3 } ' param_after.txt `
carbonate_height=`awk ' $1 ~ /carbonate_height/ { print $3 } ' param_after.txt `
dotp_height=`awk ' $1 ~ /dotp_height/ { print $3 } ' param_after.txt `
fluor_height=`awk ' $1 ~ /fluor_height/ { print $3 } ' param_after.txt `

####### Send heights to summary file
echo $nicename $pvc_height $carbonate_height $dotp_height $fluor_height
echo $nicename $pvc_height $carbonate_height $dotp_height $fluor_height >> acombinedresults.txt

####### Tidy up and output final files
mv peaks.png ${nicename}_all_fixed_peaks.png
mv fit.png ${nicename}_all_fixed_fit.png
mv bgremoved.png ${nicename}_all_fixed_bgremoved.png
mv residual.png ${nicename}_all__fixed_residual.png
mv param_after.txt ${nicename}_all_fixed_param.txt

ps2pdf combined.ps ${nicename}combined.pdf
rm combined.ps

######  Output to list of processed files     ##########
	echo Congratulations, new sample $nicename analysed 
	echo
return

else
	echo $outputresult
	echo Sample already processed
	echo
fi
}


function tidy {

#Tidy up

mv *.png jpg
mv *.xy xy_chart_files
mv *param*.txt param
#rm param*.txt
mv *combined.pdf pdf
rm fit.log
rm *.xy
rm *.plt

#Make combined output
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=allanalysedraman.pdf pdf/*combined.pdf
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
