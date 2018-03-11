% IterativeQuantileNormImg2.m
% 04/26/2011: Gerry wrote the original script
% 08/22/2011: Gerry wrote the updated v2 script
%
% This script will perform quantile normalization on 3D images on pairs of
% slices at a time for many iterations. It will ultimately converge on the
% true quantilenorm of the image if you were to process the entire image at
% once. Benefits of using this script: allows you to normalize large
% datasets that can't all be loaded into memory
%
% Since each iteration is technically independent of the previous, you can
% open up multiple matlabs at once to converge on the normalized image
% faster.
% 
% Improvements of this script over IterativeQuantileNormImg: this script
% allows you to feed in images of different sizes. It will still feed
% quantilenorm vectors of the same length--but the smaller image will have
% been padded with numbers randomly drawn from the entire distribution of
% values in the smaller image. These padding numbers will then be removed
% when finally reconstructing the normalized images. If your images satisfy
% the assumptions of quantile normalization in general, then your images
% should, in theory, satisfy the assumptions required for this method to be
% valid. That is, the TRUE intensity distributions of your images should be
% mostly equal (on average across all images), but they aren't equal in
% your actual images (which is why you are quantile normalizing). Thus, it
% is fine to just randomly sample values from the intensity distribution of
% the smaller image, because all the values have the same statistics.
%
% dependencies: quantilenorm from Biostatistics Toolbox

InputDir = 'C:\Users\Gerry\Desktop'; % absolute path to folder containing images
FileFormat = '.tif'; % image file format
bitLevel = 16; % bitlevel of your images

cd(InputDir)
ImgList = dir(['*' FileFormat]);

% initialize random number generator
RandSeed = sum(100*clock);
rand('state',RandSeed);

for i=1:length(ImgList)*100
    
    % load two random slices
    Pick1 = ceil(rand*length(ImgList));
    Pick2 = ceil(rand*length(ImgList));
    
    success = 0;
    while ~success
        try
            Img1 = imread(ImgList(Pick1).name);
            Img2 = imread(ImgList(Pick2).name);
            success = 1;
        catch
            fprintf('\nRead Error, waiting 2sec to try again\n');
            pause(2);
        end
    end
    
    % keep track of dimensions to put things back together
    DimensionsImg1 = size(Img1);
    DimensionsImg2 = size(Img2);
    
    % figure out which image is larger, so you can add dummy values as needed
    Difference = length(Img2(:))-length(Img1(:));
    if Difference>0 % img2 is larger
        AddValsIndx = ceil(rand(abs(Difference),1).*length(Img1)); % pick values from img1 randomly
        AddVals = Img1(AddValsIndx); % get the values
        Img1 = [Img1(:)' AddVals(:)']'; % stick them on
    elseif Difference<0 % img1 is larger
        AddValsIndx = ceil(rand(abs(Difference),1).*length(Img2)); % pick values from img2 randomly
        AddVals = Img2(AddValsIndx); % get the values
        Img2 = [Img2(:)' AddVals(:)']'; % stick them on
    end % else they are same size, so do nothing
    
    % note conversion to double
    ToNorm = double([Img1(:) Img2(:)]);
    
    % normalize
    NormD = quantilenorm(ToNorm);
    
    % remove dummy values, if needed
    NormImg1 = NormD(:,1); % get img1
    NormImg2 = NormD(:,2); % get img2
    if Difference>0 % img2 is larger
        NormImg1 = NormImg1(1:end-abs(Difference)); % remove dummy values
    elseif Difference<0 % img1 is larger
        NormImg2 = NormImg2(1:end-abs(Difference)); % remove dummy values
    end % else no dummy values, do nothing
    
    % reconstitute, make uint8/16/32 again  
    eval(['NormImg1 = uint' num2str(bitLevel) '(reshape(NormImg1,DimensionsImg1));']);
    eval(['NormImg2 = uint' num2str(bitLevel) '(reshape(NormImg2,DimensionsImg2));']);
    
    success = 0;
    while ~success
        try
            imwrite(NormImg1,ImgList(Pick1).name,'tiff','Compression','none','Resolution',[96 96]);
            imwrite(NormImg2,ImgList(Pick2).name,'tiff','Compression','none','Resolution',[96 96]);
            success = 1;
        catch
            fprintf('\nWrite Error, waiting 2sec to try again\n');
            pause(2);
        end
    end
    
    if mod(i,50)
        fprintf('.');
    else
        fprintf('%d\n.',i);
    end
end