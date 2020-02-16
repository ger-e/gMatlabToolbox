function ToHDF5FromAVI(filename,inDirectory,outDirectory,FrameCeiling,MetaExists,Stride)
% function ToHDF5FromAVI(filename,inDirectory,outDirectory,FrameCeiling,MetaExists,Stride)
% 1/24/2016: Gerry wrote it
% 4/11/2016: Gerry added ability to write metadata to HDF5 file (here we
% just write the age and recording frequency from the metadata string)
% 4/13/2016: Gerry added ability to export a downsampled HDF5 file--here we
% mean downsampling in terms of frames (e.g., taking every nth frame)
% 7/27/2016: Fixed bug where if the last pass only had 1 frame, you'd run into a write error
% This function will take in an AVI file and convert it directly to an HDF5 
% file. If metadata exists in a text file of the same name, then pass 
% MetaExists = 1, else pass a 0
% Stride is the interval between frames to sample; if you want all frames,
% pass 1, if you want every 2nd frame, pass 2, if you want every nth frame,
% pass n
% NOTE: as currently written, we assume data are uint8!

% open the video reader object
fullpath = fullfile(inDirectory,filename);
obj = VideoReader(fullpath);

% get total frames and frame size
TotFrames = get(obj,'NumberOfFrames');
FrameSize = size(read(obj,1));

% create the HDF5 file
h5create(fullfile(outDirectory,[filename(1:end-4) '.h5']),'/data',[Inf Inf Inf],'Datatype','uint8','ChunkSize',[FrameSize(1) FrameSize(2) 1]);

% figure out how many passes to make (because can't load all into memory at
% once)
NumPasses = ceil(TotFrames/FrameCeiling);

for a=1:NumPasses
    % read in bolus of data
    if NumPasses ==1
        data = read(obj,TotFrames);
    else
        data = read(obj,[(a-1)*FrameCeiling+1 min([TotFrames a*FrameCeiling])]);
    end
    
    data = squeeze(data);
    data = data(:,:,1:Stride:end);
    
    % write directly to HDF5 file
	if length(size(data))==2 % protect against error if your last pass only has a single frame
		h5write(fullfile(outDirectory,[filename(1:end-4) '.h5']),'/data',data,[1 1 (a-1)*length(1:Stride:FrameCeiling)+1],[size(data) 1]);
	else
		h5write(fullfile(outDirectory,[filename(1:end-4) '.h5']),'/data',data,[1 1 (a-1)*length(1:Stride:FrameCeiling)+1],size(data));
	end
end

% write metadata to hdf5 file if requested
if MetaExists
    [pathstr, filenameWOext] = fileparts(fullpath);
    metafilename=[filenameWOext '.txt'];
    myh5name = [filenameWOext '.h5'];
    metastring=fileread(fullfile(pathstr,metafilename));
    Freq = readVarIni(metastring,'Freq');
    Age = readVarIni(metastring,'Age');
    if ~h5dataexists('Freq',h5info(fullfile(outDirectory,myh5name)));
        h5create(fullfile(outDirectory,myh5name),'/Freq',1,'Datatype','double');
    end
    h5write(fullfile(outDirectory,myh5name),'/Freq',Freq/Stride);
    if ~h5dataexists('Age',h5info(fullfile(outDirectory,myh5name)));
        h5create(fullfile(outDirectory,myh5name),'/Age',1,'Datatype','double');
    end
    h5write(fullfile(outDirectory,myh5name),'/Age',Age);
end

end