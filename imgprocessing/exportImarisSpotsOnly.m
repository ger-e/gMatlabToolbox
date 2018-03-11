function exportImarisSpotsOnly(Points,FileName,Size)
% function exportImarisSpotsOnly(Points,FileName,Size)
% 5/15/2015: Gerry wrote it based upon exportImarisInv2_1
% This function will take a MxNxD matrix (Points) and output a text file
% that can be manually copied and pasted into a ghost spots object in a
% *.imx file (e.g. make a spots object with just a couple points, export
% scene from imaris to *.imx, then just replace the point positions with
% the text exported from this script).
%
% Note that points at the origin are excluded by default
%
% The M dimension is from point 1 to point n; the N dimension are your 
% x,y,z coordinates, respectively; and the D dimension is from point
% 1 to n.

% make a new inventor file
fid = fopen([FileName '.iv'],'wt');

% print header information
% fprintf(fid,'#Inventor V2.1 ascii\n');

% print objects
for a=1:size(Points,3)
    CurrentPoints = Points(:,:,a);
    Test = sum(CurrentPoints,2);
    CurrentPoints = CurrentPoints(Test>0,:); % exclude points at the origin (0,0,0)
    
    % Add in your points-------------------------------------------------------
    for b=1:size(CurrentPoints,1)
        fprintf(fid,'<point position="');
        fprintf(fid,'%10.10f %10.10f %10.10f',CurrentPoints(b,1),CurrentPoints(b,2),CurrentPoints(b,3));
        fprintf(fid,['" radius="' num2str(Size) '" timeIndex="0"/>\n']);
    end
    %--------------------------------------------------------------------------

end

% close the file
fclose(fid);