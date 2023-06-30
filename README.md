# raman-fitting-pvc
A script for automatically analysing Raman spectra of PVC to determine 
the contribution of four raw materials to the overall formulation

This script is a variant of "raman-fitting" (https://github.com/robertsparkes/raman-fitting), 
developed to specifically fit Raman spectra from PVC plastic formulations

The main script, **raman-fitting-pvc.sh** analyses Raman spectra of a PVC mixture fitting the sample data against
defined Voigt peaks of four standards, plus a background. Other scripts in this repository are 
for pre-processing the data and generating required files in the working directory.

## Requirements

The script requires the following software to run:
- A Unix / Linux environment (tested with Ubuntu 22.04)
- Packages "dos2unix", "bc", "awk", "ghostscript"
- Gnuplot graphing software (package "gnuplot") 
    - v4.5 or above is required, v5.4.2 is included with Ubuntu 22.04

- All scripts require permission to execute as programs

## Basic Operation

### Preparing the working directory

The script "**prepraman.sh**" should be run before the first files in a given folder are analysed.
This script creates folders and initiates some datafiles for the subsequent fits

> $ prepraman.sh

### Preparing the data files

The input is taken from a series of two-column space-separated text files. The text files should be contained 
within one single folder, or grouped into sub-folders which will each need to be prepared and analysed separately.
Column 1 is the wavenumber, column 2 is the intensity.

Suitable text files can be as produced by a Renishaw Raman spectrometer using the inbuilt WiRE software. 
Proprietary .wxd files can be converted into two-column space-separated text files 
(wavenumber intensity) using the "Wire Batch Convert" program. 

The script "**csvtxt.sh**" can be used to convert comma-separated data files into space-separated text files.

> $ csvtxt.sh myfile.csv

### Script Execution

The script executes from the command line, in the form

> $ raman-fitting-pvc.sh [options] [input files]

The options are
-q Quiet mode - graphs appear on screen but immediately disappear
-d Delete - removes previous results from "acombinedresults.txt"

Input files can be listed individually, or selected all at once using a wildcard (e.g. *.txt)
After analysis the results are written to a file entitled "acombinedresults.txt". Any filename
already in this file will be ignored and not re-fitted. The "-d" option removes all results 
from "acombinedresults.txt" and allows previously fitted files to be analysed.

Example code to prepare for and then analyse all samples with "taiwan" at the start of the file name:

> $ prepraman.sh
> 
> $ sparkesfitraman.sh -d -q taiwan*.txt

### Outputs

The script outputs three graphs, containing the raw spectra with linear background identified,
raw spectra with overall fit superimposed and a residual shown, and the spectra following the fitting,
showing the fitted peaks after the background has been removed. 

The fitting parameters are written to a summary file (acombinedresults.txt) for further analysis

## Advanced Operation

### Generating parameters for the standard raw materials (not required for basic operation)

The curves for each of the four standards are defined by fitting Voigt peaks to Raman data
collected from a pure sample of each raw material. Peak locations, heights and widths are
currently hard-coded into the main script.

If you wish to generate standard curves independently, scripts for doing this are incldued in 
the repository:
raman-standard-PVC.sh
raman-standard-carbonate.sh
raman-standard-DOTP.sh
raman-standard-p4008.sh

The main script will then need to be edited to ensure:
- The right number of peaks are generated for each raw material
- The heights, locations and widths of each peak for each material are correct
