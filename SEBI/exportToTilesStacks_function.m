function exportToTilesStacks_function(InputImgName,numChannels,bitLevel,TileDim)
% this script will export zen files to tiles, but in either forward or reverse Z order
% 5/2011: updated to export to stacks
% 6/2011: changed to version that runs as a function; function assumes you
% are in the root directory of the images you wish to process
% 6/29/2011: updated to be able to deal with n numChannels
% 8/17/2011: updated to take in bitLevels: note must be uint8,16,32,64 only
%
% image parameters
% numSlices = 101; % number of slices
numSlices = size(dir('*.tif'),1)/numChannels;  % number of slices
% numChannels = 1; % number of channels
ImgName = InputImgName; % image must have been exported previously as *.tif via Imaris

% tile parameters
% TileDim = 512; % tile square size in pixels

% account for different numbers of channels
if numChannels == 1
    TempImg = imread([ImgName '_Z' num2str(1,'%0.3i') '.tif']);
else
    TempImg = imread([ImgName '_C' num2str(0) '_Z' num2str(1,'%0.3i') '.tif']);
end

XTileNum = size(TempImg,2)/TileDim; % number of tiles in x direction (Horizontal)
YTileNum = size(TempImg,1)/TileDim; % number of tiles in y direction (Vertical)
% XTileNum = 6; % number of tiles in x direction (Horizontal)
% YTileNum = 6; % number of tiles in y direction (Vertical)

% export forward (1) for reverse (0)
FwdRev = 1;

mkdir('Individual stacks');
for n=1:numSlices
    for p=1:numChannels
        if FwdRev
            if numChannels == 1
                Img = imread([ImgName '_Z' num2str(n-1,'%0.3i') '.tif']);
            else
                Img = imread([ImgName '_C' num2str(p-1) '_Z' num2str(n-1,'%0.3i') '.tif']);
            end
        else
            if numChannels == 1
                Img = imread([ImgName '_Z' num2str(numSlices-n,'%0.3i') '.tif']);
            else
                Img = imread([ImgName '_C' num2str(p-1) '_Z' num2str(numSlices-n,'%0.3i') '.tif']);
            end
        end
        for c=1:XTileNum
            for d=1:YTileNum
                Tile = Img(1+TileDim*(d-1):TileDim*d,1+TileDim*(c-1):TileDim*c);
%                 fprintf(1,['\n\nmax:' num2str(max(Tile(:))) '\nmin:' num2str(min(Tile(:))) '\nrange:' num2str(range(Tile(:)))]);
%                 fprintf(1,'\nexpect: 65536,0,65536');
                success = 0;
                while ~success
                    try                
                        cd('Individual stacks');
                        eval(['imwrite(uint' num2str(bitLevel) '(Tile),[ImgName ''_c'' num2str(p-1) ''_t'' num2str(d+YTileNum*(c-1)) ''.tiff''],''tif'',''Compression'',''none'',''Resolution'',[96 96],''WriteMode'',''append'');'])
                        success = 1;
                        cd ..
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