% NNmain.m
% 08/03/2010: Gerry wrote it
%
% This is the nearest neighbor analysis gateway script.  This script will
% call all other necessary nearest neighbor scripts required in the nearest
% neighbor analysis, such that you don't have to go to each individual
% script.  Simply comment/uncomment the regions corresponding to the
% analyses you wish to run

% Global Variables---------------------------------------------------------

% type of data being analyzed
DataType = '6mo';

% Root directories to datafiles
root = '\\SONGMINGONE\Sun(K)';
% root = 'K:\1-DGTangentialCut';

Rootdirs = {[root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo1RH_Sect09\Group1\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo1RH_Sect09\Group2\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo3RH_Sect11\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo4RH_Sect06\Group1\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo4RH_Sect06\Group2\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo4RH_Sect07\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo5RH_Sect06\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo5RH_Sect07\Group1\'] ...
    [root '\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\AgedFull6mo5RH_Sect07\Group2\']};

% datafile names
Names = {'AgedFull6mo1RH_Sect09_Group1' ...
    'AgedFull6mo1RH_Sect09_Group2' ...
    'AgedFull6mo3RH_Sect11' ...
    'AgedFull6mo4RH_Sect06_Group1' ...
    'AgedFull6mo4RH_Sect06_Group2' ...
    'AgedFull6mo4RH_Sect07' ...
    'AgedFull6mo5RH_Sect06' ...
    'AgedFull6mo5RH_Sect07_Group1' ...
    'AgedFull6mo5RH_Sect07_Group2'};

% xyz scaling plus number of slices (important for random data generation)
% X, Y, Z, Slice#
ScalingNSlice(1,:) = [0.59 0.59 2.5 30]; % AgedFull6mo1RH_Sect09_Group1
ScalingNSlice(2,:) = [0.59 0.59 2.5 30]; % AgedFull6mo1RH_Sect09_Group2
ScalingNSlice(3,:) = [0.59 0.59 2.5 28]; % AgedFull6mo3RH_Sect11
ScalingNSlice(4,:) = [0.69 0.69 2.5 28]; % AgedFull6mo4RH_Sect06_Group1
ScalingNSlice(5,:) = [0.69 0.69 2.5 28]; % AgedFull6mo4RH_Sect06_Group2
ScalingNSlice(6,:) = [0.69 0.69 2.5 26]; % AgedFull6mo4RH_Sect07
ScalingNSlice(7,:) = [0.54 0.54 2.5 27]; % AgedFull6mo5RH_Sect06
ScalingNSlice(8,:) = [0.54 0.54 2.5 28]; % AgedFull6mo5RH_Sect07_Group1
ScalingNSlice(9,:) = [0.54 0.54 2.5 28]; % AgedFull6mo5RH_Sect07_Group2

% standard names of progenitor subtypes classified
Classifications = {'NesRad' 'NesRadMcm2' 'NesRadMcm2Tbr2' 'NesTangMcm2' ...
    'NesTangMcm2Tbr2' 'Mcm2' 'Mcm2Tbr2' 'DcxTangStubMcm2Tbr2' ...
    'DcxTangLongMcm2Tbr2' 'DcxTangLongMcm2' 'DcxTangLong' 'DcxRad'};


% PLEASE CHANGE THE WORKING DIRECTORY OF MATLAB TO THAT OF THIS SCRIPT
% BEFORE USING THE CELLS BELOW
%% make mat files from the Imaris exported spreadsheets
ReadSpotsXLS(Rootdirs,Names,Classifications,ScalingNSlice);

%% run the nearest neighbor analysis
NNAnalysis(Rootdirs,Names,Classifications,DataType);

%% run bootstrapping on the NNAnalysis-->can only do this after running NNAnalysis.m!
NNbootstrap(Classifications,DataType);

%% plot the n Nearest Neighbors
nNearestNeighbors(Rootdirs,Names,Classifications,DataType)

%% plot progenitor composition pie graphs
ProgenitorComposition(Rootdirs,Names,Classifications,DataType)