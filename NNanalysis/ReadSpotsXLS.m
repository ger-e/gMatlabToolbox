function ReadSpotsXLS(Rootdirs,Names,Classifications,ScalingNSlice)
% ReadSpotsXLS.m
% 06/11/2010: Gerry wrote it
% 06/14/2010: Added functionality to get random distribution statistics
% 08/03/2010: Modified to work with NNmain as a function
% 08/20/2010: Modified to include more precise randomization statistics
% that take into account the scaling factor as well as the Z depth
%
% This script will read Excel spreadsheets of Spot statistics as outputted 
% by Imaris and extract the xyz coordinates of the spots and save them into
% a matrix
%
% Random Distribution Statistics-------------------------------------------
% This script will take an input black/white image with a specified ROI and
% randomly sprinkle a specified number of points within that ROI for a
% given named population. This script will then output the location of
% those points for later estimate of the random distribution for nearest
% neighbor analysis.
%
% Note: randomly generated points for random distribution statistics are
% given locations with integer values only!
% 
% To create the input image for the random distribution statistics
% 1) create WHITE borders of an ROI in imaris using the surfaces tool
% 2) put imaris on orthogonal view, 100% then fit to get bird's-eye view,
% and then output the image from imaris with all channels off and with the
% Zoom in Snapshot = 1.00 (100% snapshot); 72 dpi is OK.
% -------------------------------------------------------------------------

for c=1:length(Rootdirs)
    cd(Rootdirs{c});
    % load and get info for ROI for random distribution statistics
    Img = imread([Names{c} '_ROI.tif']);
    Img = Img(:,:,1); % just take the R channel from RGB
    temp = Img;
    for d=1:ScalingNSlice(c,4)
        Img(:,:,d) = temp;
    end
    indices = find(Img>0); % all indices in the ROI
    
    % sheet in spreadsheet you want to extract data from
    Sheet = 'Position';
    
    % read in the spot xyz position data
    for a=1:length(Classifications)
        eval(['test = xlsread(''' Classifications{a} ''',''Overall'');']);
        if test(1) % in case there are no cells of a particular classification
            eval([Classifications{a} '= xlsread(''' Classifications{a} ''',Sheet);']);
            eval([Classifications{a} '=' Classifications{a} '(:,1:3);']);
            eval([Classifications{a} '_Rand = zeros(size(' Classifications{a} '));'])
            indices = Shuffle(indices);
            eval(['numElements = size(' Classifications{a} ',1);'])
            for b=1:numElements
                [sub1 sub2 sub3] = ind2sub(size(Img),indices(b));
                eval([Classifications{a} '_Rand(b,1:3) = [sub1 sub2 sub3].*ScalingNSlice(c,1:3);'])
            end
        end
    end

    clear Sheet Img indices a b numElements sub1 sub2 sub3;
    save(Names{c});
end