% NNvoronoi.m
% standard names and their colors
Colors(1,:) = [0 1 0]; % NesRad
Colors(2,:) = [0.5 1 0]; % NesRadMcm2
Colors(3,:) = [1 1 0]; % NesRadMcm2Tbr2
Colors(4,:) = [1 0.5 0]; % NesTangMcm2
Colors(5,:) = [1 0 0]; % NesTangMcm2Tbr2
Colors(6,:) = [1 0 0.5]; % Mcm2Tbr2
Colors(7,:) = [0.8 0 0.4]; % Mcm2
Colors(8,:) = [1 0 1];  %DcxTangStubMcm2Tbr2
Colors(9,:) = [0.5 0 1]; % DcxTangLongMcm2Tbr2
Colors(10,:) = [0 0 1]; % DcxTangLongMcm2
Colors(11,:) = [0 0.5 1]; % DcxTangLong
Colors(12,:) = [0 1 1]; % DcxRad

% combine all NesRadial and plot
NesRadAll = [NesRad' NesRadMcm2' NesRadMcm2Tbr2']';
voronoi(NesRadAll(:,1),NesRadAll(:,2));
hold on; plot(NesRadMcm2(:,1),NesRadMcm2(:,2),'r.');
plot(NesRadMcm2Tbr2(:,1),NesRadMcm2Tbr2(:,2),'g.');
hold off;

% combine all Tbr2 and plot
Tbr2All = [NesRadMcm2Tbr2' NesTangMcm2Tbr2' Mcm2Tbr2' DcxTangStubMcm2Tbr2' DcxTangLongMcm2Tbr2']';
voronoi(Tbr2All(:,1),Tbr2All(:,2));
hold on; plot(NesRadMcm2Tbr2(:,1),NesRadMcm2Tbr2(:,2),'y.');
hold on; plot(NesTangMcm2Tbr2(:,1),NesTangMcm2Tbr2(:,2),'g.');
hold on; plot(Mcm2Tbr2(:,1),Mcm2Tbr2(:,2),'r.');
hold on; plot(DcxTangStubMcm2Tbr2(:,1),DcxTangStubMcm2Tbr2(:,2),'b.');
hold on; plot(DcxTangLongMcm2Tbr2(:,1),DcxTangLongMcm2Tbr2(:,2),'c.');

% combine all Mcm2 and plot
Mcm2All = [NesRadMcm2' NesRadMcm2Tbr2' NesTangMcm2' NesTangMcm2Tbr2' Mcm2' Mcm2Tbr2' DcxTangStubMcm2Tbr2' ...
    DcxTangLongMcm2Tbr2' DcxTangLongMcm2']';
voronoi(Mcm2All(:,1),Mcm2All(:,2));
hold on; plot(NesRadMcm2(:,1),NesRadMcm2(:,2),'.','Color',Colors(2,:));
hold on; plot(NesRadMcm2Tbr2(:,1),NesRadMcm2Tbr2(:,2),'.','Color',Colors(3,:));
hold on; plot(NesTangMcm2(:,1),NesTangMcm2(:,2),'.','Color',Colors(4,:));
hold on; plot(NesTangMcm2Tbr2(:,1),NesTangMcm2Tbr2(:,2),'.','Color',Colors(5,:));
hold on; plot(Mcm2Tbr2(:,1),Mcm2Tbr2(:,2),'.','Color',Colors(6,:));
hold on; plot(Mcm2(:,1),Mcm2(:,2),'.','Color',Colors(7,:));
hold on; plot(DcxTangStubMcm2Tbr2(:,1),DcxTangStubMcm2Tbr2(:,2),'.','Color',Colors(8,:));
hold on; plot(DcxTangLongMcm2Tbr2(:,1),DcxTangLongMcm2Tbr2(:,2),'.','Color',Colors(9,:));
hold on; plot(DcxTangLongMcm2(:,1),DcxTangLongMcm2(:,2),'.','Color',Colors(10,:));

% combine all Dcx and plot
DcxAll = [DcxTangStubMcm2Tbr2' DcxTangLongMcm2Tbr2' DcxTangLongMcm2' DcxTangLong' DcxRad']';
voronoi(DcxAll(:,1),DcxAll(:,2));
hold on; plot(DcxTangStubMcm2Tbr2(:,1),DcxTangStubMcm2Tbr2(:,2),'.','Color',Colors(8,:));
hold on; plot(DcxTangLongMcm2Tbr2(:,1),DcxTangLongMcm2Tbr2(:,2),'.','Color',Colors(9,:));
hold on; plot(DcxTangLongMcm2(:,1),DcxTangLongMcm2(:,2),'.','Color',Colors(10,:));
hold on; plot(DcxTangLong(:,1),DcxTangLong(:,2),'.','Color',Colors(11,:));

% blah = imread('SetFull8RH_Sect05_ROI_flip.tif');
% [sub1 sub2] = find(blah(:,:,1)>1);
% plot(sub2,sub1,'s');

% set axes properies
set(gca,'visible','off');
set(gca,'color',[1 1 1]);
set(gcf,'color',[1 1 1]);
set(gcf,'InvertHardCopy','off'); % prevent Matlab from auto-changing background to white
axis equal; % make a square plot

