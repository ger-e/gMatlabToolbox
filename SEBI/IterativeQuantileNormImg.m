% IterativeQuantileNormImg.m
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
% dependencies: quantilenorm from Biostatistics Toolbox
%
% 04/26/2011: Gerry wrote it

InputDir = 'D:\Gerry\SEBI norm\complete OB'; % absolute path to folder containing images
FileFormat = '.tif'; % image file format

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
    Dimensions = size(Img1);
    
    % note conversion to double
    ToNorm = double([Img1(:) Img2(:)]);
    
    % normalize
    NormD = quantilenorm(ToNorm);
    
    % reconstitute, make uint8 again  
    NormImg1 = uint8(reshape(NormD(:,1),Dimensions));
    NormImg2 = uint8(reshape(NormD(:,2),Dimensions));
    
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