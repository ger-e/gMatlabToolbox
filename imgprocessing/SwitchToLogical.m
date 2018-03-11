% SwitchToLogical
% 11/5/11: gerry wrote it
% 11/6/11: updated to pull out the largest volume (3d!) so you can create
% surface renderings of data very easily
%
% A quick script to switch imgs to logical for better use with automatic
% surface creation in imaris. This script was originally used for Juan's PV
% data (And thus some data-specific code is present)

rootdir = '\\SONGMINGONE\Storage 2 (X)\Gerry\PV-NesGFP_Reconstruction\fordeconvolution\deconvolved\series\nesGFP';
cd(rootdir);
imgs = dir('*.tif'); % just pull out normalized images
diskradius = 1; % radius to dilated mask by

manuallevels = [18.1847
16.6635
9.0578
13.2063
12.7915
12.2383
11.4086
11.4086
9.6109
20.6738
];
for a=1:length(imgs)
    % segment and convert to logical
    slice = imread(imgs(a).name);
    
    % manually set thresh level based upon thresh_tool investigation for
    % problematic slices
    switch imgs(a).name(end-10:end-4)
%         case 'C0_Z000'
%             level = manuallevels(1)/255;
%         case 'C0_Z001'
%             level = manuallevels(2)/255;
%         case 'C0_Z127'
%             level = manuallevels(3)/255;
%         case 'C0_Z155'
%             level = manuallevels(4)/255;
%         case 'C0_Z180'
%             level = manuallevels(5)/255;
%         case 'C0_Z181'
%             level = manuallevels(6)/255;
%         case 'C0_Z207'
%             level = manuallevels(7)/255;
%         case 'C0_Z208'
%             level = manuallevels(8)/255;
%         case 'C0_Z209'
%             level = manuallevels(9)/255;
%         case 'C0_Z239'
%             level = manuallevels(10)/255;
        otherwise % default case
            level = graythresh(slice);        
    end
    mask = im2bw(slice,level); % undilated mask
    
    % dilated mask
    SE = strel('disk',diskradius); % define a disk to dilate pixels by
    mask2 = imdilate(mask,SE); % dilate;
    
    % store the entire mask stack for bwlabeln/regionprops to pluck out 3d
    % connected regions
    if a==1
%         MaskStack = zeros(size(mask,1),size(mask,2),length(imgs));
%         MaskStack(:,:,a) = mask;
        MaskStack2 = zeros(size(mask2,1),size(mask2,2),length(imgs));
        MaskStack2(:,:,a) = mask2;        
    else
%         MaskStack(:,:,a) = mask;
        MaskStack2(:,:,a) = mask2;
    end
%     imwrite(mask,[imgs(a).name(1:end-5) '_mask.bmp'],'bmp');
%     imwrite(mask,[imgs(a).name(1:end-4) '_mask.bmp'],'bmp');
end

% now pull out only the largest volume from the dilated mask
Clusters2 = bwlabeln(MaskStack2); % number 3d clusters
Stats2 = regionprops(Clusters2,'Area');
Areas2 = [Stats2.Area];

% get largest volume
[maxArea2 indx2] = max(Areas2);
MaskStack2(Clusters2~=indx2) = 0;

for b=1:size(MaskStack2,3)
    imwrite(MaskStack2(:,:,b),[imgs(b).name(end-10:end-4)  '_strel' num2str(diskradius) '.bmp'],'bmp');
end