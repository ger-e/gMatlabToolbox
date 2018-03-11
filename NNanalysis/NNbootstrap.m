function NNbootstrap(Classifications,DataType)
% NNbootstrap.m
% 06/11/2010: Gerry wrote it
% 08/03/2010: Gerry modified it to work with NNmain.m calling it as a
% function
% 03/08/2011: Gerry added clarification on the bootstrapping technique
%
%
% This script will bootstrap nearest neighbor (NN) distance measurments
% such that the *means* can be plotted against each other. This
% bootstrapping method will sample from the original distributions with
% replacement and take/store the mean distance after each iteration.  The
% resulting distribution will be the distribution of the estimated mean;
% the median will be the actual estimated mean.
% 
% If you want to simply plot the distributions against each other (in the
% case that the original sample data are not sample equally (i.e. you have
% more NNdistance measurements for one cell type than another)), then you
% should just pull samples from the original distribution, with
% replacement, at each iteration. This way you will faithfully recreate the
% original distribution. Using the method in the previous paragraph (taking
% and storing the means at each iteration) will NOT faithfully recapitulate
% the original distribution because it is a distribution of MEANS not the
% actual data
%
% Note: you'd need to have run NNAnalysis first in order to run this script

load(['pooled_' DataType]); % load the datafile created by NNAnalysis.m
prefix = 'NNdist';

% seed the random number generator
Seed = sum(100*clock);
rand('state',Seed);

% number of bootstrap iterations
NIterations = 1000;

% for actual data----------------------------------------------------------
for j=1:length(Classifications)
    eval([[prefix Classifications{j} '_bootstrap'] '= zeros(NIterations,1);'])
    eval([[prefix Classifications{j} '_temp'] '= zeros(size(' [prefix Classifications{j}] '));'])
    for i=1:NIterations
        eval(['tempy=length(' [prefix Classifications{j}] ');'])
        for h=1:tempy
            eval(['pickNum = ceil(rand*length(' [prefix Classifications{j}] '));']) % pick a number with replacement
            eval([[prefix Classifications{j} '_temp'] '(h) =' [prefix Classifications{j}] '(pickNum);'])
        end
        eval([[prefix Classifications{j} '_bootstrap'] '(i) = mean(' [prefix Classifications{j} '_temp'] ');']) % now store the mean from this bootstrap iteration
    end
    fprintf(1,'.');
end

% now put everything in a single matrix for plotting
for k=1:length(Classifications)
    if k==1
        eval(['NNAll =' [prefix Classifications{k} '_bootstrap'] ';'])
    else
        eval(['NNAll = [NNAll ' [prefix Classifications{k} '_bootstrap'] '];'])
    end
end

% and then boxplot it
figure(1); boxplot(NNAll,Classifications); set(gca, 'YLim', [0 140]); title('NNAll');
figure(2); boxplot(NNAll); set(gca, 'YLim', [0 140]); title('NNAll');

% for random distribution statistics---------------------------------------
for j=1:length(Classifications)
    eval([[prefix Classifications{j} '_Rand_bootstrap'] '= zeros(NIterations,1);'])
    eval([[prefix Classifications{j} '_Rand_temp'] '= zeros(size(' [prefix Classifications{j}] '_Rand));'])
    for i=1:NIterations
        eval(['temp=length(' [prefix Classifications{j}] '_Rand);'])
        for h=1:temp
            eval(['pickNum = ceil(rand*length(' [prefix Classifications{j}] '_Rand));']) % pick a number with replacement
            eval([[prefix Classifications{j} '_Rand_temp'] '(h) =' [prefix Classifications{j}] '_Rand(pickNum);'])
        end
        eval([[prefix Classifications{j} '_Rand_bootstrap'] '(i) = mean(' [prefix Classifications{j} '_Rand_temp'] ');']) % now store the mean from this bootstrap iteration
    end
    fprintf(1,'.');
end

% now put everything in a single matrix for plotting
for k=1:length(Classifications)
    if k==1
        eval(['NNAll_Rand =' [prefix Classifications{k} '_Rand_bootstrap'] ';'])
    else
        eval(['NNAll_Rand = [NNAll_Rand ' [prefix Classifications{k} '_Rand_bootstrap'] '];'])
    end
end

% and then boxplot it
figure(3); boxplot(NNAll_Rand,Classifications); set(gca, 'YLim', [0 140]); title('NNAll--Random');
figure(4); boxplot(NNAll_Rand); set(gca, 'YLim', [0 140]); title('NNAll--Random');

% save the bootstrapped information
save(['pooled_bootstrap_' DataType],'NNAll');