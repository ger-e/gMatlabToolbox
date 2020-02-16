function [peaks,valleys]=peakdetect_backup(x);

[row,col]=size(x);
if col>row,
   x=x';
end;

dif=100*diff(x);
dif1=[dif; 0];
dif2=[0; dif];
neg=dif1.*dif2;
%pks=find(neg<=0);
pks=find(neg<0);
warning off;
onedetect=find(pks==1);
warning on;

if 0,
if length(onedetect),
   pks=pks(find(pks~=1));
end;
lang=length(x);
lastdetect=find(pks==lang);
if length(lastdetect),
   pks=pks(find(pks~=lang));
end;
end;

index=zeros(length(pks),1);

for t=1:length(pks),
	if dif2(pks(t))>0,
		index(t)=1;
	elseif dif2(pks(t))<0,
		index(t)=(-1);
	elseif dif2(pks(t))==0,
		if dif1(pks(t))>0,
			index(t)=(-1);
		elseif dif1(pks(t))<0,
			index(t)=1;
		end;
	end;
end;

stretch=find(index==1);
peaks=pks(stretch);
stretch=find(index==(-1));
valleys=pks(stretch);
