% image parameters
numSlices = 94; % number of slices
numChannels = 1; % number of channels
ImgName = '3'; % image must have been exported previously as *.tif via Imaris

% tile parameters
TileDim = 512; % tile square size in pixels
XTileNum = 3; % number of tiles in x direction
YTileNum = 5; % number of tiles in y direction

% some calculations based upon tile parameters
TileNum = XTileNum*YTileNum; % total number of tiles

for e=1:TileNum
    mkdir(num2str(e));
end
for n=1:numSlices
    for p=1:numChannels
        Img = imread([ImgName '_Z' num2str(n-1,'%0.3i') '.tif']);
        for c=1:XTileNum
            for d=1:YTileNum
                Tile = Img(1+TileDim*(d-1):TileDim*d,1+TileDim*(c-1):TileDim*c);
                cd(num2str(d+YTileNum*(c-1)));
                imwrite(uint8(Tile),[ImgName '_c' num2str(p-1) '_z' num2str(n-1) '_t' num2str(d+YTileNum*(c-1)) '.tiff'],'tiff');                
                cd ..
            end
        end
    end
end