function [mask answer counter] = GetImgMask(img,counter)
% function GetImgMask(Image)
%
% Histology image analysis based initially upon Brett Shoelson's demo code
% (which was based upon Bob Bemis' code)
%
% Actual image analysis has been commented out in this code; this code will
% only segment the image

%% Some global variables
debug = 0; % = 1, show figs as you go along; = 0, suppress output
% ch_R = 1; % label 1
% ch_G = 2; % label 2
% ch_B = 3; % DAPI
%% Read in the file

% if debug
%     figure(1);
%     imshow(img);
%     title(sprintf('Original Image: %s',imgName));
% end

%% Use imtool if you want to explore image properties
% if debug
%     imtool(img);
% end

%% Segment out the primary region of interest (i.e. the dentate gyrus)

img = uint8(img); % convert to uint8

if debug
    figure(1);
    imshow(img);
    title('Primary region of interest (channel 1): DAPI');
end
%% Now create a mask for the primary ROI
%level = 3*0.1; % set threshold for segmentation via im2bw

if counter > 0
    level = thresh_tool(img); % manual thresholding if auto wasn't good
else
    level = mean(img(:)); % default auto thresholding
end
mask = im2bw(img,level/255);

if debug
    figure(2);
    imshow(mask);
    title(sprintf('Mask: rough outline, Threshold = %0.2f',level));
end

%% ROI cleaning step 1: clear objects on border
% might have to leave this out; doesn't seem to have any adverse effect if
% you leave it out; leaving it in makes life difficult when the ROI is on
% the border

% mask_roi = imclearborder(mask_roi);
% 
% if debug
%     figure(4);
%     imshow(mask_roi);
%     title('ROI Mask: after cleaning step 1 (imclearborder)');
% end

%% ROI cleaning step 2: only take the largest contiguous object
clusters = bwlabel(mask);
stats = regionprops(clusters,'Area');
Areas = [stats.Area];
[maxArea indx] = max(Areas);
mask(clusters~=indx) = 0;

if debug
    figure(3);
    imshow(mask);
    title('Mask: after cleaning step 2 (bwlabel,regionprops)');
    
    % if you haven't gotten the whole DG here, try again!
    answer = inputdlg('1 = OK, 0 = Try again manually','OK so far?',1,{'1'});
    answer = str2double(answer);
    if ~answer
        mask = 0;
        counter = counter + 1;
        return;
    end
end

%% ROI cleaning step 3: dilate the ROI to get smooth and filled region
diskRadius = 22; % set size of disk to dilate by
SE = strel('disk',diskRadius); % define the disk to dilate by
mask = imdilate(mask,SE); % dilate

if debug
    figure(4);
    imshow(mask);
    title('Mask: after cleaning step 3 (imdilate)');
end

% everything was OK
answer = 1;
%% Primary ROI has now been segmented out----------------------------------
% Use mask_roi now to home in on the region of your image where you want to
% count cells. We will now segment the image for cell counting

%% Segmentation for data in RED and GREEN channels-------------------------
% % isolate the data from red and green channels
% layer_R = img(:,:,1);
% layer_G = img(:,:,2);
% 
% if debug
%     figure(7); imshow(layer_R); title('Red channel');
%     figure(8); imshow(layer_G); title('Green channel');
% end

%% Use mask from primary ROI to define region where we'll segement
% layer_R(~mask_roi) = 0;
% layer_G(~mask_roi) = 0;
% 
% if debug
%     figure(9); imshow(layer_R); title('Red channel: masked');
%     figure(10); imshow(layer_G); title('Green channel: masked');
% end

%% Segment image using thresh_tool
%threshold_R = thresh_tool(layer_R); % 71.75
%threshold_G = thresh_tool(layer_G); % 151.74
% threshold_R = 22; % override values
% threshold_G = 151.74;
% mask_R = im2bw(layer_R,threshold_R/255); % divide by 255 b/c need value on [0 1]
% mask_G = im2bw(layer_G,threshold_G/255); 
% 
% if debug
%     figure(11); imshow(mask_R); title(sprintf('Red Channel Threshold: %0.2f',threshold_R));
%     figure(12); imshow(mask_G); title(sprintf('Green Channel Threshold: %0.2f',threshold_G));
% end

%% red test for dcx
% seline = strel('line',10,45);
% mask_R = imerode(mask_R,seline);
% figure(15); imshow(mask_R);
%% RED/GREEN channel cleaning step 1: erode away ~single pixels
% %pixRadius = 2; % set size of disk to erode by; for mcm2
% pixRadius = 6; % for dcx
% SEpix = strel('disk',pixRadius); % define the disk
% mask_R = imerode(mask_R,SEpix); % erode the masks
% mask_G = imerode(mask_G,SEpix);
% 
% if debug
%     figure(13); imshow(mask_R); title('Red channel, masked: cleaning step 1 (imerode)');
%     figure(14); imshow(mask_G); title('Green channel, masked: cleaning step 1 (imerode)');
% end

%% RED/GREEN channel analysis
% % bwlabel and regionprops to get information
% [clusters_R num_R] = bwlabel(mask_R,4);
% [clusters_G num_G] = bwlabel(mask_G,4);
% stats_R = regionprops(clusters_R,'Area','Image');
% stats_G = regionprops(clusters_G,'Area');
% 
% area_R = [stats_R.Area];
% mean_R = mean(area_R);
% %additional_R = floor([stats_R(area_R > 250).Area]./250);
% additional_R = floor([stats_R(area_R > 400).Area]./400);
% num_R
% extra_R = sum(additional_R) % parameter tuned to sect3; pretty arbitrary value
% totalcells = num_R + extra_R - length(additional_R) % subtract length(additional_R) to prevent counting something twice

%%
%figure(15); imshow(stats_R(32).Image);