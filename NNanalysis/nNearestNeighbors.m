function nNearestNeighbors(Rootdirs,Names,Classifications,DataType)
% nNearestNeighbors.m
% 07/28/2010: Gerry wrote it earlier, but only commented it on this date
% 08/03/2010: Modified to work on pooled data (single data code is
% commented out on very bottom) and to be called by NNmain.m
%
% This script will output a matrix and plot graphs for the n nearest
% neighbors for the desired input matrices of points

for e=1:length(Rootdirs)
    % load the data
    load([Rootdirs{e} Names{e}]);

    for d=1:length(Classifications)
        eval(['Spots =' Classifications{d} ';'])
        distances = zeros(size(Spots,1),size(Spots,1));
        for a=1:size(Spots,1)
            for b=1:size(Spots,1)
                distances(a,b) = d2points3d(Spots(a,1),Spots(a,2),Spots(a,3),Spots(b,1),Spots(b,2),Spots(b,3));
            end
        end

        subplot(4,3,d); hold on;
        for c=1:size(distances,1)
            plot(0:size(distances,2)-1,sort(distances(c,:)),'k')
            title([Classifications{d} ' - ' DataType]);
        end
        distances = sort(distances,2);

    %     plot(0:size(distances,2)-1,mean(distances,1),'r','LineWidth',5);

        % set axes properies
        set(gca,'Xlim',[0 20]);
        set(gca,'Ylim',[0 100]);

    end
end

% rootdir = '\\SONGMINGONE\Sun(K)\1-DGTangentialCut\0-DataAnalysis\NearestNeighbor\';
% 
% % 6mo data
% % dirs = {'AgedFull6mo3RH_Sect11\AgedFull6mo3RH_Sect11.mat' 'AgedFull6mo1RH_Sect09\AgedFull6mo1RH_Sect09.mat'};
% dirs = {'AgedFull6mo5RH_Sect06\AgedFull6mo5RH_Sect06.mat'};
% 
% % 2mo data
% % dirs = {'SetFull8RH_Sect05\SetFull8RH_Sect05.mat'};
% 
% % standard file names
% % FileNames = {'NesRad' 'NesRadMcm2' 'NesRadMcm2Tbr2' 'NesTangMcm2' ...
% %     'NesTangMcm2Tbr2' 'Mcm2' 'Mcm2Tbr2' 'DcxTangStubMcm2Tbr2' ...
% %     'DcxTangLongMcm2Tbr2' 'DcxTangLongMcm2' 'DcxTangLong' 'DcxRad'};
% FileNames = {'NesRad' 'NesRadMcm2' 'NesTangMcm2' ...
%     'Mcm2' 'Mcm2Tbr2' 'DcxTangStubMcm2Tbr2' ...
%     'DcxTangLongMcm2Tbr2' 'DcxTangLongMcm2' 'DcxTangLong' 'DcxRad'};
% 
% % load the data
% load([rootdir dirs{1}]);
% 
% for d=1:length(FileNames)
%     eval(['Spots =' FileNames{d} ';'])
%     distances = zeros(size(Spots,1),size(Spots,1));
%     for a=1:size(Spots,1)
%         for b=1:size(Spots,1)
%             distances(a,b) = d2points3d(Spots(a,1),Spots(a,2),Spots(a,3),Spots(b,1),Spots(b,2),Spots(b,3));
%         end
%     end
% 
%     distances = distances.*MicronsPerPix;
% 
%     subplot(4,3,d); hold on;
%     for c=1:size(distances,1)
%         plot(0:size(distances,2)-1,sort(distances(c,:)),'k')
%         title(FileNames{d});
%     end
%     distances = sort(distances,2);
% 
% %     plot(0:size(distances,2)-1,mean(distances,1),'r','LineWidth',5);
% 
%     % set axes properies
%     set(gca,'Xlim',[0 20]);
%     set(gca,'Ylim',[0 100]);
%     
% end