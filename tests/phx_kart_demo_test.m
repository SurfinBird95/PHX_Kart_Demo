function report = phx_kart_demo_test
%PHX_KART_DEMO_TEST Numerical, race-control and GUI lifecycle regression tests.
    root = fileparts(mfilename('fullpath'));
    report = struct;
    for manual = [false true]
        P = phxkart.parameters(manual); S = phxkart.state;
        b = phx.Body([], 'Mass',P.mass,'Inertia',P.inertia, ...
            'Shape',{'Box','Size',[1.65 1.12 .32]});
        sim = phx.Simulation(b,'Gravity',[0 0 0]);
        cleanup = onCleanup(@()dispose(sim,b));
        for k = 1:720
            [S,F,M] = phxkart.forces(S,P,b.LinearVelocity,0,[1 0 0],true,1/120);
            b.applyForce(F); b.applyTorque(M); sim.step(1/120,1,-1);
        end
        speed = b.LinearVelocity(1);
        assert(speed>8 && speed<50,'Acceleration outside plausible range.');
        assert(abs(b.Position(2))<1e-6,'Symmetric input must stay straight.');
        for k = 1:720
            [S,F,M] = phxkart.forces(S,P,b.LinearVelocity,0,[0 1 0],true,1/120);
            b.applyForce(F); b.applyTorque(M); sim.step(1/120,1,-1);
        end
        assert(norm(b.LinearVelocity)<.5,'Braking must stop the kart.');
        report.(['AccelerationKmh' num2str(manual)]) = speed*3.6;
        clear cleanup
    end
    P = phxkart.parameters(false); S = phxkart.state;
    for k = 1:120
        [S,F,M,D] = phxkart.forces(S,P,[12 0 0],0,[1 0 1],true,1/120);
    end
    assert(F(2)>0 && M(3)>0,'Left steering must produce left force and yaw.');
    assert(D.grip<=1 && all(isfinite([F M])));
    [~,offroad] = phxkart.forces(S,P,[12 0 0],0,[0 0 0],false,1/120);
    [~,onroad] = phxkart.forces(S,P,[12 0 0],0,[0 0 0],true,1/120);
    assert(offroad(1)<onroad(1),'Grass must increase resistance.');
    for name = ["technical","oval","eight"]
        T = phxkart.track(name);
        r = struct('gate',1,'started',false,'startTime',0,'times',[], 'valid',true,'validTimes',[]);
        % Backwards start-line crossing cannot start a lap.
        r = phxkart.checkGate(r,T,T.xy(1,:)+T.tangent(1,:),T.xy(1,:)-T.tangent(1,:),1,.1);
        assert(~r.started);
        order = [T.gates 1];
        for k = 1:numel(order)
            idx = order(k); c = T.xy(idx,:); t = T.tangent(idx,:);
            r = phxkart.checkGate(r,T,c-t,c+t,k,.1);
            if k==1
                attempted = phxkart.checkGate(r,T,c-t,c+t,k+1,.1);
                assert(isempty(attempted.times),'Repeated finish-line crossing must not count.');
            end
        end
        assert(numel(r.times)==1 && abs(r.times-numel(T.gates))<1e-10);
    end
    report.Gates = 'Forward, reverse, ordered lap and both crossing branches passed';
    originalTimers = numel(timerfindall('Name','PHXKartDemo'));
    f = phx_kart_demo(Visible="off",StartLights=false);
    cleanFigure = onCleanup(@()closeIfValid(f));
    % Test actual menu controls, then keyboard callbacks and deterministic steps.
    button = findobj(f,'Style','pushbutton','String','START DRIVING');
    button.Callback(button,[]);
    api = getappdata(f,'PHXKartDemo');
    pause(.25);
    press(f,'p'); a = api.Snapshot(); assert(a.Paused); release(f,'p');
    t = a.Time; pause(.1); a = api.Snapshot(); assert(a.Time==t);
    api.Menu(); assert(numel(timerfindall('Name','PHXKartDemo'))==originalTimers);
    close(f); clear cleanFigure
    for players = [1 2]
        f = phx_kart_demo(Start=true,Track="eight",Players=players,Manual=true,Visible="off",RunTimer=false,StartLights=false);
        cleanFigure = onCleanup(@()closeIfValid(f));
        api = getappdata(f,'PHXKartDemo');
        initial = api.Snapshot();
        press(f,'w');
        if players==2, press(f,'uparrow'); end
        for k = 1:35, api.Step(); end
        release(f,'w'); release(f,'uparrow');
        a = api.Snapshot(); assert(norm(a.Position(1,:)-initial.Position(1,:))>.3);
        assert(all(isfinite(a.Position(:))));
        if players==2, assert(norm(a.Velocity(2,:))>1); end
        press(f,'c'); release(f,'c'); a = api.Snapshot(); assert(a.States{1}.gear==2);
        if players==2
            press(f,'m'); release(f,'m'); a = api.Snapshot(); assert(a.States{2}.gear==2);
        end
        press(f,'r'); release(f,'r'); a = api.Snapshot(); assert(all(a.Velocity(:)==0));
        assert(isempty(a.Race{1}.times));
        try
            exportapp(f,fullfile(root,sprintf('kart_demo_%dplayer.png',players)));
        catch
            frame = getframe(f); imwrite(frame.cdata,fullfile(root,sprintf('kart_demo_%dplayer.png',players)));
        end
        press(f,'escape'); a = api.Snapshot(); assert(~a.Running);
        close(f); clear cleanFigure
    end
    assert(numel(timerfindall('Name','PHXKartDemo'))==originalTimers);
    report.GUI = 'Menu, timers, pause, reset, shifts, both players, close and cleanup passed';
    disp(report);
end
function press(f,key), f.WindowKeyPressFcn(f,struct('Key',key)); end
function release(f,key), f.WindowKeyReleaseFcn(f,struct('Key',key)); end
function closeIfValid(f), if isgraphics(f), close(f); end, end
function dispose(sim,b)
    if isvalid(sim), delete(sim); end
    if isvalid(b), delete(b); end
end
