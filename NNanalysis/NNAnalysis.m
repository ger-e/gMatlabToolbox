function NNAnalysis(Rootdirs,Names,Classifications,DataType)
% NNAnalysis.m
% 06/11/2010: Gerry wrote it
% 07/28/2010: Gerry modified to remove improper microns/pix scaling
% 08/03/2010: Gerry modified to work with NNmain.m calling it as a
% function.
%
% This script will call NearestNeighbor.m to calculate the nearest neighbor
% distances between the various progenitor subtypes (Classifications) and pooled
% from the datafiles (Rootdirs/Names).
%
% NOTE: You do NOT need to specify the microns/pix scaling factor because
% Imaris statistics output already does this for you

% for the actual data
for b=1:length(Rootdirs)
    load([Rootdirs{b} Names{b}]);
    for a=1:length(Classifications)
        if b==1
            if exist(Classifications{a},'var') % in case the current dataset does not have cells of a particular classification
                eval(['[NNdist meanNNdist sdNNdist modeNNdist] = NearestNeighbor(' Classifications{a} ');'])
                eval(['NNdist' Classifications{a} '= NNdist;'])
                eval(['meanNNdist' Classifications{a} '= meanNNdist;'])
                eval(['sdNNdist' Classifications{a} '= sdNNdist;'])
                eval(['modeNNdist' Classifications{a} '= modeNNdist;'])
            end
            eval(['clear ' Classifications{a}]); % clear out variables from the previous dataset
        else
            if exist(Classifications{a},'var') % in case the current dataset does not have cells of a particular classification            
                eval(['[NNdist meanNNdist sdNNdist modeNNdist] = NearestNeighbor(' Classifications{a} ');'])
                eval(['NNdist' Classifications{a} '= [NNdist' Classifications{a} ' NNdist];'])
                eval(['meanNNdist' Classifications{a} '= [meanNNdist' Classifications{a} ' meanNNdist];'])
                eval(['sdNNdist' Classifications{a} '= [sdNNdist' Classifications{a} ' sdNNdist];'])
                eval(['modeNNdist' Classifications{a} '= [modeNNdist' Classifications{a} ' modeNNdist];'])
            end
            eval(['clear ' Classifications{a}]); % clear out variables from the previous dataset            
        end
    end
end

% for the random data
for b=1:length(Rootdirs)
    load([Rootdirs{b} Names{b}]);
    for a=1:length(Classifications)
        if b==1
            if exist([Classifications{a} '_Rand'],'var') % in case the current dataset does not have cells of a particular classification
                eval(['[NNdist meanNNdist sdNNdist modeNNdist] = NearestNeighbor(' Classifications{a} '_Rand);'])
                eval(['NNdist' Classifications{a} '_Rand= NNdist;'])
                eval(['meanNNdist' Classifications{a} '_Rand= meanNNdist;'])
                eval(['sdNNdist' Classifications{a} '_Rand= sdNNdist;'])
                eval(['modeNNdist' Classifications{a} '_Rand= modeNNdist;'])
            end
        else
            if exist([Classifications{a} '_Rand'],'var') % in case the current dataset does not have cells of a particular classification
                eval(['[NNdist meanNNdist sdNNdist modeNNdist] = NearestNeighbor(' Classifications{a} '_Rand);'])
                eval(['NNdist' Classifications{a} '_Rand= [NNdist' Classifications{a} '_Rand NNdist];'])
                eval(['meanNNdist' Classifications{a} '_Rand= [meanNNdist' Classifications{a} '_Rand meanNNdist];'])
                eval(['sdNNdist' Classifications{a} '_Rand= [sdNNdist' Classifications{a} '_Rand sdNNdist];'])
                eval(['modeNNdist' Classifications{a} '_Rand= [modeNNdist' Classifications{a} '_Rand modeNNdist];'])
            end
        end
    end
end

% save all the NNAnalyzed data
save(['pooled_' DataType]);