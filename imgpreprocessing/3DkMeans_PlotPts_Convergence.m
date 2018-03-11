% 3DkMeans.m
% This script will take in a matrix of points in 3-dimensions of format
% x,y,z along columns and point # along rows, i.e.
%    x y z
% P1 1 2 3
% P2 3 7 4
% Pn . . .
%
% You will specify (1) number of seed points and (2) number of iterations
% and then the script will use a k-means method in 3-dimensions to estimate
% the centroids of clusters of your input points. Distances between points
% are purely Euclidean and centroids of cluters of points are calculated by
% taking the mean x, y, and z coordinates of all the points in a given
% cluster.
%
% This script will output two 3D plots: (1) the input points, (2) the
% centroid of the calculated point clusters. This script will also output
% to a text file which you can copy and paste point locations into an
% Imaris inventor file (*.iv) for direct import into Imaris (in order to do
% this, you need to create a 'ghost' or 'shell' inventor file using the
% Surpass Scene Spot object that you derived the input matrix of points
% from; you can then copy and paste the outputted text file contents to the
% matrix that defines the Spot points).
%
% Some notes
% 1) This script will excise any seed points that don't have any closest
% points at any given iteration. The number of points excised does tend to
% vary depending on the seed of the psuedo-random number generator, but the
% distribution of number of excised points does appear somewhat normal
% (based on a sample of 20 random number generator seeds). That said, this
% means that you may not need to be too precise with your starting seed
% locations, as bad seeds will get removed. This might require a bit more
% fiddling
%
% Todo
% 1) Create a method to figure out the optimal number of starting seeds

for f=1:1
    for g=1:1
        % initialize random number generator
        % RandSeed = 212039180;
        RandSeed = sum(100*clock);
        rand('state',RandSeed);

        % input: matrix of x,y,z coords of each spot
        % Spots = zeros(n,3); % n spots, 3 for x,y,z
        load spots.mat;

        % defn the dimensions of your image
        xDim = max(Spots(:,1))-min(Spots(:,1));
        yDim = max(Spots(:,2))-min(Spots(:,2));
        zDim = max(Spots(:,3))-min(Spots(:,3));

        % define number of cluster seed points
        Seed = 200*g;
        Seed = ones(Seed,3);

        % define number of iterations to reach convergence
        NIterations = 20;

        % randomly choose starting location of seed points
        Seed = rand(size(Seed)).*Seed;
        Seed(:,1) = ceil(Seed(:,1).*xDim);
        Seed(:,2) = ceil(Seed(:,2).*yDim);
        Seed(:,3) = ceil(Seed(:,3).*zDim);

        %--------------RUN KMEANS--------------------------------------------------
        for i=1:NIterations
            % calculate distance from each point to each seed point in 3D
            % aka the 'Euclidean distance'
            distances = zeros(size(Spots,1),size(Seed,1));
            for a=1:size(Spots,1)
                for b=1:size(Seed,1)
                    distances(a,b) = d2points3d(Spots(a,1),Spots(a,2),Spots(a,3),Seed(b,1),Seed(b,2),Seed(b,3));
                end
            end

            % find the nearest seed point to each point
            nearestSeed = min(distances,[],2);
            distancesBinary = distances;

            for c=1:length(nearestSeed)
                nearestSeedToPoint = find(distances(c,:) == nearestSeed(c));
                nearestSeedToPoint = nearestSeedToPoint(1); % only take the first nearest seed in case the point is equidistant from two or more seeds
                distancesBinary(c,1:nearestSeedToPoint-1) = 0;
                distancesBinary(c,nearestSeedToPoint+1:end) = 0;
                distancesBinary(c,nearestSeedToPoint) = 1;
            end

            % then create a new estimate of the seed point based upon the centroid of its (the seed point's) closest spots
            for d=1:size(Seed,1)
                SeedPoints = find(distancesBinary(:,d) == 1);
                if d==1 && i==NIterations
                    NumSeedPoints = zeros(1,size(Seed,1));
                end
                if i==NIterations % plot 2d projection of a given cluster
                    figure(1); plot(Spots(SeedPoints,1),Spots(SeedPoints,2),'.','Color',rand(1,3)); hold on;
                    NumSeedPoints(d) = sum(distancesBinary(:,d) == 1);
                end
                newSeedX = mean(Spots(SeedPoints,1));
                newSeedY = mean(Spots(SeedPoints,2));
                newSeedZ = mean(Spots(SeedPoints,3));
                Seed(d,:)= [newSeedX newSeedY newSeedZ];
                if d==1 % plot x coord of seed 1 and 2's location to look for convergence
                    figure(2); plot(i,Seed(1,1),'.'); hold on;
                end
                if d==2
                    figure(3); plot(i,Seed(2,1),'.'); hold on;
                end
            end
            
            if i==NIterations
                AverageNumCellsPerClust = mean(NumSeedPoints)
                StdDevNumCellsPerClust = std(NumSeedPoints)
            end
            
            % collapse the Seed matrix to weed out Seeds that have no points near them
            RemoveNaN = isnan(Seed);
            RemoveNaN = sum(RemoveNaN,2);
            indx = find(RemoveNaN == 0);
            Seed = Seed(indx,:);

            % print progress every iteration
            if ~mod(i,50)
                fprintf(1,'%d\n',i);
            else
                fprintf(1,'.');
            end
        end
        %%
        %--------------OUTPUT------------------------------------------------------
        % plot the original spots and the resulting cluster locations
        % figure(1); plot3(Spots(:,1),Spots(:,2),Spots(:,3),'k*');
        % figure(2); plot3(Seed(:,1),Seed(:,2),Seed(:,3),'k*');

        % now output the cluster centers to a format that can be copied into an
        % Imaris inventor file (*.iv)
%         fid = fopen(['clusterCentroids' num2str(f) '_' num2str(g) '.txt'],'wt');
%         for e=1:size(Seed,1)
%             fprintf(fid,'%10.10f %10.10f %10.10f ,\n',Seed(e,1),Seed(e,2),Seed(e,3));
%         end
%         fclose(fid);

        save(['randSeedTest' num2str(f) '_' num2str(g)]);
        clear all;
    end
end

fprintf(1,'\n----------Done!----------\n');