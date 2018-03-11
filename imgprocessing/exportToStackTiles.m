% 5/2011: Gerry wrote it
% This script will take tiff series exported from Imaris and create tiff
% stacks on a per tile basis.  It also includes important protection
% against write errors that Matlab will encounter if windows tries to read
% from the tiff stacks while matlab is writing to them.

% image parameters
numSlices = 126; % number of slices
numChannels = 1; % number of channels
ImgName = 'two'; % image must have been exported previously as *.tif via Imaris

% tile parameters
TileDim = 512; % tile square size in pixels
XTileNum = 4; % number of tiles in x direction
YTileNum = 4; % number of tiles in y direction

% some calculations based upon tile parameters
TileNum = XTileNum*YTileNum; % total number of tiles

for n=1:numSlices
    for p=1:numChannels
        Img = imread([ImgName '_Z' num2str(n-1,'%0.3i') '.tif']);
%         Img = imread([ImgName '_C' num2str(p-1) '_Z' num2str(n-1,'%0.3i') '.tif']); % for multiple channels
        for c=1:XTileNum
            for d=1:YTileNum
                Tile = Img(1+TileDim*(d-1):TileDim*d,1+TileDim*(c-1):TileDim*c);
                success = 0;
                while ~success
                    try
                        imwrite(uint8(Tile),[ImgName '_c' num2str(p-1) '_t' num2str(d+YTileNum*(c-1)) '.tiff'],'tif','Compression','none','Resolution',[96 96],'WriteMode','append');
                        success = 1;
                    catch
                        fprintf(1,'\nWrite Error, waiting 1sec to try again');
                        fprintf(1,'\nIt was: X%i Y%i Z%i', c, d, n);
                        pause(1);
                    end
                end
            end
        end
    end
end