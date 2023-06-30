# raman-fitting-pvc
A script for automatically analysing Raman spectra of PVC to determine 
the contribution of four raw materials to the overall formulation

This script is a variant of "raman-fitting" (https://github.com/robertsparkes/raman-fitting), 
developed to specifically fit Raman spectra from PVC plastic formulations

The main script, raman-fitting-pvc.sh analyses Raman spectra of a PVC mixture fitting the sample data against
defined Voigt peaks of four standards, plus a linear background.

The curves for each of the four standards are defined by fitting Voigt peaks to Raman data
collected from a pure sample of each raw material.

If you wish to generate standard curves independently, scripts for doing this are incldued in 
the repository:
raman-standard-PVC.sh
raman-standard-carbonate.sh
raman-standard-DOTP.sh
raman-standard-p4008.sh

The input is taken from a series of text files as produced by a Renishaw Raman spectrometer using
Wire software. Proprietary .wxd files can be converted into two-column space-separated text files 
(wavenumber intensity) using the "Wire Batch Convert" program. The text files should be contained 
within one single folder, or grouped into sub-folders.

The script outputs three graphs, containing the raw spectra with linear background identified,
raw spectra with overall fit superimposed and a residual shown, and the spectra following the fitting,
showing the fitted peaks after the background has been removed. The fitting parameters are outputted 
to a summary file (acombinedresults.txt) for further analysis

The script requires the following software to run:
- A Unix / Linux environment (tested with Ubuntu)
- Bash terminal program
- Dos2unix text file conversion software
- Gnuplot graphing software. 
    - Version 4.5 or above is required
- Ghostscript PostScript and PDF manipulation software
- The script "prepraman.sh" should be run before the first files in a given folder are analysed.
  This script creates folders and initiates some datafiles for the subsequent fits
- Both this fitting script and "prepraman.sh" require permission to execute as programs

The script executes from the command line, in the form
$ sparkesfitraman.sh [options] [input files]

The options are
-q Quiet mode - graphs appear on screen but immediately disappear
-d Delete - removes previous files from "acombinedresults.txt"
-t[value] Threshold - the signal-to-noise ratio below which a peak is too noisy to process

Input files can be listed individually, or selected all at once using a wildcard (e.g. *.txt)
After analysis the results are written to a file entitled "acombinedresults.txt". Any filename
already in this file will be ignored and not re-fitted, hence the delete option.

Example code to prepare for and then analyse all samples with "taiwan" in the file name:
$ prepraman.sh 
$ sparkesfitraman.sh -d -q -t 5 taiwan*.txt

Note: The included script "cropraman.sh" will take a file and crop to certain wavenumbers. The
fitting procedure is less accurate if files extend too far beyond 2000 cm-1 as the assumption
of a linear background is no longer valid.
