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

pvc_1_loc=614
pvc_1_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$pvc_1_loc' - 5) && ($1 < '$pvc_1_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_2_loc=637
pvc_2_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_2_loc' - 5) && ($1 < '$pvc_2_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_3_loc=696
pvc_3_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_3_loc' - 5) && ($1 < '$pvc_3_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_4_loc=843
pvc_4_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_4_loc' - 5) && ($1 < '$pvc_4_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_5_loc=965
pvc_5_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_5_loc' - 5) && ($1 < '$pvc_5_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_6_loc=1103
pvc_6_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_6_loc' - 5) && ($1 < '$pvc_6_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_7_loc=1103
pvc_7_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_7_loc' - 5) && ($1 < '$pvc_7_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_8_loc=1175
pvc_8_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_8_loc' - 5) && ($1 < '$pvc_8_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

pvc_9_loc=1259
pvc_9_height=`awk 'BEGIN { max = -1000 } (($1 > ('$pvc_9_loc' - 5) && ($1 < '$pvc_9_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`


###### Report parameters to command line ##################
echo pvc_1_loc = $pvc_1_loc
echo pvc_1_height = $pvc_1_height

echo pvc_2_loc = $pvc_2_loc
echo pvc_2_height = $pvc_2_height

echo pvc_3_loc = $pvc_3_loc
echo pvc_3_height = $pvc_3_height

echo pvc_4_loc = $pvc_4_loc
echo pvc_4_height = $pvc_4_height

echo pvc_5_loc = $pvc_5_loc
echo pvc_5_height = $pvc_5_height

echo pvc_6_loc = $pvc_6_loc
echo pvc_6_height = $pvc_6_height

echo pvc_7_loc = $pvc_7_loc
echo pvc_7_height = $pvc_7_height

echo pvc_8_loc = $pvc_8_loc
echo pvc_8_height = $pvc_8_height

echo pvc_9_loc = $pvc_9_loc
echo pvc_9_height = $pvc_9_height


########### Enter parameters into fitting dataset #####################

########### Uncomment to use a floating background ###################
#echo grad = $grad > param.txt
#echo int = $yinit >> param.txt

#### Uncomment to use a flat, non moving background  ################
echo grad = 0$'\t'# FIXED > param.txt
echo int = ${ymin}$'\t'# FIXED >> param.txt
#####################################################################

echo pvc_1_loc = ${pvc_1_loc}$'\t'# FIXED >> param.txt
echo pvc_1_height = $pvc_1_height >> param.txt
echo pvc_1_width = -25  >> param.txt

echo pvc_2_loc = ${pvc_2_loc}$'\t'# FIXED >> param.txt
echo pvc_2_height = $pvc_2_height >> param.txt
echo pvc_2_width = -25  >> param.txt

echo pvc_3_loc = ${pvc_3_loc}$'\t'# FIXED >> param.txt
echo pvc_3_height = $pvc_3_height >> param.txt
echo pvc_3_width = -25  >> param.txt

echo pvc_4_loc = ${pvc_4_loc}$'\t'# FIXED >> param.txt
echo pvc_4_height = $pvc_4_height >> param.txt
echo pvc_4_width = -25  >> param.txt

echo pvc_5_loc = ${pvc_5_loc}$'\t'# FIXED >> param.txt
echo pvc_5_height = $pvc_5_height >> param.txt
echo pvc_5_width = -25  >> param.txt

echo pvc_6_loc = ${pvc_6_loc}$'\t'# FIXED >> param.txt
echo pvc_6_height = $pvc_6_height >> param.txt
echo pvc_6_width = -25  >> param.txt

echo pvc_7_loc = ${pvc_7_loc}$'\t'# FIXED >> param.txt
echo pvc_7_height = $pvc_7_height >> param.txt
echo pvc_7_width = -25  >> param.txt

echo pvc_8_loc = ${pvc_8_loc}$'\t'# FIXED >> param.txt
echo pvc_8_height = $pvc_8_height >> param.txt
echo pvc_8_width = -25  >> param.txt

echo pvc_9_loc = ${pvc_9_loc}$'\t'# FIXED >> param.txt
echo pvc_9_height = $pvc_9_height >> param.txt
echo pvc_9_width = -25  >> param.txt



gnuplot $persist<<EOF

# Restrict all peaks to their single defined location, a positive peak height, and a maximum width of 50 wavenumbers
h(x) = sqrt(x**2)
w(x) = 25/pi*(atan(x)+pi/2)+0.1


# Set up fitting peaks
bg(x) = int + grad * x

pvc_1_peak(x) = h(pvc_1_height) * voigt( x - (pvc_1_loc) , w(pvc_1_width) )
pvc_2_peak(x) = h(pvc_2_height) * voigt( x - (pvc_2_loc) , w(pvc_2_width) )
pvc_3_peak(x) = h(pvc_3_height) * voigt( x - (pvc_3_loc) , w(pvc_3_width) )
pvc_4_peak(x) = h(pvc_4_height) * voigt( x - (pvc_4_loc) , w(pvc_4_width) )
pvc_5_peak(x) = h(pvc_5_height) * voigt( x - (pvc_5_loc) , w(pvc_5_width) )
pvc_6_peak(x) = h(pvc_6_height) * voigt( x - (pvc_6_loc) , w(pvc_6_width) )
pvc_7_peak(x) = h(pvc_7_height) * voigt( x - (pvc_7_loc) , w(pvc_7_width) )
pvc_8_peak(x) = h(pvc_8_height) * voigt( x - (pvc_8_loc) , w(pvc_8_width) )
pvc_9_peak(x) = h(pvc_9_height) * voigt( x - (pvc_9_loc) , w(pvc_9_width) )

# Define curve as sum of peaks, with and without baseline
f(x) = pvc_1_peak(x) + pvc_2_peak(x) + pvc_3_peak(x) + pvc_4_peak(x) + pvc_5_peak(x) + pvc_6_peak(x) + pvc_7_peak(x) + pvc_8_peak(x) + pvc_9_peak(x) + bg(x)
p(x) = pvc_1_peak(x) + pvc_2_peak(x) + pvc_3_peak(x) + pvc_4_peak(x) + pvc_5_peak(x) + pvc_6_peak(x) + pvc_7_peak(x) + pvc_8_peak(x) + pvc_9_peak(x)


# Perform the fit
FIT_LIMIT = 1e-6
FIT_MAXITER = 1000
fit f(x) '$1' using 1:2:(1) via 'param.txt'

save fit 'param_after.txt'


############ Output data to text files



set table "data.xy"
plot [x=400:1400] '$1' using 1:2
#set terminal png
#set output "data.png"
#replot

set table "pvc_1_peak.xy"
plot [x=400:1400] pvc_1_peak(x)

set table "pvc_2_peak.xy"
plot [x=400:1400] pvc_2_peak(x)

set table "pvc_3_peak.xy"
plot [x=400:1400] pvc_3_peak(x)

set table "pvc_4_peak.xy"
plot [x=400:1400] pvc_4_peak(x)

set table "pvc_5_peak.xy"
plot [x=400:1400] pvc_5_peak(x)

set table "pvc_6_peak.xy"
plot [x=400:1400] pvc_6_peak(x)

set table "pvc_7_peak.xy"
plot [x=400:1400] pvc_7_peak(x)

set table "pvc_8_peak.xy"
plot [x=400:1400] pvc_8_peak(x)

set table "pvc_9_peak.xy"
plot [x=400:1400] pvc_9_peak(x)

set table "fit.xy"
plot [x=400:1400] f(x)


set table "all_pvc_peaks.xy"
plot [x=400:1400] p(x)

set table "residual.xy"
plot [x=400:1400] '$1' using 1:(\$2 - f(\$1))

set table "background.xy"
plot [x=400:1400] bg(x)

set table "bgremoved.xy"
plot [x=400:1400] '$1' using 1:(\$2 - bg(\$1))

unset table

plot 'data.xy', 'pvc_1_peak.xy' with lines, 'pvc_2_peak.xy' with lines, 'pvc_3_peak.xy' with lines, 'pvc_4_peak.xy' with lines, 'pvc_5_peak.xy' with lines, 'pvc_6_peak.xy' with lines, 'pvc_7_peak.xy' with lines, 'pvc_8_peak.xy' with lines, 'pvc_9_peak.xy' with lines, f(x) with lines


set terminal png
set output "peaks.png"
replot

set output "residual.png"
plot [x=400:1400] 'data.xy', 'residual.xy' with lines

set output "bgremoved.png"
plot [x=400:1400] 'data.xy', 'background.xy' with lines, 'bgremoved.xy' with lines

set output "fit.png"
plot [x=400:1400] 'data.xy', 'fit.xy' with lines, 'residual.xy' with lines

set print 'widths.txt'
pr "pvc_1_width ", w(pvc_1_width)
pr "pvc_2_width ", w(pvc_2_width)
pr "pvc_3 width ", w(pvc_3_width)
pr "pvc_4_width ", w(pvc_4_width)
pr "pvc_5_width ", w(pvc_5_width)
pr "pvc_6_width ", w(pvc_6_width)
pr "pvc_7_width ", w(pvc_7_width)
pr "pvc_8_width ", w(pvc_8_width)
pr "pvc_9_width ", w(pvc_9_width)


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
mv param_after.txt ${nicename}_PVCfit_param.txt

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
#Tidy up

mv *.png jpg
mv *combined.pdf pdf
mv *chart.xy xy_chart_files
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
