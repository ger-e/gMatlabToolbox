function ToHDF5FromMPtiffDir(inDirectory,outDirectory,Compress)
% function ToHDF5FromMPtiffDir(inDirectory,outDirectory,Compress)
% 1/9/2016: Gerry wrote it
% 5/23/2016: Gerry modified to specify output directory as well as a flag
% to say whether you wanted compression (1) or not (0)
% Converts sequential multi-page tiff files (e.g. exported from
% HCImageLive) into a single compressed HDF5 file

Imgs = dir(fullfile(inDirectory,'*.tif')); % get img names
PrevSlice = 0; % counter for proper indexing
for a=1:length(Imgs)
    CurrImg = tiffread_gerry(fullfile(inDirectory,Imgs(a).name));
    if a==1
        % create file with unlimited dimensions
        if Compress
            h5create(fullfile(outDirectory,[Imgs(1).name(1:end-4) '.h5']),'/data',[Inf Inf Inf], ...
                'Datatype','uint16','ChunkSize',[size(CurrImg,1) size(CurrImg,2) 1],'Deflate',9);
        else
            h5create(fullfile(outDirectory,[Imgs(1).name(1:end-4) '.h5']),'/data',[Inf Inf Inf], ...
                'Datatype','uint16','ChunkSize',[size(CurrImg,1) size(CurrImg,2) 1]);
        end
    end
    h5write(fullfile(outDirectory,[Imgs(1).name(1:end-4) '.h5']),'/data',CurrImg,[1 1 1+PrevSlice],[size(CurrImg,1) size(CurrImg,2) size(CurrImg,3)]);
    PrevSlice = PrevSlice + size(CurrImg,3);
end
end