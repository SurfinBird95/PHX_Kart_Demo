function drawTrack(ax,T)
%DRAWTRACK Lightweight static scene shared by both views.
    hold(ax,'on');
    patch(ax,[-180 180 180 -180],[-180 -180 180 180],[-.08 -.08 -.08 -.08], ...
        [.19 .31 .24],'EdgeColor','none');
    n = size(T.xy,1); next = [2:n 1]';
    slope = tan(T.bank); edge = T.width/2+.55;
    for side = [-1 1]
        inner = T.xy+side*T.normal*T.width/2;
        outer = T.xy+side*T.normal*(T.width/2+.55);
        vertices = [inner (side*T.width/2-edge)*slope;outer (side*edge-edge)*slope];
        faces = [(1:n)' next next+n (1:n)'+n];
        colors = repmat([.91 .93 .91],n,1);
        colors(mod(floor((1:n)'/5),2)==0,:) = repmat([.85 .20 .20],sum(mod(floor((1:n)'/5),2)==0),1);
        patch(ax,'Vertices',vertices,'Faces',faces,'FaceVertexCData',colors, ...
            'FaceColor','flat','EdgeColor','none');
    end
    left = T.xy+T.normal*T.width/2; right = T.xy-T.normal*T.width/2;
    roadColors = [ .14 .17 .20]+T.gripBoost.*([.62 .075 .055]-[.14 .17 .20]);
    patch(ax,'Vertices',[left .015+(T.width/2-edge)*slope;right .015+(-T.width/2-edge)*slope], ...
        'Faces',[(1:n)' next next+n (1:n)'+n], ...
        'FaceVertexCData',[roadColors;roadColors],'FaceColor','interp','EdgeColor','none');
    phxkart.drawEscape(ax,T);
    if any(T.bank)
        outer = T.xy-T.normal*edge; foot = T.xy-T.normal*(edge+6);
        patch(ax,'Vertices',[outer -2*edge*slope;foot -.04*ones(n,1)], ...
            'Faces',[(1:n)' next next+n (1:n)'+n], ...
            'FaceColor',[.27 .35 .23],'EdgeColor','none');
        phxkart.drawBank(ax,T);
    end
    % Painted start stripe (road crossing is intentionally at grade).
    for row = 0:1
        for col = 0:11
            c = T.xy(1,:)+(row-.5)*.5*T.tangent(1,:)+(col-5.5)*T.width/12*T.normal(1,:);
            v = c+[-.25 -.5;.25 -.5;.25 .5;-.25 .5]*[T.tangent(1,:);T.normal(1,:)*T.width/12];
            shade = .12+.8*mod(row+col,2);
            patch(ax,v(:,1),v(:,2),.025*ones(4,1),[shade shade shade],'EdgeColor','none');
        end
    end
    % Trackside markers and a few low-poly trees, safely outside the road.
    for k = 1:40:n
        p = T.xy(k,:)+T.normal(k,:)*(T.width/2+2);
        z = phxkart.roadSurface(T,p);
        plot3(ax,[p(1) p(1)],[p(2) p(2)],z+[0 1.2],'Color',[.8 .86 .88],'LineWidth',2);
    end
    for k = 1:12
        a = k*2*pi/12; p = [88*cos(a) 73*sin(a)];
        if min(vecnorm(T.roadXY-p,2,2))<T.width/2+4, continue; end
        [x,y,z] = cylinder([2 0],7);
        surf(ax,x+p(1),y+p(2),z*6,'FaceColor',[.10 .24 .18], 'EdgeColor','none');
    end
    axis(ax,'equal'); axis(ax,[-120 120 -100 100 -1 30]); axis(ax,'vis3d');
    axis(ax,'off'); ax.Color = [.55 .70 .79]; ax.Projection = 'perspective';
    camup(ax,[0 0 1]); camva(ax,56);
    light(ax,'Position',[30 -40 80],'Style','infinite');
    lighting(ax,'gouraud');
    set(findobj(ax,'Type','patch'),'FaceLighting','none');
end
