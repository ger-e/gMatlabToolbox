function ToHDF5FromTif(filename,Directory,FrameCeiling)
% function ToHDF5FromTif(filename,Directory,FrameCeiling)
% 1/24/2015: Gerry wrote it
% This function will take in a tif stack and convert it directly to an HDF5
% file

% get basic img parameters
ImgInfo = imfinfo(fullfile(Directory,filename));

% create the HDF5 file
h5create(fullfile(Directory,[filename(1:end-4) '.h5']),'/data',[ImgInfo(1).Width ImgInfo(1).Height length(ImgInfo)],'Datatype','single');

% figure out how many passes to make (because can't load all into memory at
% once)
NumPasses = ceil(length(ImgInfo)/FrameCeiling);

for a=1:NumPasses
    % read in bolus of data
    if NumPasses == 1
        data = zeros(ImgInfo(1).Width,ImgInfo(1).Height,length(ImgInfo));
    elseif a<NumPasses
        data = zeros(ImgInfo(1).Width,ImgInfo(1).Height,FrameCeiling);
    else
        data = zeros(ImgInfo(1).Width,ImgInfo(1).Height,length(ImgInfo)-FrameCeiling);
    end
    
    if NumPasses == 1
        parfor b=1:length(ImgInfo)
            data(:,:,b) = imread(fullfile(Directory,filename),b);
        end
    else
        parfor b=1:min([FrameCeiling length(ImgInfo)-(a-1)*FrameCeiling])
            data(:,:,b) = imread(fullfile(Directory,filename),(a-1)*FrameCeiling+b);
        end
    end
    
    data = single(data); % assuming 16-bit here
    % write directly to HDF5 file
    h5write(fullfile(Directory,[filename(1:end-4) '.h5']),'/data',data,[1 1 (a-1)*FrameCeiling+1],size(data));
end
end