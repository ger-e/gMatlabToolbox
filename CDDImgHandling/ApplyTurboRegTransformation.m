function ImgOut = ApplyTurboRegTransformation(ImgIn,table,Interpolate)
% function ImgOut = ApplyTurboRegTransformation(ImgIn,table,Interpolate)
% ~8/9/2017: Gerry wrote it
% This script will take in a single image slice and a table of
% transformations (NOT a transformation matrix, but the table exported by
% TurboReg), apply the transformation, and then return the transformed
% image (ImgOut). You can optionally specify whether you want subpixel
% interpolation

% apply the tranformation
sourceX0 = table(1,1); sourceY0 = table(1,2);
targetX0 = table(1,3); targetY0 = table(1,4);
sourceX1 = table(2,1); sourceY1 = table(2,2);
targetX1 = table(2,3); targetY1 = table(2,4);
sourceX2 = table(3,1); sourceY2 = table(3,2);
targetX2 = table(3,3); targetY2 = table(3,4);
dx1 = sourceX0 - targetX0;
dy1 = sourceY0 - targetY0;
% translation = sqrt(dx1^2+ dy1^2); % Amount of translation, in pixels.
dx = sourceX2 - sourceX1;
dy = sourceY2 - sourceY1;
sourceAngle = atan2(dy, dx);
dx = targetX2 - targetX1;
dy = targetY2 - targetY1;
targetAngle = atan2(dy, dx);
rotation = targetAngle - sourceAngle; % Amount of rotation, in radians.

shifteddata=ImgIn;

% translate with interpolation
% see: http://www.mathworks.com/matlabcentral/newsreader/view_thread/261037#720879
xshift=dx1;
yshift=dy1; % since shift is finer than sampling, sub-pixel shifting is required
xdata=[1 size(shifteddata,2)];
ydata=[1 size(shifteddata,1)];
T=maketform('affine',[1 0 0; 0 1 0; xshift yshift 1]);

% rotate with interpolation
degrotation = rotation*180/pi;
if Interpolate
    shifteddata = imrotate(shifteddata,degrotation,'bicubic','crop');
else
    shifteddata = imrotate(shifteddata,degrotation,'nearest','crop');
end

if Interpolate
    shifteddata=imtransform(shifteddata,T,'bicubic','XData',xdata,'YData',ydata);
else
    shifteddata=imtransform(shifteddata,T,'nearest','XData',xdata,'YData',ydata);
end

ImgOut = shifteddata;
end