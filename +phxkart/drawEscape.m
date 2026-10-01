function drawEscape(ax,T)
%DRAWESCAPE Open paved escape lane and matching solid arrow barriers.
    if isempty(T.escape), return; end
    E = T.escape; n = size(E.xy,1);
    left = E.xy+E.width/2*E.normal; right = E.xy-E.width/2*E.normal;
    patch(ax,'Vertices',[left .02*ones(n,1);right .02*ones(n,1)], ...
        'Faces',[(1:n-1)' (2:n)' (n+2:2*n)' (n+1:2*n-1)'], ...
        'FaceColor',[.20 .23 .25],'EdgeColor','none','FaceLighting','none');
    for k = 1:numel(E.obstacles)
        O = E.obstacles(k); a = O.angle;
        R = [cos(a) -sin(a);sin(a) cos(a)];
        v = [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1;-1 -1 1;1 -1 1;1 1 1;-1 1 1].*O.size/2;
        v(:,1:2) = v(:,1:2)*R'+O.position; v(:,3) = v(:,3)+O.size(3)/2;
        patch(ax,'Vertices',v,'Faces',[1 4 3 2;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8], ...
            'FaceColor',[1 .76 .12],'EdgeColor',[.12 .13 .14],'FaceLighting','none');
        direction = sign(dot(O.gap-O.position,[-sin(a) cos(a)]));
        for offset = [-1.6 0 1.6]
            y = offset+direction*[-.55 .10 .10 .65 .10 .10 -.55]';
            z = [.37 .37 .20 .45 .70 .53 .53]';
            p = [-.34*ones(7,1) y]*R'+O.position;
            patch(ax,p(:,1),p(:,2),z,[.08 .09 .10],'EdgeColor','none','FaceLighting','none');
        end
    end
    % Yellow direction marks on the normal chicane.
    for g = T.branchGatePositions
        idx = T.gates(g); c = T.xy(idx,:); f = T.tangent(idx,:); side = T.normal(idx,:);
        arrow = c+[-1 -.20;.4 -.20;.4 -.65;1.2 0;.4 .65;.4 .20;-1 .20]*[f;side];
        patch(ax,arrow(:,1),arrow(:,2),.035*ones(7,1),[1 .86 .2],'EdgeColor','none','FaceLighting','none');
    end
end
