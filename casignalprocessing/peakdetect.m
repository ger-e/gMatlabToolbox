function [peaks,valleys]=peakdetect(x)
% function [peaks,valleys]=peakdetect(x)
% 11/16/2015: Gerry optimized the code

x = x(:);
% [row,col]=size(x);
% if col>row,
%    x=x';
% end;

dif=100*diff(x);
% dif1=zeros(numel(dif)+1,1);
% dif2=zeros(numel(dif)+1,1);
% dif1(1:end-1) = dif;
% dif2(2:end) = dif;
dif1=[dif; 0];
dif2=[0; dif];
neg=dif1.*dif2;
%pks=find(neg<=0);
pks=find(neg<0);
% warning('off','last');
% onedetect=find(pks==1);
% warning('on','all');

% if 0,
% if length(onedetect),
%    pks=pks(find(pks~=1));
% end;
% lang=length(x);
% lastdetect=find(pks==lang);
% if length(lastdetect),
%    pks=pks(find(pks~=lang));
% end;
% end;

index=false(numel(pks),1);

for t=1:numel(pks)
    if dif2(pks(t))>0
		index(t)=1;
	elseif dif2(pks(t))<0
		index(t)=0;
	elseif dif2(pks(t))==0
        if dif1(pks(t))>0
			index(t)=0;
		elseif dif1(pks(t))<0
			index(t)=1;
        end
    end
end

% stretch=find(index==1);
peaks=pks(index);
% stretch=find(index==(-1));
valleys=pks(~index);
end
