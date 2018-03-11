% LSMtoTiffSeries.m
% 08/22/2011: Gerry wrote it
% This is a simple script that will use Imaris to convert LSM files to Tiff
% series

% path to images
rootDir = 'D:\Gerry\SEBI norm\060311-08 35dai hippo posterior';
cd(rootDir);
Images = dir('*.lsm'); % get list of lsm files

% open COM access to Imaris
vImarisApplication=actxserver('Imaris.Application');

for a=1:size(Images,1)
    % read the file
    vImarisApplication.FileOpen([rootDir '\' Images(a).name]);
    
    % save as tiff series
    vImarisApplication.FileSave([rootDir '\' Images(a).name(1:end-4)],'writer="SeriesAdjustable"');
end