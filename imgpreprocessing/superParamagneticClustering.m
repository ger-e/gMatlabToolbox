% superParamagneticClustering.m
% 4/22/2010: Gerry wrote it; Debugging provided by Ting
% 4/25/2010: Fixed major bugs in 'try...catch' portion
% 5/15/2010: this is the most recent version of the script
% This function will apply the superParamagnetic clustering algorithm to
% cluster a set of points without supervision. For more details on the
% algorithm used, see
% (1) M Blatt et al., "Superparamagnetic Clustering of Data", 1996
% (2) RQ Quiroga et al., "Unsupervised Spike Detection and Sorting with
% Wavelets and Superparamagnetic Clustering", 2004
%
% Note: 'state' and 'label' are sometimes used interchangeably in this
% script's annotations
% Note: pt-pt (point to point) correlation as defined in this script is
% simply the number of times two given points changed together

% clear all junk
clear all;
close all;
clc;

% Parameters to change-----------------------------------------------------
% -------------------------------------------------------------------------
% initialize random number generator
% RandSeed = sum(100*clock);
% rand('state',RandSeed);

% input: matrix of x,y,z coords of each spot
% Spots = zeros(n,3); % n spots, 3 for x,y,z
load spots.mat;

% shuffle to assess order of points effects
% newindx = 1:size(Spots,1);
% shuffledindx = Shuffle(newindx);
% Spots = Spots(shuffledindx,:);

RandSeed = 16534;
% RandSeed = sum(100*clock);
rand('state',RandSeed);
% dummy data for algorithm debugging
% cluster1 = rand(3,200)*10+180;
% cluster2 = rand(3,100)*2+70;
% cluster3 = rand(3,45)*4+1;
% 
% input = [cluster1 cluster2 cluster3];
% input = input';
% Spots = input;

newindx = 1:size(Spots,1);
shuffledindx = Shuffle(newindx);
Spots = Spots(shuffledindx,:);
%-----------------------------------

% define neighbor threshold, k
kay = 11;

% define number of labels, q
que = 20;

% define a good estimate of the temperature, T, based on q
% tee = exp(-0.5)/(4*log(1+que^0.5));
tee = 0.01;

% define threshold of correlation for clustering, theta
% theta = 100;

% define number of iterations for Monte Carlo simulation
NIterations = 500;

% Perform some initial calculations (nearest neighbor (NN) via Euclidean
% distances and strength between nearest neighbors)------------------------
% -------------------------------------------------------------------------
% define the dimensions of your image
xDim = max(Spots(:,1))-min(Spots(:,1));
yDim = max(Spots(:,2))-min(Spots(:,2));
zDim = max(Spots(:,3))-min(Spots(:,3));

% calculate the distance between each point and every other point
distances = zeros(size(Spots,1),size(Spots,1));
for a=1:size(Spots,1)
    for b=1:size(Spots,1)
        distances(a,b) = d2points3d(Spots(a,1),Spots(a,2),Spots(a,3),Spots(b,1),Spots(b,2),Spots(b,3));
    end
end

% create a parallel matrix of indices so you can recover point identity
indices = zeros(size(distances));
for c=1:size(indices,1)
    indices(c,:) = c;
end

% then combine this matrix with the distance matrix
distancesWindices = distances;
distancesWindices(:,:,2) = indices;

% on a per point (columnwise) basis, sort distances to find the k
% nearest neighbors
for d=1:size(distancesWindices,2)
    temp = distancesWindices(:,d,:); % temp is Nx1xM
    temp = reshape(temp,size(temp,1),size(temp,3)); % temp is NxM
    temp = sortrows(temp,1); % sort by column 1
    temp = reshape(temp,size(temp,1),1,size(temp,2)); % temp is Nx1xM again
    distancesWindices(:,d,:) = temp; % put the sorted column back into the matrix
end

% then find the k nearest neighbors for each point
NNeighbor = distancesWindices(2:kay+1,:,:); % 2:kay+1 because the first item will always be 0, i.e. the distance between the point and itself

% calculate the average nearest neighbor distance, a
temp2 = NNeighbor(:,:,1); % ignore the indices
aye = mean(temp2(:));

% calculate the strength, J, between each point and every other point iff
% they are nearest neighbors, else leave J = 0
% Note: this choose what strength function we wish to use
jay = zeros(size(distances));
for e=1:size(NNeighbor,2)
    for f=1:size(NNeighbor,1)
        jay(NNeighbor(f,e,2),e) = (1/kay)*exp((-NNeighbor(f,e,1)^2)/(2*aye^2));
    end
end

% assign labels, S from 1 to q to each point randomly
% Note: we use 'rand' and sample from a uniform distribution, i.e. there
% should be roughly 1/20 (5%) of each value 1 to q
Es = ceil(rand(size(distances,1),1)*que);

% initialize a matrix to keep track of the point to point correlation (i.e.
% the number of times points change together; the more they change
% together, the higher the correlation)
PrelimClusters = zeros(size(distances));

% Monte Carlo simulation to estimate pt-pt correlation---------------------
% -------------------------------------------------------------------------

for k=1:NIterations
%     Es = ceil(rand(size(distances,1),1)*que); % mod 4
    ExAye = ceil(rand*size(distances,1)); % choose a random point, xi
    OldState = Es(ExAye); % store its original label
    Es(ExAye) = ceil(rand*que); % choose a new label
    NewState = Es(ExAye); % assign the new label

    % index of all NN's that had the same old label as xi
    ThingsToChange1 = find(jay(ExAye,Es == OldState) > 0);
    ChangeNo=find(Es==OldState);
    ThingsToChange=ChangeNo(ThingsToChange1);
    
    CantChangeAgain = ExAye; % start building your vector of points that have already changed and can't change again
    Count3 = 1;
    JustChanged = zeros(1,size(distances,1)); % also keep track of what points just changed at this second order iteration; maximum size of JustChanged

    % for point xi, change (with some probability) all the NN's with the same label as xi originally had
    for g=1:length(ThingsToChange)
        Pee = 1-exp(-jay(ExAye,ThingsToChange(g))/tee);

        if rand <= Pee
            Es(ThingsToChange(g)) = NewState; % mod 1
            PrelimClusters(ExAye,ThingsToChange(g)) = PrelimClusters(ExAye,ThingsToChange(g)) + 1; % keep track of how many times things change together
            CantChangeAgain = [CantChangeAgain ThingsToChange(g)];
            JustChanged(Count3) = ThingsToChange(g);
            Count3 = Count3 + 1;
        end
    end

    % collapse JustChanged (remove zeros at the end)
%     temp = find(JustChanged > 0);
%     JustChanged = JustChanged(temp);

    % now start a while loop to explore all the NN's of the NN's, etc
    NotDone = 1;
    Count = 2;
    Count2 = 1;

    while NotDone
        try
            temp = find(JustChanged(Count2,:) > 0);
            JustChangedTemp = JustChanged(Count2,temp);
            for h=1:length(JustChangedTemp)
                ThingsToChange2 = find(jay(JustChangedTemp(h),:) > 0); % mod 2
                for j=1:length(CantChangeAgain) % omit things that have already changed
                    Test = find(ThingsToChange2 == CantChangeAgain(j));
                    if ~isempty(Test)
                        ThingsToChange2 = [ThingsToChange2(1:Test(1)-1) ThingsToChange2(Test(1)+1:end)];
                    end
                end
                if isempty(ThingsToChange2)
                    % do nothing
                else
                    Count4 = 1;
                    JustChanged(Count,:) = 0;
                    for i=1:length(ThingsToChange2)
                        Pee = 1-exp(-jay(JustChangedTemp(h),ThingsToChange2(i))/tee);
                        if rand <= Pee
                            Es(ThingsToChange2(i)) = NewState; % mod 3
                            PrelimClusters(JustChangedTemp(h),ThingsToChange2(i)) = PrelimClusters(JustChangedTemp(h),ThingsToChange2(i)) + 1;
                            CantChangeAgain = [CantChangeAgain ThingsToChange2(i)];
                            JustChanged(Count,Count4) = ThingsToChange2(i);
                            Count4 = Count4 + 1;
                        end
                    end
                    Count = Count + 1;
                end
            end
            Count2 = Count2 + 1;
        catch
            NotDone = 0;
        end
    end
    fprintf(1,'.');
    if ~mod(k,50)
        fprintf(1,'\n');
    end
end

%% Now figure out your clusters, export, and plot---------------------------
% -------------------------------------------------------------------------
Clusters = PrelimClusters;
Clus = zeros(size(Spots,1),size(Spots,2),size(Spots,1)); % initialize matrix to put cluster points in
% load spots;
% shuffle to see random effects at this level
% newindx = 1:size(Clusters,1);
% shuffledindx = Shuffle(newindx);
% Clusters = Clusters(shuffledindx,:);
% Spots = Spots(shuffledindx,:);

theta = 250; % 50, 100,150,200,250,300,350,400,450,500

for bb=1:size(Spots,1)
    if Clusters(bb,bb) < 0; % this will be < 0 if you've already taken that point into account
        % do nothing
    else
        Clusters(:,bb) = -bb;
        temp = find(Clusters(bb,:)>theta); % for the current point, find its friends
        if ~isempty(temp) % if the point has no friends, don't do anything
            Clusters(:,temp) = -bb; % mark the friends' column with a negative number; note that this propagates to future iterations of bb
            while 1 % now loop through to cover all the possible friends
                indicesToSearch = [];
                for aa=1:length(temp)
                    temp2 = find(Clusters(temp(aa),:)>theta); % friends of friends
                    if ~isempty(temp2) % if no friends of friends, don't do anything
                        Clusters(:,temp2) = -bb; % mark friends' column with a negative marker
                        indicesToSearch = [indicesToSearch temp2]; % friends of friends to search next
                    end
                end
                if isempty(indicesToSearch) % if no further friends of friends, then you're done!
                    break;
                else
                    temp = indicesToSearch; % ...otherwise keep going
                end
            end
            SpotsInClus = find(Clusters(bb,:)==-bb); % now extract all the friends of point bb that you marked
            Clus(1:length(SpotsInClus),:,bb) = Spots(SpotsInClus,:); % and then extract the actual coordinates
        end
    end
    fprintf(1,'*');
    if ~mod(bb,50)
        fprintf(1,'\n');
    end    
end

% excise regions where there are no clusters
temp = find(Clus(1,1,:)>0);
FinalClus = Clus(:,:,temp);

% plot your clusters
% FYI: clusters in black will be false negatives!!
figure(3); plot(Spots(:,1),Spots(:,2),'k.'); hold on;

for r=1:size(FinalClus,3)
    figure(3); plot(FinalClus(:,1,r),FinalClus(:,2,r),'.','Color',rand(1,3)); hold on;
end

% save the cluster matrix
save FinalClusters FinalClus;

% export your clusters to Imaris Inventor file
% exportImarisInv2_1(FinalClus,'FinalClusters',5);