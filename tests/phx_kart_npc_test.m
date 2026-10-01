function report = phx_kart_npc_test(mode)
%PHX_KART_NPC_TEST Real PHX lap completion plus populated GUI lifecycle.
    arguments
        mode (1,1) string = "all"
    end
    report = struct;
    if mode~="gui"
        for track = ["oval","eight","technical"]
            for difficulty = ["easy","medium","hard","race"]
                T = phxkart.track(track); A = phxkart.npcPlan(T,difficulty);
                P = phxkart.parameters(false); P.npc = true;
                P.controls = struct('throttleTime',.25,'brakeTime',.15,'steerTime',.18,'returnTime',.12);
                S = phxkart.state;
                [pos,yaw,index] = phxkart.gridPose(T,1,1);
                N = struct('index',index,'lane',0,'offset',0,'pace',1,'stuck',0,'targetSpeed',0);
                b = phx.Body([],'Mass',P.mass,'Inertia',P.inertia,'Position',[pos .25], ...
                    'EulerAngles',[0 0 yaw],'Shape',{'Box','Size',[1.65 1.12 .32]});
                sim = phx.Simulation(b,'Gravity',[0 0 0]);
                cleanup = onCleanup(@()dispose(sim,b));
                r = struct('gate',1,'started',false,'startTime',0,'times',[],'valid',true,'validTimes',[]);
                maxDistance = 0; dt = .008; input = [0 0 0];
                timer = tic;
                for step = 1:round(150/dt)
                    pos = b.Position; angle = b.EulerAngles; w = b.AngularVelocity;
                    v = (b.Orientation'*b.LinearVelocity')';
                    if mod(step-1,4)==0
                        [input,N] = phxkart.npcInput(N,A,P,pos(1:2),angle(3),v,w(3),zeros(0,2),4*dt);
                    end
                    distance = min(vecnorm(T.roadXY-pos(1:2),2,2));
                    maxDistance = max(maxDistance,distance);
                    if distance>T.width/2+.5, r.valid = false; end
                    [~,grade,gripScale] = phxkart.roadSurface(T,pos(1:2));
                    rotation = b.Orientation; grade = (rotation(1:2,1:2)'*grade')';
                    [S,F,M] = phxkart.forces(S,P,v,w(3),input,distance<T.width/2,dt,grade,gripScale);
                    b.applyForce(F); b.applyTorque(M); sim.step(dt,1,-1);
                    current = b.Position;
                    r = phxkart.checkGate(r,T,pos(1:2),current(1:2),step*dt,dt);
                    if ~isempty(r.times), break; end
                    assert(all(isfinite(current)),'NPC state diverged.');
                end
                key = char(track+"_"+difficulty);
                report.(key) = struct('Laps',numel(r.times),'LapTime',r.times,'MaxOffset',maxDistance, ...
                    'WallSeconds',toc(timer),'SimSeconds',step*dt,'LastGate',r.gate);
                disp(key); disp(report.(key));
                assert(~isempty(r.times) && all(r.validTimes),'NPC must complete a valid lap on every circuit.');
                clear cleanup
            end
        end
        assert(report.oval_easy.LapTime>report.oval_medium.LapTime && ...
            report.oval_medium.LapTime>report.oval_hard.LapTime,'Difficulty must change lap pace.');
        for track = ["oval","eight","technical"]
            assert(report.(track+"_race").LapTime<report.(track+"_hard").LapTime, ...
                'Race must beat Hard on every circuit.');
        end
    end
    if mode~="physics"
        timers = numel(timerfindall('Name','PHXKartDemo'));
        f = phx_kart_demo(Visible="off",RunTimer=false,NPCs=8,Difficulty="race");
        cleanup = onCleanup(@()closeIfValid(f));
        assert(findobj(f,'Tag','KartNPCCount').Value==9);
        assert(findobj(f,'Tag','KartNPCDifficulty').Value==4);
        exportapp(f,'kart_npc_menu.png');
        button = findobj(f,'String','START DRIVING'); button.Callback(button,[]);
        api = getappdata(f,'PHXKartDemo'); a = api.Snapshot();
        assert(size(a.Position,1)==9 && a.NPCs==8 && a.Difficulty=="race");
        initial = a.Position;
        for k = 1:200, api.Step(); end
        a = api.Snapshot(); assert(max(abs(a.Position-initial),[],'all')<1e-8);
        timer = tic; for k = 1:70, api.Step(); end
        report.NineKartFrameSeconds = toc(timer)/70;
        a = api.Snapshot(); assert(all(vecnorm(a.Position(2:end,:)-initial(2:end,:),2,2)>.2));
        f.WindowKeyPressFcn(f,struct('Key','p')); a = api.Snapshot(); t = a.Time;
        api.Step(); a = api.Snapshot(); assert(a.Time==t);
        f.WindowKeyReleaseFcn(f,struct('Key','p')); f.WindowKeyPressFcn(f,struct('Key','p'));
        f.WindowKeyPressFcn(f,struct('Key','r')); a = api.Snapshot();
        assert(~a.StartReady && all(a.Velocity==0,'all'));
        exportapp(f,'kart_npc_grid.png');
        api.Menu(); assert(findobj(f,'Tag','KartNPCCount').Value==9);
        close(f); clear cleanup
        assert(numel(timerfindall('Name','PHXKartDemo'))==timers);
        f = phx_kart_demo(Start=true,Visible="off",RunTimer=false,StartLights=false,Players=2,NPCs=8);
        cleanup = onCleanup(@()closeIfValid(f)); api = getappdata(f,'PHXKartDemo');
        timer = tic; for k = 1:40, api.Step(); end
        report.TenKartFrameSeconds = toc(timer)/40;
        a = api.Snapshot(); assert(size(a.Position,1)==10 && ~a.Paused);
        close(f); clear cleanup
        disp(report);
    end
end
function closeIfValid(f)
    if isgraphics(f), close(f); end
end
function dispose(sim,b)
    if isvalid(sim), delete(sim); end
    if isvalid(b), delete(b); end
end
