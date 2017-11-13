OpenStudio-ERI
===============

Calculates an Energy Rating Index (ERI) via an OpenStudio/EnergyPlus-based workflow. Building information is provided through an [HPXML file](https://hpxml.nrel.gov/).

The ERI is defined by the ANSI/RESNET 301-2014 "Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index".

**Unit Test Status:** [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-ERI.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-ERI)

**Code Coverage:** [![Coverage Status](https://coveralls.io/repos/github/NREL/OpenStudio-ERI/badge.svg?branch=master)](https://coveralls.io/github/NREL/OpenStudio-ERI?branch=master)

## Setup

Download the latest version of OpenStudio from https://www.openstudio.net/developers. At a minimum, install the "Command Line Interface".

## Running

1. Navigate to the [workflow](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow) directory.
2. Run the ERI calculation on a provided sample HPXML file:  
```c:/openstudio-2.2.1/bin/openstudio.exe energy_rating_index.rb -x sample_files/valid.xml -e sample_files/denver.epw```  
Note that the Reference Home and Rated Home workflows/simulations will be executed in parallel on the local machine.
3. This will generate output as shown below:
![CLI output](https://user-images.githubusercontent.com/5861765/32755025-942216e6-c890-11e7-966c-0f655582b58f.png)

## ERI Outputs

Upon completion of the ERI calculation, multiple outputs are currently available:
* results.csv and worksheet.csv files (that mirror the [HERS Method Test form](http://www.resnet.us/programs/2014_HERS-Method_Results-Form.xlsx))
* Reference & Rated Home HPXML files (transformations of the input HPXML file via the 301 ruleset)
* EnergyPlus input/output files

See the [sample_results](https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results) directory for examples of these outputs.

## Disclaimers

*	The 301 ruleset and ERI calculation are very much both **works-in-progress**. 
* The format of the ERI HPXML file is still in flux.
*	The workflow has only been tested with a few sample files, as provided in the `workflow/sample_files` directory.
*	Errors/warnings are not yet being handled gracefully.
*	No effort has been spent to optimize/speed up the process yet. 
