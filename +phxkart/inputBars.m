function H = inputBars(parent,position,player)
%INPUTBARS Draw once; update the patches from the actual filtered commands.
    panel = uipanel(parent,'Units','normalized','Position',position, ...
        'BorderType','none','BackgroundColor',[.055 .075 .105]);
    ax = axes(panel,'Position',[.025 .02 .95 .96],'XLim',[0 1],'YLim',[0 3], ...
        'Visible','off','Clipping','on');
    disableDefaultInteractivity(ax); ax.Toolbar.Visible = 'off'; hold(ax,'on');
    colors = [.2 .85 .45;1 .3 .25;.25 .75 1];
    H.fill = gobjects(1,3); H.label = gobjects(1,3);
    for k = 1:3
        y = 3-k;
        patch(ax,[0 1 1 0],y+[.08 .08 .34 .34],[.16 .20 .25],'EdgeColor','none');
        H.fill(k) = patch(ax,[0 0 0 0],y+[.08 .08 .34 .34],colors(k,:), ...
            'EdgeColor','none','Tag',sprintf('KartInput%d_%d',player,k));
        H.label(k) = text(ax,0,y+.66,'','Color',[.88 .93 .97], ...
            'FontName','Segoe UI','FontSize',10,'Interpreter','none', ...
            'VerticalAlignment','middle');
    end
    plot(ax,[.5 .5],[.035 .39],'Color',[.9 .93 .96],'LineWidth',1);
end
