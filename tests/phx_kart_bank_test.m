function report = phx_kart_bank_test
%PHX_KART_BANK_TEST Surface continuity, downhill force, solid wall and previews.
    T = phxkart.track('eight');
    assert(abs(min(T.bank)+18*pi/180)<1e-12 && T.bank(1)==0);
    for name = ["oval","technical"]
        flat = phxkart.track(name);
        assert(~any(flat.bank) && isempty(flat.bankWalls));
    end
    heights = zeros(720,1);
    for k = 1:720
        [heights(k),grade] = phxkart.roadSurface(T,T.xy(k,:));
        M = phxkart.surfacePose(T,T.xy(k,:),atan2(T.tangent(k,2),T.tangent(k,1)));
        assert(all(isfinite(M),'all') && norm(M(1:3,1:3)'*M(1:3,1:3)-eye(3))<1e-10);
        assert(norm(M(1:3,3)-[-grade 1]'/norm([-grade 1]))<1e-10);
    end
    assert(max(abs(diff([heights;heights(1)])))<.06,'Bank transition must be continuous.');
    [height,grade,gripScale] = phxkart.roadSurface(T,[-48 0]);
    assert(abs(gripScale-1.55)<1e-10);
    [~,~,flatGrip] = phxkart.roadSurface(T,T.xy(1,:)); assert(flatGrip==1);
    [~,~,grassGrip] = phxkart.roadSurface(T,[-54 0]); assert(grassGrip==1);
    assert(height>1 && grade(1)<0,'Outer (left) edge must be higher.');
    P = phxkart.parameters(false); S = phxkart.state;
    [~,force] = phxkart.forces(S,P,[0 0 0],0,[0 0 0],true,.008,grade);
    assert(dot(force(1:2),grade)<0,'Gravity must pull downhill.');
    [~,ordinary] = phxkart.forces(S,P,[14 3 0],0,[0 0 0],true,.008,grade,1);
    [~,red] = phxkart.forces(S,P,[14 3 0],0,[0 0 0],true,.008,grade,gripScale);
    assert(abs(red(2))>1.25*abs(ordinary(2)),'Red surface must increase lateral force at speed.');
    [~,grass1] = phxkart.forces(S,P,[14 3 0],0,[0 0 0],false,.008,grade,1);
    [~,grass2] = phxkart.forces(S,P,[14 3 0],0,[0 0 0],false,.008,grade,gripScale);
    assert(isequal(grass1,grass2),'Grass must not inherit red surface grip.');
    walls = phx.Body.empty;
    for k = 1:numel(T.bankWalls)
        O = T.bankWalls(k); h = O.base+O.size(3);
        walls(k) = phx.Body([],'Type','static','Position',[O.position h/2], ...
            'EulerAngles',[0 0 O.angle],'Shape',{'Box','Size',[O.size(1:2) h]},'Restitution',.05);
    end
    [~,index] = min(vecnorm(vertcat(T.bankWalls.position)-[-53.35 0],2,2));
    O = T.bankWalls(index); inward = [-sin(O.angle) cos(O.angle)];
    position = O.position+inward*3;
    body = phx.Body([],'Mass',162,'Inertia',[18 22 32],'Position',[position .25], ...
        'EulerAngles',[0 0 O.angle],'LinearVelocity',[-12*inward 0], ...
        'Shape',{'Box','Size',[1.65 1.12 .32]},'Restitution',.05);
    sim = phx.Simulation([body walls],'Gravity',[0 0 0]);
    cleanup = onCleanup(@()dispose(sim,[body walls]));
    minimum = inf;
    for k = 1:150
        sim.step(.008,1,-1); p = body.Position; a = body.EulerAngles;
        v = body.LinearVelocity; w = body.AngularVelocity;
        body.Position = [p(1:2) .25]; body.EulerAngles = [0 0 a(3)];
        body.LinearVelocity = [v(1:2) 0]; body.AngularVelocity = [0 0 w(3)];
        minimum = min(minimum,dot(p(1:2)-O.position,inward));
    end
    assert(minimum>.45,'The physical barrier must retain a kart hitting it at 43 km/h.');
    clear cleanup
    fig = figure('Visible','off','Position',[50 50 1200 760],'Color',[.55 .70 .79]);
    cleanup = onCleanup(@()close(fig)); ax = axes(fig,'Position',[0 0 1 1]);
    phxkart.drawTrack(ax,T); phxkart.drawStartGate(ax,T);
    sponsors = findobj(ax,'Tag','KartSponsor');
    assert(numel(sponsors)==6);
    words = get(sponsors,'UserData');
    assert(all(ismember({'Škoda','Continental','Valeo','Humusoft','#AutaVUT','UADI'},words)));
    G = phxkart.drawKart(ax,[.1 .78 .8]); k = 335;
    M = phxkart.surfacePose(T,T.xy(k,:),atan2(T.tangent(k,2),T.tangent(k,1))); G.root.Matrix = M;
    pos = M(1:3,4)'+[0 0 .25]; forward = M(1:3,1)';
    campos(ax,pos-forward*4.3+[0 0 2.3]); camtarget(ax,pos+forward*3.5+[0 0 .35]);
    exportgraphics(ax,'kart_bank_driver.png','Resolution',120);
    campos(ax,[-14 -68 49]); camtarget(ax,[-35 0 1]); camva(ax,48);
    exportgraphics(ax,'kart_bank_overview.png','Resolution',120);
    report = struct('BankDegrees',-min(T.bank)*180/pi,'WallSegments',numel(T.bankWalls), ...
        'WallClearance',minimum,'MaxCenterHeight',max(heights));
    disp(report);
end
function dispose(sim,bodies)
    if isvalid(sim), delete(sim); end
    for j = 1:numel(bodies), if isvalid(bodies(j)), delete(bodies(j)); end, end
end
