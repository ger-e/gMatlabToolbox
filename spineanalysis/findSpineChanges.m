% findSpineChanges.m
% 3/3/10: Gerry wrote it
% 3/17/10: Gerry fixed it (unanticipated pattern in StartEnds matrix)
% 3/19/10: Gerry fixed it again (unanticipated pattern in StartEnds matrix)
% 4/8/2010: Gerry fixed issues with false data due to non-cleared variables
% and artifacts due to excel spreadsheet overwriting; Also fixed issue
% where a spine would be denoted as stable if it was on the left side at
% one time point and the right side at the next time point, e.g.
% 4/12/2010: Gerry fixed serious issue in previous matrix splitting
% algorithm. Gerry decided to ditch that old buggy algorithm in favor of a
% much more elegant and straightforward algorithm using image processing
% toolbox =). Gerry is happy now.
%
% Dependencies: requires Matlab Image Processing Toolbox
%
% expected input: uint8 RGB image
% 
% origin should be in the B channel

% clear all variables before starting!!!
clear all;
close all;
clc;

% Things to edit-----------------------------------------------------------
Path = 'C:\Users\Gerry\Desktop\newdebugging\';
ImgName = 'GC4D2Array';
% ImgName = 'Array';
Extension = '.png';
SpineLocations = imread([Path ImgName Extension]); % load the image
MicronsPerPix = 10/152;

% NOTE: if you see the following error message, make sure to close the open
% excel spreadsheet with the same name as ImgName!!!
%     ??? Error using ==> movefile
%     The process cannot access the file because it is being used by another process.

% -------------------------------------------------------------------------

% find the origin
FindOrigin = sum(SpineLocations(:,:,3),2);
OriginIntensity = size(SpineLocations(:,:,3),2)*255;
OriginLocation = find(FindOrigin == OriginIntensity,1);

% find the number of time points
j = 1;
for i=1:size(SpineLocations,2)
    if (SpineLocations(end,i,3) == 0) && (i == 1)
        FindBorders(j) = 0;
    end
    if (SpineLocations(end,i,3) == 0) && (FindBorders(j) == 1)
        j = j + 1;
        FindBorders(j) = 0;
    end
    if (SpineLocations(end,i,3) == 255) && (FindBorders(j) == 0)
        j = j + 1;
        FindBorders(j) = 1;
    end
end
NumTimePts = sum(FindBorders == 0);

% find the borders between different time points
Edges = zeros(1,NumTimePts*2);
Edges(1) = 1;
Edges(end) = size(SpineLocations,2);
m = 2;
for k=1:size(SpineLocations,2)-1
    if SpineLocations(end,k,3) ~= SpineLocations(end,k+1,3)
        Edges(m) = k;
        m = m + 1;
    end
end

% find center of time point
TimePointCenter = zeros(1,NumTimePts);
for n=1:NumTimePts
    TimePointCenter(n) = floor((Edges(n+(n-1)) + Edges(n+1+(n-1)))/2);
end

% intialize the output matrices
OutputMatrixLeft = zeros(size(SpineLocations,1),NumTimePts);
OutputMatrixRight = zeros(size(SpineLocations,1),NumTimePts);

% now find the spines
for p=1:NumTimePts
    OutputMatrixLeft(:,p) = SpineLocations(:,TimePointCenter(p),1);
    OutputMatrixRight(:,p) = SpineLocations(:,TimePointCenter(p),2);
end

% OutputMatrixAll = OutputMatrixLeft + OutputMatrixRight;
% 4/8/10 fix
OutputMatrixLeftRight = zeros(size(OutputMatrixLeft,1),size(OutputMatrixLeft,2),2);
OutputMatrixLeftRight(:,:,1) = OutputMatrixLeft;
OutputMatrixLeftRight(:,:,2) = OutputMatrixRight;

%% ----------------------------------------------------------------------
% 4/12/10 new algorithm for splitting the matrix using bwlabel and
% image processing toolbox

for ii=1:2
    % now account for >1pix height of spine-denoting bars
    OutputMatrixAll = OutputMatrixLeftRight(:,:,ii);
    for r=1:size(OutputMatrixAll,2)
        for q=1:size(OutputMatrixAll,1)-1
            if (OutputMatrixAll(q,r) == 0) && (OutputMatrixAll(q+1,r) > 150)
                OutputMatrixAll(q,r) = 1;
            end
        end
    end

    OutputMatrixAll = (OutputMatrixAll == 1); % make things binary

    % get distances
    Distances = zeros(size(OutputMatrixAll));
    for t=1:size(OutputMatrixAll,2)
        Indices = find(OutputMatrixAll(:,t)>=0);
        Distances(:,t) = OutputMatrixAll(:,t).*Indices;
    end

    % now excise the intervening rows of zeros (collapse the matrix)
    indx = sum(Distances,2);
    indx = find(indx > 0);
    finalDistances = Distances(indx,:);

    % make a temp matrix that has twice the rows of the outputmatrix
    TempMatrix = zeros(size(OutputMatrixAll,1)*2,size(OutputMatrixAll,2));

    % then fill every other row (only odd rows) with all the data from
    % outputmatrix; this lets you use bwlabel on the matrix
    for iii=1:size(OutputMatrixAll,1)
        TempMatrix(iii+(iii-1),:) = OutputMatrixAll(iii,:);
    end

    % now isolate each instance of a spine
    IndvSpines = bwlabel(TempMatrix(:,:,1)',4); % note the transposition
    IndvSpines = IndvSpines'; % note the transposition

    % we don't need those intervening rows of zeros anymore, so collapse the matrix (again)
    indx2 = sum(IndvSpines,2);
    indx2 = find(indx2 > 0);
    IndvSpines2 = IndvSpines(indx2,:);

    % now make a new matrix to put all the split spine information in
    finalDistancesSplit = zeros(max(IndvSpines2(:)),size(IndvSpines2,2));

    % and then load this new matrix
    for kk=1:size(finalDistancesSplit,1)
        [row, col] = find(IndvSpines2 == kk);
        row2(1:numel(row)) = kk;
        finalDistancesSplit(row2,col) = finalDistances(row,col);
        clear row col row2;
    end
    
    % now just scale by the distance factor
    finalDistancesSplit = (OriginLocation-finalDistancesSplit);
    finalDistancesSplit(finalDistancesSplit == OriginLocation) = 0;
    finalDistancesSplit = finalDistancesSplit*MicronsPerPix;
    finalDistancesSplitBinary = (finalDistancesSplit > 0);
    
    if ii==1
        finalDistancesSplitDistances = sum(finalDistancesSplit,2)./sum(finalDistancesSplitBinary,2);
        finalDistancesSplitDistances = [finalDistancesSplitDistances finalDistancesSplitBinary];
    end
    if ii==2
        finalDistancesSplitDistances2 = [sum(finalDistancesSplit,2)./sum(finalDistancesSplitBinary,2) finalDistancesSplitBinary];
    end
end
%%

% 4/8/10 fix
% now combine the left and right matrices and sort by the distance column
finalDistancesSplitDistancesAll = [finalDistancesSplitDistances' finalDistancesSplitDistances2']';
finalDistancesSplitDistancesAll(:,1) = finalDistancesSplitDistancesAll(:,1)*-1;
finalDistancesSplitDistancesAll = sortrows(finalDistancesSplitDistancesAll,1);
finalDistancesSplitDistancesAll(:,1) = finalDistancesSplitDistancesAll(:,1)*-1;

% 4/8/10 fix
% and don't forget to remake your binary matrix
finalDistancesSplitBinary = finalDistancesSplitDistancesAll(:,2:end);

% 4/8/10 fix
% rename old spreadsheet if it already exists to avoid overwriting artifacts
if exist([ImgName '.xls'],'file')
    movefile([ImgName '.xls'],[ImgName '_' num2str(sum(clock)) '.xls']);
end

% write to spreadsheet
xlswrite([ImgName '.xls'],finalDistancesSplitDistancesAll,'BinaryMap');

%% call spineChanges
spineChanges(finalDistancesSplitBinary,ImgName);