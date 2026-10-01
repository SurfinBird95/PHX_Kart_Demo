function T = track(name)
%TRACK Closed road geometry; ordered gates disambiguate the level crossing.
    t = (0:719)'*2*pi/720;
    switch lower(string(name))
        case "technical"
            % Periodic cubic B-spline: smooth esses, a long start straight,
            % fast outer bends and a tighter infield, without crossings.
            control = [-35 -48;-5 -48;35 -48;65 -40;76 -15;66 7; ...
                42 10;42 28;60 44;40 60;12 57;0 35;-12 22; ...
                -30 30;-40 53;-66 46;-78 20;-66 0;-44 4; ...
                -28 -10;-43 -25;-65 -25;-70 -44;-55 -48];
            count = size(control,1); samples = 60;
            u = (0:samples-1)'/samples;
            basis = [(1-u).^3,3*u.^3-6*u.^2+4, ...
                -3*u.^3+3*u.^2+3*u+1,u.^3]/6;
            dense = zeros(count*samples,2);
            for k = 1:count
                indices = mod((k-2:k+1),count)+1;
                dense((k-1)*samples+(1:samples),:) = basis*control(indices,:);
            end
            dense(end+1,:) = dense(1,:);
            arc = [0;cumsum(vecnorm(diff(dense),2,2))];
            xy = interp1(arc,dense,(0:719)'*arc(end)/720,'linear');
        case "obstacle"
            a=linspace(-pi/2,pi/2,181)'; b=linspace(pi/2,3*pi/2,181)';
            dense=[linspace(-22,22,181)' -14*ones(181,1); ...
                22+14*cos(a(2:end)) 14*sin(a(2:end)); ...
                linspace(22,-22,181)' 14*ones(181,1); ...
                -22+14*cos(b(2:end)) 14*sin(b(2:end))];
            dense=unique(dense,'rows','stable'); dense(end+1,:)=dense(1,:);
            arc=[0;cumsum(vecnorm(diff(dense),2,2))];
            [arc,keep]=unique(arc,'stable'); dense=dense(keep,:);
            xy=interp1(arc,dense,(0:719)'*arc(end)/720);
        case "oval"
            xy = [42*cos(t), 25*sin(t)];
        case "eight"
            xy = [48*sin(t), 30*sin(2*t)];
            % Put the finish, gantry and grid on the right-hand loop,
            % clear of the central crossing; preserve the road geometry.
            xy = circshift(xy,-180,1);
        otherwise
            error('phxkart:Track','Unknown track: %s',name);
    end
    base = xy;
    if strcmpi(name,'technical')
        section = xy(:,2)<-38 & xy(:,1)>-5 & xy(:,1)<55;
        xy(section,2) = xy(section,2)-18*sin(pi*(xy(section,1)+5)/60).^2;
    end
    d = circshift(xy,-1)-circshift(xy,1);
    tangent = d./vecnorm(d,2,2);
    T.xy = xy;
    T.tangent = tangent;
    T.normal = [-tangent(:,2),tangent(:,1)];
    T.width = 9;
    T.course = [];
    if strcmpi(name,'obstacle')
        T.course.ramps=struct('center',{},'yaw',{},'length',{},'height',{},'width',{},'descent',{});
        T.course.ramps(1)=struct('center',[-5 -14],'yaw',0,'length',6,'height',1.1,'width',6,'descent',1.5);
        T.course.ramps(2)=struct('center',[8 14],'yaw',pi,'length',4.5,'height',.8,'width',5.5,'descent',1.5);
        T.course.hay=[-5 14 0;-10 11.7 .25;-13 16 -.2;-34 3 .4;-35 -1 -.3];
        T.course.pivot=[36 0 5]; T.course.yaw=pi/2;
        T.course.arm=4.2; T.course.amplitude=.85; T.course.period=3.6;
    end
    T.bank = zeros(size(xy,1),1);
    T.bankWalls = struct('position',{},'angle',{},'size',{},'base',{});
    if strcmpi(name,'eight')
        % Bank the far left bend; the crossing and start stay at grade.
        q = max(0,min(1,(-xy(:,1)-20)/28));
        T.bank = -18*pi/180*q.^2.*(3-2*q);
        edge = xy-T.normal*(T.width/2+.85);
        indices = find(q>.015);
        for k = indices(1):4:indices(end)-4
            last = min(k+4,indices(end));
            a = edge(k,:); b = edge(last,:);
            baseHeight = (T.width+1.1)*max(abs(tan(T.bank([k last]))));
            O.position = (a+b)/2; O.angle = atan2(b(2)-a(2),b(1)-a(1));
            O.size = [norm(b-a)+.12 .42 1.15]; O.base = baseHeight;
            T.bankWalls(end+1) = O;
        end
    end
    blend = min(1,abs(T.bank)/(6*pi/180));
    T.gripBoost = blend.^2.*(3-2*blend);
    T.name = char(name);
    T.gates = 1:30:720;
    T.length = sum(vecnorm(circshift(xy,-1)-xy,2,2));
    T.roadXY = xy;
    T.escape = [];
    T.gateAlternatives = cell(1,numel(T.gates));
    T.branchGatePositions = [];
    if strcmpi(name,'technical')
        entry = nearest(base,[-8 -48]); exit = nearest(base,[58 -43]);
        E.xy = base(entry:exit,:);
        d = [E.xy(2,:)-E.xy(1,:);E.xy(3:end,:)-E.xy(1:end-2,:);E.xy(end,:)-E.xy(end-1,:)];
        E.tangent = d./vecnorm(d,2,2); E.normal = [-E.tangent(:,2) E.tangent(:,1)];
        E.width = T.width;
        E.obstacles = struct('position',{},'angle',{},'size',{},'gap',{});
        branchIndices = zeros(1,3);
        gaps = cell(1,3);
        for k = 1:3
            idx = nearest(base,[12+(k-1)*13 -48]);
            local = idx-entry+1; side = (-1)^k;
            E.obstacles(k).position = E.xy(local,:)+side*1.8*E.normal(local,:);
            E.obstacles(k).angle = atan2(E.tangent(local,2),E.tangent(local,1));
            E.obstacles(k).size = [.65 5.4 .70];
            E.obstacles(k).gap = E.xy(local,:)-side*2.8*E.normal(local,:);
            gaps{k} = struct('center',E.obstacles(k).gap,'tangent',E.tangent(local,:), ...
                'normal',E.normal(local,:),'halfWidth',1.65);
            branchIndices(k) = idx;
        end
        T.gates = sort(unique([T.gates(T.gates<entry | T.gates>exit),entry,branchIndices,exit]));
        T.gateAlternatives = cell(1,numel(T.gates));
        for k = 1:3
            g = find(T.gates==branchIndices(k));
            T.gateAlternatives{g} = gaps{k};
            T.branchGatePositions(k) = g;
        end
        T.escape = E;
        T.roadXY = [xy;E.xy];
    end
end
function idx = nearest(xy,p)
    [~,idx] = min(sum((xy-p).^2,2));
end
