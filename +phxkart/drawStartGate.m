function G = drawStartGate(ax,T)
%DRAWSTARTGATE Five paired signal lamps facing the starting grid.
    root = hgtransform('Parent',ax,'Matrix',makehgtform( ...
        'translate',[T.xy(1,:) 0],'zrotate',atan2(T.tangent(1,2),T.tangent(1,1))));
    for side = [-1 1]
        block(root,[0 side*(T.width/2+.8) 1.75],[.25 .25 3.5],[.34 .38 .42]);
    end
    block(root,[0 0 3.45],[.30 T.width+1.85 .24],[.34 .38 .42]);
    block(root,[-.08 0 3.05],[.34 3.3 .70],[.035 .04 .05]);
    G.lamps = gobjects(5,2);
    a = linspace(0,2*pi,25);
    for k = 1:5
        for row = 1:2
            G.lamps(k,row) = patch('Parent',root, ...
                'XData',-.26*ones(size(a)), ...
                'YData',(k-3)*.62+.115*cos(a), ...
                'ZData',2.9+(row-1)*.30+.115*sin(a), ...
                'FaceColor',[.13 .018 .015],'EdgeColor','none', ...
                'FaceLighting','none','Tag',sprintf('KartStartLamp%d',k));
        end
    end
end
function block(parent,c,s,color)
    v = [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1;-1 -1 1;1 -1 1;1 1 1;-1 1 1].*s/2+c;
    patch('Parent',parent,'Vertices',v,'Faces',[1 4 3 2;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8], ...
        'FaceColor',color,'EdgeColor','none','FaceLighting','gouraud');
end
