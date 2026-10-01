function G = drawCourse(ax,T)
%DRAWCOURSE Ramp wedges, movable straw bales and overhead hammer frame.
    G=[]; if isempty(T.course), return; end
    C=T.course;
    for r=C.ramps
        f=[cos(r.yaw) sin(r.yaw)]; n=[-f(2) f(1)];
        x=[0 r.length r.length+r.descent]; z=[.025 r.height+.025 .025];
        xy=[r.center+x'*f-r.width/2*n;r.center+x'*f+r.width/2*n];
        patch(ax,'Vertices',[xy [z z]'],'Faces',[1 2 5 4;2 3 6 5], ...
            'FaceColor',[.90 .46 .09],'EdgeColor',[1 .78 .2],'LineWidth',1.5);
        for s=[-1 1]
            q=r.center+x'*f+s*r.width/2*n;
            patch(ax,q(:,1),q(:,2),z,[.34 .25 .12],'EdgeColor','none');
        end
    end
    G.hay=gobjects(1,size(C.hay,1));
    for k=1:numel(G.hay)
        G.hay(k)=hgtransform('Parent',ax);
        box(G.hay(k),[0 0 0],[1.8 1.2 1.1],[.73 .55 .22]);
        for x=[-.52 .52], box(G.hay(k),[x 0 0],[.09 1.22 1.12],[.32 .27 .14]); end
        for z=[-.35 -.15 .1 .3]
            line('Parent',G.hay(k),'XData',[-.88 .88],'YData',[-.606 -.606],'ZData',[z z], ...
                'Color',[.95 .77 .36]);
        end
    end
    side=[-sin(C.yaw) cos(C.yaw) 0];
    for s=[-1 1]
        p=C.pivot+s*6*side;
        box(ax,[p(1:2) C.pivot(3)/2],[.35 .35 C.pivot(3)],[.35 .40 .43]);
    end
    p=C.pivot;
    plot3(ax,p(1)+[-6 6]*side(1),p(2)+[-6 6]*side(2),[p(3) p(3)],'Color',[.85 .68 .12],'LineWidth',7);
    G.head=hgtransform('Parent',ax); box(G.head,[0 0 0],[1.1 2.4 1.1],[.85 .16 .12]);
    box(G.head,[0 0 0],[1.12 .35 1.12],[.2 .22 .25]);
    G.arm=plot3(ax,[0 0],[0 0],[0 0],'Color',[.35 .38 .40],'LineWidth',6);
end
function box(parent,p,s,c)
    v=[-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1;-1 -1 1;1 -1 1;1 1 1;-1 1 1].*s/2+p;
    patch('Parent',parent,'Vertices',v,'Faces',[1 2 3 4;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8], ...
        'FaceColor',c,'EdgeColor',c*.65);
end
