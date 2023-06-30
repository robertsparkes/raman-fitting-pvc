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

p4008_1_loc=560
p4008_1_height=`awk 'BEGIN { max = -1000000000 } (($1 > ('$p4008_1_loc' - 5) && ($1 < '$p4008_1_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

p4008_2_loc=890
p4008_2_height=`awk 'BEGIN { max = -1000 } (($1 > ('$p4008_2_loc' - 5) && ($1 < '$p4008_2_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

p4008_3_loc=957
p4008_3_height=`awk 'BEGIN { max = -1000 } (($1 > ('$p4008_3_loc' - 5) && ($1 < '$p4008_3_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

p4008_4_loc=1063
p4008_4_height=`awk 'BEGIN { max = -1000 } (($1 > ('$p4008_3_loc' - 5) && ($1 < '$p4008_3_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

p4008_5_loc=1101
p4008_5_height=`awk 'BEGIN { max = -1000 } (($1 > ('$p4008_5_loc' - 5) && ($1 < '$p4008_45loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

p4008_6_loc=1130
p4008_6_height=`awk 'BEGIN { max = -1000 } (($1 > ('$p4008_6_loc' - 5) && ($1 < '$p4008_6_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

p4008_7_loc=1175
p4008_7_height=`awk 'BEGIN { max = -1000 } (($1 > ('$p4008_7_loc' - 5) && ($1 < '$p4008_7_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`

p4008_8_loc=1296
p4008_8_height=`awk 'BEGIN { max = -1000 } (($1 > ('$p4008_8_loc' - 5) && ($1 < '$p4008_8_loc' + 5))) { if ( max < $2 ) max = $2 } END { print max }' $1`


###### Report parameters to command line ##################
echo p4008_1_loc = $p4008_1_loc
echo p4008_1_height = $p4008_1_height

echo p4008_2_loc = $p4008_2_loc
echo p4008_2_height = $p4008_2_height

echo p4008_3_loc = $p4008_3_loc
echo p4008_3_height = $p4008_3_height

echo p4008_4_loc = $p4008_4_loc
echo p4008_4_height = $p4008_4_height

echo p4008_5_loc = $p4008_5_loc
echo p4008_5_height = $p4008_5_height

echo p4008_6_loc = $p4008_6_loc
echo p4008_6_height = $p4008_6_height

echo p4008_7_loc = $p4008_7_loc
echo p4008_7_height = $p4008_7_height

echo p4008_8_loc = $p4008_8_loc
echo p4008_8_height = $p4008_8_height

########### Enter parameters into fitting dataset #####################

########### Uncomment to use a floating background ###################
#echo grad = $grad > param.txt
#echo int = $yinit >> param.txt

#### Uncomment to use a flat, non moving background  ################
echo grad = 0$'\t'# FIXED > param.txt
echo int = ${ymin}$'\t'# FIXED >> param.txt
#####################################################################

echo p4008_1_loc = ${p4008_1_loc}$'\t'# FIXED >> param.txt
echo p4008_1_height = $p4008_1_height >> param.txt
echo p4008_1_width = -25  >> param.txt

echo p4008_2_loc = ${p4008_2_loc}$'\t'# FIXED >> param.txt
echo p4008_2_height = $p4008_2_height >> param.txt
echo p4008_2_width = -25  >> param.txt

echo p4008_3_loc = ${p4008_3_loc}$'\t'# FIXED >> param.txt
echo p4008_3_height = $p4008_3_height >> param.txt
echo p4008_3_width = -25  >> param.txt

echo p4008_4_loc = ${p4008_4_loc}$'\t'# FIXED >> param.txt
echo p4008_4_height = $p4008_4_height >> param.txt
echo p4008_4_width = -25  >> param.txt

echo p4008_5_loc = ${p4008_5_loc}$'\t'# FIXED >> param.txt
echo p4008_5_height = $p4008_5_height >> param.txt
echo p4008_5_width = -25  >> param.txt

echo p4008_6_loc = ${p4008_6_loc}$'\t'# FIXED >> param.txt
echo p4008_6_height = $p4008_6_height >> param.txt
echo p4008_6_width = -25  >> param.txt

echo p4008_7_loc = ${p4008_7_loc}$'\t'# FIXED >> param.txt
echo p4008_7_height = $p4008_7_height >> param.txt
echo p4008_7_width = -25  >> param.txt

echo p4008_8_loc = ${p4008_8_loc}$'\t'# FIXED >> param.txt
echo p4008_8_height = $p4008_8_height >> param.txt
echo p4008_8_width = -25  >> param.txt



gnuplot $persist<<EOF

# Restrict all peaks to their single defined location, a positive peak height, and a maximum width of 10 or 50 wavenumbers
h(x) = sqrt(x**2)
w_narrow(x) = 5/pi*(atan(x)+pi/2)+0.1
w_wide(x) = 25/pi*(atan(x)+pi/2)+0.1


# Set up fitting peaks
bg(x) = int + grad * x

p4008_1_peak(x) = h(p4008_1_height) * voigt( x - (p4008_1_loc) , w_narrow(p4008_1_width) )
p4008_2_peak(x) = h(p4008_2_height) * voigt( x - (p4008_2_loc) , w_narrow(p4008_2_width) )
p4008_3_peak(x) = h(p4008_3_height) * voigt( x - (p4008_3_loc) , w_narrow(p4008_3_width) )
p4008_4_peak(x) = h(p4008_4_height) * voigt( x - (p4008_4_loc) , w_narrow(p4008_4_width) )
p4008_5_peak(x) = h(p4008_5_height) * voigt( x - (p4008_5_loc) , w_narrow(p4008_5_width) )
p4008_6_peak(x) = h(p4008_6_height) * voigt( x - (p4008_6_loc) , w_narrow(p4008_6_width) )
p4008_7_peak(x) = h(p4008_7_height) * voigt( x - (p4008_7_loc) , w_narrow(p4008_7_width) )
p4008_8_peak(x) = h(p4008_8_height) * voigt( x - (p4008_8_loc) , w_narrow(p4008_8_width) )



# Define curve as sum of peaks, with and without baseline
f(x) = p4008_1_peak(x) + p4008_2_peak(x) + p4008_3_peak(x) + p4008_4_peak(x) + p4008_5_peak(x) + p4008_6_peak(x) + p4008_7_peak(x) + p4008_8_peak(x) + bg(x)
p(x) = p4008_1_peak(x) + p4008_2_peak(x) + p4008_3_peak(x) + p4008_4_peak(x) + p4008_5_peak(x) + p4008_6_peak(x) + p4008_7_peak(x) + p4008_8_peak(x)


# Perform the fit
FIT_LIMIT = 1e-7
FIT_MAXITER = 1000
fit f(x) '$1' using 1:2:(1) via 'param.txt'

save fit 'param_after.txt'


############ Output data to text files



set table "data.xy"
plot [x=400:1400] '$1' using 1:2
#set terminal png
#set output "data.png"
#replot

set table "p4008_1_peak.xy"
plot [x=400:1400] p4008_1_peak(x)

set table "p4008_2_peak.xy"
plot [x=400:1400] p4008_2_peak(x)

set table "p4008_3_peak.xy"
plot [x=400:1400] p4008_3_peak(x)

set table "p4008_4_peak.xy"
plot [x=400:1400] p4008_4_peak(x)

set table "p4008_5_peak.xy"
plot [x=400:1400] p4008_5_peak(x)

set table "p4008_6_peak.xy"
plot [x=400:1400] p4008_6_peak(x)

set table "p4008_7_peak.xy"
plot [x=400:1400] p4008_7_peak(x)

set table "p4008_8_peak.xy"
plot [x=400:1400] p4008_8_peak(x)

set table "fit.xy"
plot [x=400:1400] f(x)


set table "all_p4008_peaks.xy"
plot [x=400:1400] p(x)

set table "residual.xy"
plot [x=400:1400] '$1' using 1:(\$2 - f(\$1))

set table "background.xy"
plot [x=400:1400] bg(x)

set table "bgremoved.xy"
plot [x=400:1400] '$1' using 1:(\$2 - bg(\$1))

unset table

plot [x=400:1400] 'data.xy', 'p4008_1_peak.xy' with lines, 'p4008_2_peak.xy' with lines, 'p4008_3_peak.xy' with lines, 'p4008_4_peak.xy' with lines, 'p4008_5_peak.xy' with lines, 'p4008_6_peak.xy' with lines, 'p4008_7_peak.xy' with lines, 'p4008_8_peak.xy' with lines, f(x) with lines

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
pr "p4008_1_width ", w_narrow(p4008_1_width)
pr "p4008_2_width ", w_narrow(p4008_2_width)
pr "p4008_3_width ", w_narrow(p4008_3_width)
pr "p4008_4_width ", w_narrow(p4008_4_width)
pr "p4008_5_width ", w_narrow(p4008_5_width)
pr "p4008_6_width ", w_narrow(p4008_6_width)
pr "p4008_7_width ", w_narrow(p4008_7_width)
pr "p4008_8_width ", w_narrow(p4008_8_width)



EOF


##### Remove scientific notation
#sed 's/e-/\*10\^-/' param_after.txt > ${1}_param_after.txt

##### Find final parameters ######
#p4008_1_loc=`awk ' $1 ~ /p4008_1_loc/ { print sqrt( $2 ^ 2 ) } ' param3.txt `
#p4008_1_height=`awk ' $1 ~ /p4008_1_height/ { print $2 } ' param3.txt `
#p4008_1_width=`awk ' $1 ~ /p4008_1_width/ { print $2 } ' param3.txt `
#p4008_1_area=`awk ' ( NR > 4) $1 ~ /p4008_1_area/ { print $2 } ' param3.txt `


#ps2pdf combined.ps ${nicename}combined.pdf
#rm combined.ps


mv peaks.png ${nicename}peaks.png
mv fit.png ${nicename}fit.png
mv bgremoved.png ${nicename}bgremoved.png
mv residual.png ${nicename}residual.png
mv param_after.txt ${nicename}_p4008fit_param.txt

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
