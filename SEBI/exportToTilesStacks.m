% this script will export zen files to tiles, but in either forward or reverse Z order
% 5/2011: updated to export to stacks

% image parameters
numSlices = 101; % number of slices
numChannels = 1; % number of channels
ImgName = 'Slab 14'; % image must have been exported previously as *.tif via Imaris

% tile parameters
TileDim = 512; % tile square size in pixels
XTileNum = 6; % number of tiles in x direction (Horizontal)
YTileNum = 6; % number of tiles in y direction (Vertical)

% export forward (1) for reverse (0)
FwdRev = 1;

% some calculations based upon tile parameters
TileNum = XTileNum*YTileNum; % total number of tiles

% for e=1:TileNum
%     mkdir(num2str(e));
% end
for n=1:numSlices
    for p=1:numChannels
        if FwdRev
            Img = imread([ImgName '_Z' num2str(n-1,'%0.3i') '.tif']);
        else
            Img = imread([ImgName '_Z' num2str(numSlices-n,'%0.3i') '.tif']);
        end
        for c=1:XTileNum
            for d=1:YTileNum
                Tile = Img(1+TileDim*(d-1):TileDim*d,1+TileDim*(c-1):TileDim*c,p);
                success = 0;
                while ~success
                    try                
%                         cd(num2str(d+YTileNum*(c-1)));
                        imwrite(uint8(Tile),[ImgName '_c' num2str(p-1) '_t' num2str(d+YTileNum*(c-1)) '.tiff'],'tif','Compression','none','Resolution',[96 96],'WriteMode','append');
                        success = 1;
%                 cd ..
                    catch
                        fprintf(1,'\nWrite Error, waiting 1sec to try again');
                        fprintf(1,'\nIt was: X%i Y%i Z%i Channel', c, d, n, p);
                        pause(1);
                    end   
                end
            end
        end
    end
end