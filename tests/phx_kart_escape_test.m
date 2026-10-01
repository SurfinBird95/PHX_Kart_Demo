function phx_kart_escape_test
%PHX_KART_ESCAPE_TEST Both legal routes, missed barriers and solid collision.
    T = phxkart.track('technical');
    [~,entry] = min(vecnorm(T.xy-T.escape.xy(1,:),2,2));
    [~,exit] = min(vecnorm(T.xy-T.escape.xy(end,:),2,2));
    E = T.escape;
    knots = 1; offsets = 0;
    for k = 1:numel(E.obstacles)
        [~,i] = min(vecnorm(E.xy-E.obstacles(k).gap,2,2));
        knots(end+1) = i; offsets(end+1) = dot(E.obstacles(k).gap-E.xy(i,:),E.normal(i,:)); %#ok<AGROW>
    end
    knots(end+1) = size(E.xy,1); offsets(end+1) = 0;
    slalom = E.xy+interp1(knots,offsets,(1:size(E.xy,1))','pchip').*E.normal;
    normal = T.xy;
    escape = [T.xy(1:entry-1,:);slalom;T.xy(exit+1:end,:)];
    shortcut = [T.xy(1:entry-1,:);E.xy;T.xy(exit+1:end,:)];
    for route = {normal,escape}
        r = traverse(T,route{1});
        assert(numel(r.times)==1 && r.validTimes(1),'Both correct routes must complete a valid lap.');
    end
    r = traverse(T,shortcut);
    assert(isempty(r.times),'Straight-through shortcut must not count as a lap.');
    % Real PHX impact against one escape-road barrier, no graphics required.
    O = E.obstacles(1); forward = [cos(O.angle) sin(O.angle)];
    wall = phx.Body([], 'Type','static','Position',[O.position .35], ...
        'EulerAngles',[0 0 O.angle],'Shape',{'Box','Size',O.size},'Restitution',0);
    kart = phx.Body([], 'Mass',162,'Inertia',[18 22 32], ...
        'Position',[O.position-3*forward .25],'EulerAngles',[0 0 O.angle], ...
        'LinearVelocity',[6*forward 0],'Shape',{'Box','Size',[1.65 1.12 .32]},'Restitution',0);
    sim = phx.Simulation([wall kart],'Gravity',[0 0 0]);
    cleanup = onCleanup(@()dispose(sim,[wall kart]));
    sim.step(1,125,-1);
    assert(dot(kart.Position(1:2)-O.position,forward)<0,'Kart must not pass through the barrier.');
    clear cleanup
    fprintf('PASS: normal chicane, escape slalom, shortcut rejection and PHX barrier collision.\n');
end
function r = traverse(T,xy)
    r = struct('gate',1,'started',false,'startTime',0,'times',[], 'valid',true,'validTimes',[]);
    xy = [T.xy(1,:)-3*T.tangent(1,:);xy;T.xy(1,:)+T.tangent(1,:)];
    for k = 2:size(xy,1)
        if min(vecnorm(T.roadXY-xy(k,:),2,2))>T.width/2+.5, r.valid = false; end
        r = phxkart.checkGate(r,T,xy(k-1,:),xy(k,:),k*.01,.01);
    end
end
function dispose(sim,bodies)
    if isvalid(sim), delete(sim); end
    for b = bodies, if isvalid(b), delete(b); end, end
end
