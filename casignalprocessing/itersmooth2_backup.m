function outvec=itersmooth2_backup(invec,maxiters)

%figure(6);clf;
%plot(invec);hold on;

for a2=1:maxiters,
    [ppks,npks]=peakdetect(invec);
    if length(invec)>1,
        if invec(2)<invec(1),
            ppks=[1;ppks];
        else
            npks=[1;npks];
        end
        if invec(length(invec))>invec(length(invec)-1),
            ppks=[ppks;length(invec)];
        else
            npks=[npks;length(invec)];
        end
    end
    for a1=1:length(ppks),
        range=(ppks(a1)-1):(ppks(a1)+1);
        stretch=find( (range>0) & (range<=length(invec)) );
        if length(stretch)>0,
            invec(ppks(a1))=mean(invec(range(stretch)));
        end
    end
    for a1=1:length(npks),
        range=(npks(a1)-1):(npks(a1)+1);
        stretch=find( (range>0) & (range<=length(invec)) );
        if length(stretch)>0,
            invec(npks(a1))=mean(invec(range(stretch)));
        end
    end
end
outvec=invec;

%plot(outvec,'r-');
