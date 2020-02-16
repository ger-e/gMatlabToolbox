function ToHDF5FromCZI(inputDir,inputFileName,outputDir)
% function ToHDF5FromCZI(inputDir,inputFileName,outputDir)
% 4/25/2015: Gerry wrote it
%
% This script will take in a *.czi file series and export it to a single
% HDF5 file with the data stored in '/data' with dimensions Y, X, Z, T.
% Slices are loaded serially such that the whole stack is never in memory.
%
% Dependencies: Bio-formats 5.1 toolbox for Matlab, 
% see: http://www.openmicroscopy.org/site/support/bio-formats5.1/users/matlab/

% output file info
outputFileName = [inputFileName(1:end-4) '.h5'];

% open up a bio-formats file reader (virtual stack)
reader = bfGetReader(fullfile(inputDir,inputFileName));
omeMeta = reader.getMetadataStore(); % get metadata

% get dimensions
YXZTDims = [omeMeta.getPixelsSizeY(0).getValue() omeMeta.getPixelsSizeX(0).getValue() omeMeta.getPixelsSizeZ(0).getValue() omeMeta.getPixelsSizeT(0).getValue()];

% start reading in each slice and export to a single hdf5 file
h5create(fullfile(outputDir,outputFileName),'/data',YXZTDims,'Datatype','uint16');

SliceCount = 1;
for a=1:YXZTDims(4)
    for b=1:YXZTDims(3)
        Slice = bfGetPlane(reader,SliceCount);
        h5write((fullfile(outputDir,outputFileName)),'/data',single(Slice),[1 1 b a],[YXZTDims(1) YXZTDims(2) 1 1]);
        SliceCount = SliceCount + 1;
    end
end

end