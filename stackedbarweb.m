function h = stackedbarweb(data,errorL,errorU)
% function h = stackedbarweb(data,errorL,errorU)
% 2/25/2014: Gerry wrote it
% This function will take plot your bar graph as a stacked bar graph, and
% then add in error bars as specified by errorL and errorU. Note that
% size(errorL/U) should equal size(data).
    h.bars= bar(data,0.5,'stacked'); hold on;

    for a=1:length(h.bars)
        xcoords = get(get(h.bars(a),'children'), 'xdata'); % get x position of bars
        ycoords = get(get(h.bars(a),'children'), 'ydata'); % get y position of bars

        x = mean(xcoords([1 3],:));
        y = ycoords(2,:);

        h.errors(a)=errorbar(x,y,errorL(:,a),errorU(:,a),'k','linestyle','none');
    end
end