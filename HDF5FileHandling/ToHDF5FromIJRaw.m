function ToHDF5FromIJRaw(filename,Directory,FrameCeiling,CompressLevel)
% function ToHDF5FromIJRaw(filename,Directory,FrameCeiling,CompressLevel)
% 1/24/2015: Gerry wrote it
% 4/7/2015: Gerry added in compression options (0-9), 0 = no compression
% This function will take in an ImageJ tif 'raw' image file (anything >2^32
% bytes in size) and convert it directly to an HDF5 file

% get basic img parameters
ImgInfo = imfinfo(fullfile(Directory,filename));
temp2 = strfind(ImgInfo.ImageDescription,'s=');
NumSlices = str2double(ImgInfo.ImageDescription(temp2(1)+2:temp2(2)-6));

% create the HDF5 file
h5create(fullfile(Directory,[filename(1:end-4) '.h5']),'/data',[ImgInfo(1).Height ImgInfo(1).Width NumSlices],'Datatype','single','ChunkSize',[20 20 20],'Deflate',CompressLevel);

% figure out how many passes to make (because can't load all into memory at
% once)
NumPasses = ceil(NumSlices/FrameCeiling);

for a=1:NumPasses
    % read in bolus of data
    if NumPasses == 1
        data = ReadRawIJSlices(fullfile(Directory,filename),ImgInfo,1,NumSlices);
    else
        data = ReadRawIJSlices(fullfile(Directory,filename),ImgInfo,(a-1)*FrameCeiling+1,min([FrameCeiling NumSlices-(a-1)*FrameCeiling]));
    end
    
    data = single(data); % assuming 16-bit here
    
    % write directly to HDF5 file
    h5write(fullfile(Directory,[filename(1:end-4) '.h5']),'/data',data,[1 1 (a-1)*FrameCeiling+1],size(data));
end
end