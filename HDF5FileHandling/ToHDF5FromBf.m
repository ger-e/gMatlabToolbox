function ToHDF5FromBf(filename,inDirectory,outDirectory)
% 6/6/2016: Gerry wrote it
% Note that we use the memoizer wrapper to allow metadata caching (so that
% you only have to wait once for metadatafile reading; this is useful in
% the event that you have a broken network pipe. If a cache file (*.bfmemo)
% exists, then the bioformats reader will use it automatically
%
% This script will take as input a XYZTCS image that is bioformats
% compatible and export it to an HDF5 file. Currently written to export to
% a flat file (i.e. XY by Z*T*C*S)
% Note that intial loading of metadata will take a long time!

reader = bfGetReader();

% Decorate the reader with the Memoizer wrapper
reader = loci.formats.Memoizer(reader);

% Initialize the reader with an input file
% If the call is longer than a minimal time, the initialized reader will
% be cached in a file under the same directory as the initial file
% name .large_file.bfmemo
reader.setId(fullfile(inDirectory,filename));

% reader = bfGetReader(fullfile(inputDir,inputFileName));
omeMeta = reader.getMetadataStore();

XDim = omeMeta.getPixelsSizeX(0).getValue();
YDim = omeMeta.getPixelsSizeY(0).getValue();
ZDim = omeMeta.getPixelsSizeZ(0).getValue();
TDim = omeMeta.getPixelsSizeT(0).getValue(); % number of time points
CDim = omeMeta.getPixelsSizeC(0).getValue(); % number of channels
SDim = reader.getSeriesCount(); % number of views (for multiview imaging)

% create the HDF5 file
[~,namestem,~] = fileparts(filename);
fullpath = fullfile(outDirectory,[namestem '.h5']);
h5create(fullpath,'/data',[Inf Inf Inf],'Datatype','uint16','ChunkSize',[YDim XDim 1]);
h5create(fullpath,'/YXZTCSDims',[1 6],'Datatype','double');
h5write(fullpath,'/YXZTCSDims',[YDim XDim ZDim TDim CDim SDim]); % write dimension information

% get the projection series by series, time by time
for c=1:SDim % step thru views
    % all BFreader is in 0 indexing
    reader.setSeries(c-1);

    for d=1:TDim % step thru time
        for a=1:ZDim % number of slices
            for b=1:CDim % number of channels
                Index = reader.getIndex(a-1,b-1,d-1) + 1;
                success = 0;
                while ~success % guard against network errors
                    try
                        tempslice = bfGetPlane(reader,Index);
                        h5write(fullpath,'/data',tempslice,[1 1 Index],[YDim XDim 1]);
                        success = 1;
                    catch
                        fprintf(1,'\nNetwork Error...trying again...\n');
                        pause(0.1);
                    end
                end
            end
        end
    end
end

% Close the reader
reader.close()
end