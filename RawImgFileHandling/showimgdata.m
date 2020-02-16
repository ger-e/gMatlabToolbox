function showimgdata(Img,PauseTime,Type,Magnification)
% function showimgdata(Img,PauseTime,Type,Magnification)
% 11/25/2014: Gerry wrote it
% 4/7/2015: Gerry modified to allow smaller magnification (helps in the case
% where it just barely fits your window, but then matlab tries to move the
% window)
% This function will open up figure(1) and show a 'movie' of your data in
% Img. 
%
% Type = 1 -->Img must be an x by y by n matrix, where xy are your xy plane, and n
% is the frames (could be time, z, or both)
% Type = 2 -->Img is in struct outputted by tiffread30, of n length, and
% planar xy data are in Img(n).data
    
    figure(1);
    test = whos('Img');
    if strcmp(test.class,'logical')
        Low = 0; High = 1;
    else
        Low = min(Img(:));
        High = max(Img(:));
    end
    switch Type
        case 1
            while 1
                for a=1:size(Img,3)
                    imshow(Img(:,:,a),'DisplayRange',[Low High],'InitialMagnification',Magnification);
                    text(10,10,['Frame: ' num2str(a)],'color','w');
%                     colormap('jet');
                    pause(PauseTime);
                end
            end

        case 2
            while 1
                for b=1:length(Img)
                    imshow(Img(b).data,'DisplayRange',[Low High],'InitialMagnification',Magnification);
                    text(10,10,['Frame: ' num2str(a)],'color','w');
                    pause(PauseTime);
                end
            end
    end
end