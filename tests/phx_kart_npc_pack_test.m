function report = phx_kart_npc_pack_test(difficulty)
%PHX_KART_NPC_PACK_TEST Eight physical opponents, crossings and real contacts.
    arguments
        difficulty (1,1) string = "hard"
    end
    report = struct;
    for name = ["technical","eight","oval"]
        T = phxkart.track(name); A = phxkart.npcPlan(T,difficulty);
        P = phxkart.parameters(false); P.npc = true;
        P.controls = struct('throttleTime',.25,'brakeTime',.15,'steerTime',.18,'returnTime',.12);
        bodies = phx.Body.empty; obstacles = phx.Body.empty;
        S = cell(1,8); N = cell(1,8); race = cell(1,8);
        for j = 1:8
            [pos,yaw,index] = phxkart.gridPose(T,j,8);
            bodies(j) = phx.Body([],'Mass',P.mass,'Inertia',P.inertia,'Position',[pos .25], ...
                'EulerAngles',[0 0 yaw],'Shape',{'Box','Size',[1.65 1.12 .32]}, ...
                'Friction',[0 0 0],'Restitution',.1);
            S{j} = phxkart.state;
            N{j} = struct('index',index,'lane',(-1)^j*.65,'offset',(-1)^j*1.25, ...
                'pace',1-.012*mod(j-1,4),'stuck',0,'targetSpeed',0);
            race{j} = struct('gate',1,'started',false,'startTime',0,'times',[],'valid',true,'validTimes',[]);
        end
        if ~isempty(T.escape)
            for k = 1:numel(T.escape.obstacles)
                O = T.escape.obstacles(k);
                obstacles(k) = phx.Body([],'Type','static','Position',[O.position O.size(3)/2], ...
                    'EulerAngles',[0 0 O.angle],'Shape',{'Box','Size',O.size});
            end
        end
        for k = 1:numel(T.bankWalls)
            O = T.bankWalls(k); height = O.base+O.size(3);
            obstacles(end+1) = phx.Body([],'Type','static','Position',[O.position height/2], ...
                'EulerAngles',[0 0 O.angle],'Shape',{'Box','Size',[O.size(1:2) height]});
        end
        sim = phx.Simulation([bodies obstacles],'Gravity',[0 0 0]);
        cleanup = onCleanup(@()dispose(sim,[bodies obstacles]));
        commands = zeros(8,3); positions = zeros(8,2); dt = .008;
        timer = tic;
        for step = 1:round(125/dt)
            for j = 1:8, p = bodies(j).Position; positions(j,:) = p(1:2); end
            for j = 1:8
                b = bodies(j); angle = b.EulerAngles; w = b.AngularVelocity;
                v = (b.Orientation'*b.LinearVelocity')';
                if mod(step-1,4)==0 && step*dt>A.reaction+.035*(j-1)
                    [commands(j,:),N{j}] = phxkart.npcInput(N{j},A,P,positions(j,:),angle(3),v,w(3), ...
                        positions([1:j-1 j+1:end],:),4*dt);
                end
                distance = min(vecnorm(T.roadXY-positions(j,:),2,2));
                if distance>T.width/2+.5, race{j}.valid = false; end
                [~,grade,gripScale] = phxkart.roadSurface(T,positions(j,:));
                rotation = b.Orientation; grade = (rotation(1:2,1:2)'*grade')';
                [S{j},F,M] = phxkart.forces(S{j},P,v,w(3),commands(j,:),distance<T.width/2,dt,grade,gripScale);
                b.applyForce(F); b.applyTorque(M);
            end
            sim.step(dt,1,-1);
            for j = 1:8
                b = bodies(j); p = b.Position; angle = b.EulerAngles;
                v = b.LinearVelocity; w = b.AngularVelocity;
                b.Position = [p(1:2) .25]; b.EulerAngles = [0 0 angle(3)];
                b.LinearVelocity = [v(1:2) 0]; b.AngularVelocity = [0 0 w(3)];
                race{j} = phxkart.checkGate(race{j},T,positions(j,:),p(1:2),step*dt,dt);
            end
            if all(cellfun(@(r)~isempty(r.times),race)), break; end
        end
        report.(char(name)) = struct('Laps',cellfun(@(r)numel(r.times),race), ...
            'ValidLaps',cellfun(@(r)sum(r.validTimes),race),'StuckSeconds',cellfun(@(n)n.stuck,N), ...
            'LastGate',cellfun(@(r)r.gate,race),'WallSeconds',toc(timer),'SimSeconds',step*dt);
        disp(name); disp(report.(char(name)));
        assert(all(cellfun(@(r)~isempty(r.times),race)),'Every NPC must complete a lap in traffic.');
        clear cleanup
    end
end
function dispose(sim,bodies)
    if isvalid(sim), delete(sim); end
    for j = 1:numel(bodies), if isvalid(bodies(j)), delete(bodies(j)); end, end
end
