function MatOut = BinImg2D(MatIn,p,q)
% function MatOut = BinImg2D(MatIn,p,q)
% 8/5/2017: A simple function to bin an image in 2D, assuming dimensions m
% and n are divisible by binning p and q.

%Example for pxq binning
% p = 16; q = 16;
[m,n]=size(MatIn); %M is the original matrix

MatIn=sum( reshape(MatIn,p,[]) ,1 );
MatIn=reshape(MatIn,m/p,[])'; %Note transpose

MatIn=sum( reshape(MatIn,q,[]) ,1);
MatOut=reshape(MatIn,n/q,[])'; %Note transpose
MatOut = MatOut./(p*q); % return the mean
end