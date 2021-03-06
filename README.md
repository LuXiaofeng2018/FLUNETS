# FLUNETS
% -------------------------------------------------------------------------------------------------
## FLUNETS - Tool definition

FLUNETS is a tool to extract and order fluvial network from a Digital Elevation Model (DEM).
The aim is to provide a continuous fluvial network, where the value of 
each river remains the same from the confluence upstream to the headwater. 
FLUNETS internally uses TopoToolbox functions (DOI: 10.5194/esurf-2-1-2014) to calculate 
flow-related matrices derived from the DEM.

% -------------------------------------------------------------------------------------------------
## Contact details

For more information on FLUNETS, please contact:

Candela Pastor
cpastor [at] pas.uned.es

% -------------------------------------------------------------------------------------------------
## Requirements

FLUNETS requires Matlab 2011b or higher version and the Image Processing Toolbox.
Requires to download TopoToolbox:(https://github.com/wschwanghart/topotoolbox).


% -------------------------------------------------------------------------------------------------
## Getting started

The main script is FLUNETS_main.m. In FLUNETS_main.m, is where the stream_ordering_tools and TopoToolbox paths are set. Also is where the input data and optional parameters are specified.

The output files are an ordered drainage network in ASCII format, and a CSV file with descriptive data of the network, such as the accumulation value of each river, the distance to the headwater, the length of the river, the drainage area, etc. 

Fo more info, read the user-guide file.
