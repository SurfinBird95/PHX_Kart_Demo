function G = drawKart(ax,color)
%DRAWKART Visual shell only; one PHX rigid body carries physical properties.
    G.root = hgtransform('Parent',ax);
    box(G.root,[0 0 .24],[1.48 .80 .13],[.15 .18 .21]);
    box(G.root,[.75 0 .24],[.28 1.1 .22],color);
    box(G.root,[-.2 .52 .28],[.8 .16 .25],color);
    box(G.root,[-.2 -.52 .28],[.8 .16 .25],color);
    box(G.root,[-.60 0 .25],[.14 1.05 .12],[.35 .38 .4]);
    G.brakeLights = gobjects(1,2);
    for side = 1:2
        y = (2*side-3)*.30;
        box(G.root,[-.75 y .31],[.06 .26 .14],[.06 .07 .08]);
        G.brakeLights(side) = box(G.root,[-.785 y .31],[.025 .21 .095],[.22 .015 .01]);
        set(G.brakeLights(side),'FaceLighting','none','Tag','KartBrakeLight');
    end
    box(G.root,[-.37 -.29 .44],[.32 .24 .30],[.35 .37 .39]);
    box(G.root,[-.12 0 .42],[.4 .38 .25],[.07 .09 .12]);
    box(G.root,[-.25 0 .64],[.13 .4 .4],[.07 .09 .12]);
    box(G.root,[.02 0 .61],[.32 .29 .32],color*.75);
    [x,y,z] = sphere(12);
    surf('Parent',G.root,'XData',x*.18-.08,'YData',y*.17,'ZData',z*.20+.96, ...
        'FaceColor',[.92 .94 .96],'EdgeColor','none');
    box(G.root,[.07 0 .98],[.1 .30 .095],[.10 .16 .23]);
    G.wheels = gobjects(1,4);
    pts = [.60 .56;.60 -.56;-.44 .56;-.44 -.56];
    for j = 1:4
        G.wheels(j) = hgtransform('Parent',G.root);
        [x,y,z] = cylinder(.14,14);
        surf('Parent',G.wheels(j),'XData',x,'YData',(z-.5)*.17,'ZData',y, ...
            'FaceColor',[.055 .060 .07],'EdgeColor','none');
        a = (0:13)'*2*pi/14;
        for side = [-1 1]
            patch('Parent',G.wheels(j),'XData',.14*cos(a),'YData',ones(14,1)*side*.085, ...
                'ZData',.14*sin(a),'FaceColor',[.075 .08 .09],'EdgeColor','none');
            patch('Parent',G.wheels(j),'XData',.07*cos(a),'YData',ones(14,1)*side*.086, ...
                'ZData',.07*sin(a),'FaceColor',[.55 .59 .64],'EdgeColor','none');
        end
        G.wheels(j).Matrix = makehgtform('translate',[pts(j,:) .17]);
    end
    G.points = pts;
end

function h = box(parent,c,s,color)
    v = [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1;-1 -1 1;1 -1 1;1 1 1;-1 1 1].*s/2+c;
    h = patch('Parent',parent,'Vertices',v,'Faces',[1 4 3 2;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8], ...
        'FaceColor',color,'EdgeColor','none','FaceLighting','gouraud');
end
