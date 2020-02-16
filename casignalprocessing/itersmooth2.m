function outvec=itersmooth2(invec,maxiters)
% function outvec=itersmooth2(invec,maxiters)
% 11/16/2015: Gerry optimized code

%figure(6);clf;
%plot(invec);hold on;

for a2=1:maxiters
    [ppks,npks]=peakdetect(invec);
    if length(invec)>1
        if invec(2)<invec(1)
            ppks=[1;ppks];
        else
            npks=[1;npks];
        end
        if invec(length(invec))>invec(length(invec)-1)
            ppks=[ppks;length(invec)];
        else
            npks=[npks;length(invec)];
        end
    end
    for a1=1:length(ppks)
        range=(ppks(a1)-1):(ppks(a1)+1);
        stretch=find( (range>0) & (range<=length(invec)) );
        if ~isempty(stretch)
            temp = invec(range(stretch));
            temp2= sum(temp)/numel(temp); % this will run faster than the standard mean() function
            invec(ppks(a1))=temp2;
        end
    end
    for a1=1:length(npks)
        range=(npks(a1)-1):(npks(a1)+1);
        stretch=find( (range>0) & (range<=length(invec)) );
        if ~isempty(stretch)
            temp = invec(range(stretch));
            temp2= sum(temp)/numel(temp); % this will run faster than the standard mean() function
            invec(npks(a1))=temp2;
        end
    end
end
outvec=invec;

%plot(outvec,'r-');
end