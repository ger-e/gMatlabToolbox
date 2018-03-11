function exportImarisInv2_1(Points,FileName,Size,Color)
% function exportImarisInv2_1(Points,FileName,Size,Color)
% 4/22/2010: Gerry wrote it
% 5/2015: Gerry modified to give option of choosing your own color for the
% points
%
% This function will take a MxNxD matrix (Points) and create an inventor
% file (FileName) for import to Imaris, with a specified point size (Size).
% Colors of the point(s) will be determined randomly.  The M dimension is
% from point 1 to point n; the N dimension are your x,y,z coordinates,
% respectively; and the D dimension is from point cluster 1 to n.

% make a new inventor file
fid = fopen([FileName '.iv'],'wt');

% print header information
fprintf(fid,'#Inventor V2.1 ascii\n');

% print objects
for a=1:size(Points,3)
    CurrentPoints = Points(:,:,a);
    Test = sum(CurrentPoints,2);
    CurrentPoints = CurrentPoints(Test>0,:); % exclude points at the origin (0,0,0)

    % specify color of points randomly only if color not already specified
    if ~exist('Color','var')
        Color = rand(1,3);
    end
    
    % print objects
    fprintf(fid,'DEF soShowHideSep Separator {\n');
    fprintf(fid,'  renderCaching OFF\n');
    fprintf(fid,'  boundingBoxCaching OFF\n');
    fprintf(fid,'\n');
    fprintf(fid,'  Separator {\n');
    fprintf(fid,'\n');
    fprintf(fid,'  }\n');
    fprintf(fid,'  DEF bpDataSetsInventor Group {\n');
    fprintf(fid,'\n');
    fprintf(fid,'  }\n');
    fprintf(fid,'  DEF bpPointsViewerInventor Separator {\n');
    fprintf(fid,'\n');
    fprintf(fid,'    Switch {\n');
    fprintf(fid,'      whichChild -3\n');
    fprintf(fid,'\n');
    fprintf(fid,'      Switch {\n');
    fprintf(fid,'        whichChild 0\n');
    fprintf(fid,'\n');
    fprintf(fid,'        Group {\n');
    fprintf(fid,'\n');
    fprintf(fid,'          DEF bpColorSwitchSetInventor Separator {\n');
    fprintf(fid,'            renderCaching OFF\n');
    fprintf(fid,'            boundingBoxCaching OFF\n');
    fprintf(fid,'\n');
    fprintf(fid,'            Callback {\n');
    fprintf(fid,'\n');
    fprintf(fid,'            }\n');
    fprintf(fid,'            DEF ColorSwitch_cColorClass Separator {\n');
    fprintf(fid,'\n');
    fprintf(fid,'              Material {\n');
    fprintf(fid,'                ambientColor 0.2 0.2 0.2\n');
    % Specify color------------------------------------------------------------
    fprintf(fid,['                diffuseColor ' num2str(Color(1)) ' ' num2str(Color(2)) ' ' num2str(Color(3)) '\n']);
    %--------------------------------------------------------------------------
    fprintf(fid,'                specularColor 0 0 0\n');
    fprintf(fid,'                emissiveColor 0 0 0\n');
    fprintf(fid,'                shininess 0.2\n');
    fprintf(fid,'                transparency 0\n');
    fprintf(fid,'\n');
    fprintf(fid,'              }\n');
    fprintf(fid,'              DEF ObjSet_0 Group {\n');
    fprintf(fid,'\n');
    fprintf(fid,'                DrawStyle {\n');
    % Specify point size-------------------------------------------------------
    fprintf(fid,['                  pointSize ' num2str(Size) '\n']);
    %--------------------------------------------------------------------------
    fprintf(fid,'\n');
    fprintf(fid,'                }\n');
    fprintf(fid,'                Coordinate3 {\n point [ ');
    % Add in your points-------------------------------------------------------
    for b=1:size(CurrentPoints,1)
        fprintf(fid,'%10.10f %10.10f %10.10f ,\n',CurrentPoints(b,1),CurrentPoints(b,2),CurrentPoints(b,3));
    end
    %--------------------------------------------------------------------------
    fprintf(fid,' ]\n');
    fprintf(fid,'\n');
    fprintf(fid,'                }\n');
    fprintf(fid,'                PointSet {\n');
    fprintf(fid,'\n');
    fprintf(fid,'                }\n');
    fprintf(fid,'              }\n');
    fprintf(fid,'            }\n');
    fprintf(fid,'            DEF ColorSwitch_cColorClass Separator {\n');
    fprintf(fid,'\n');
    fprintf(fid,'              Material {\n');
    fprintf(fid,'                diffuseColor 1 1 0\n');
    fprintf(fid,'                specularColor 1 1 1\n');
    fprintf(fid,'                emissiveColor 0.30000001 0.30000001 0\n');
    fprintf(fid,'\n');
    fprintf(fid,'              }\n');
    fprintf(fid,'              DEF ObjectsSetInventor Group {\n');
    fprintf(fid,'\n');
    fprintf(fid,'                DrawStyle {\n');
    % Specify point size-------------------------------------------------------
    fprintf(fid,['                  pointSize ' num2str(Size) '\n']);
    %--------------------------------------------------------------------------
    fprintf(fid,'\n');
    fprintf(fid,'                }\n');
    fprintf(fid,'                Coordinate3 {\n');
    fprintf(fid,'                  point [  ]\n');
    fprintf(fid,'\n');
    fprintf(fid,'                }\n');
    fprintf(fid,'                PointSet {\n');
    fprintf(fid,'\n');
    fprintf(fid,'                }\n');
    fprintf(fid,'              }\n');
    fprintf(fid,'            }\n');
    fprintf(fid,'          }\n');
    fprintf(fid,'        }\n');
    fprintf(fid,'      }\n');
    fprintf(fid,'    }\n');
    fprintf(fid,'  }\n');
    fprintf(fid,'\n');
    fprintf(fid,'  DEF bpTracksViewerInventor Separator {\n');
    fprintf(fid,'\n');
    fprintf(fid,'  }\n');
    fprintf(fid,'}\n\n');
end

% close the file
fclose(fid);