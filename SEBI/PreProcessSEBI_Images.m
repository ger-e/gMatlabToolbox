% PreProcessSEBI_Images.m
% 06/16/2011: Gerry wrote it
% 6/29/2011: updated to be able to deal with n numChannels
% 8/17/2011: updated to be able to deal with different bit levels and also
% export tiles as separate *.ims files (for easier assessment of
% overlapping tiles for XUV alignment)
% 8/28/2012: updated to NOT assume tile dimensions; fixed bug with
% processing multi-channel images
%
% input: spreadsheet with slab names, tiledim (i.e. 512x512; num tiles in
% each xy direction can be calculated, as can the number of slices)
% 
% read in each file one by one
% 
% 1-load file
% 2-save as tiff series in file's own directory
% 3-export to tile stacks in subdir
% 4-load first tile stack
% 5-save as ims file
%
% Note that imaris FileOpen and FileSave require absolute, not relative,
% paths

% path to SEBI slabs and spreadsheet
rootDir = 'C:\Users\Gerry\Desktop\20130703-Thy1-Disc1_KI\tosplit';
% SlabInfo = ''; % currently not used because all TileDim are 512x512

numChannels = 1; % number of channels in your image
TileDim = 512; % assume tile dimensions, edit in actual function
bitLevel = 8; % important to get right intensities (only 8,16,32,64 allowed)
cd(rootDir);
Images = dir('*.lsm'); % get list of lsm files

% open COM access to Imaris
vImarisApplication=actxserver('Imaris.Application');

for a=1:size(Images,1)
    % read the file
    vImarisApplication.FileOpen([rootDir '\' Images(a).name]);
    
    % make a directory for the file's images and go to it
    mkdir(Images(a).name(1:end-4));
    cd(Images(a).name(1:end-4)); currDir = pwd;
    
    % save as tiff series
    vImarisApplication.FileSave([currDir '\' Images(a).name(1:end-4)],'writer="SeriesAdjustable"');
    
    % then extract tiles
    exportToTilesStacks_function(Images(a).name(1:end-4),numChannels,bitLevel,TileDim);
    
    % then convert extracted tiles to time course imaris files and save to
    % root directory (to save space/effort when renaming files when doing
    % the actual alignment)
    cd('Individual stacks'); currDir = pwd;
    numTiles = length(dir('*.tiff'))/numChannels; % get the number of tiles (per channel; for use later)
    vImarisApplication.FileOpen([currDir '\' Images(a).name(1:end-4) '_c0_t1.tiff']);
    vImarisApplication.FileSave([rootDir '\' Images(a).name(1:end-4) '_tiles.ims']);
    
    % then convert extracted tiles to individual imaris files and save to
    % individual stacks directory (for use with finding alignment tiles)
    mkdir('temp'); cd('temp'); currDir = pwd;
    for cc=1:numChannels
        for tt=1:numTiles
            copyfile(['../' Images(a).name(1:end-4) '_c' num2str(cc-1) '_t' num2str(tt) '.tiff'],[Images(a).name(1:end-4) '_c' num2str(cc-1) '_t' num2str(tt) '.tiff']);
            vImarisApplication.FileOpen([currDir '\' Images(a).name(1:end-4) '_c' num2str(cc-1) '_t' num2str(tt) '.tiff']);
            vImarisApplication.FileSave(['../' Images(a).name(1:end-4) '_c' num2str(cc-1) '_t' num2str(tt) '.ims']);    
            delete([Images(a).name(1:end-4) '_c' num2str(cc-1) '_t' num2str(tt) '.tiff']);
        end
    end
    cd(rootDir); % go back to root dir
end