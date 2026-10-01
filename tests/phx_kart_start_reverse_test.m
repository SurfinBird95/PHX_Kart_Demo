function phx_kart_start_reverse_test
%PHX_KART_START_REVERSE_TEST Grid release, neutral, reverse and interlocks.
    for k = 0:5
        [n,locked] = phxkart.startSignal(k,true); assert(n==k && locked);
    end
    [n,locked] = phxkart.startSignal(6.5,true); assert(n==0 && ~locked);
    P = phxkart.parameters(true); S = phxkart.state;
    S = phxkart.shiftGear(S,P,-1,[0 0 0]); assert(S.gear==0);
    S.shift = 0; stopped = S;
    blocked = phxkart.shiftGear(S,P,-1,[2 0 0]); assert(blocked.gear==0);
    S = phxkart.shiftGear(stopped,P,-1,[0 0 0]); assert(S.gear==-1);
    neutral = phxkart.state; neutral.gear = 0;
    [neutral,F] = phxkart.forces(neutral,P,[0 0 0],0,[1 0 0],true,.1);
    assert(F(1)==0 && neutral.rpm>1600,'Neutral must rev without propelling.');
    P = phxkart.parameters(false); S = phxkart.state;
    [S,~] = phxkart.driveInput(S,P,[0 1 0],[2 0 0]);
    [S,~] = phxkart.driveInput(S,P,[0 1 0],[0 0 0]);
    assert(S.gear==1,'Holding the brake while stopping must not engage reverse.');
    [S,~] = phxkart.driveInput(S,P,[0 0 0],[0 0 0]);
    [S,input] = phxkart.driveInput(S,P,[0 1 0],[0 0 0]);
    assert(S.gear==-1 && isequal(input,[1 0 0]));
    [S,input] = phxkart.driveInput(S,P,[1 0 0],[-2 0 0]);
    assert(S.gear==-1 && isequal(input,[0 1 0]));
    [S,input] = phxkart.driveInput(S,P,[1 0 0],[0 0 0]);
    assert(S.gear==1 && isequal(input,[1 0 0]));
    for manual = [false true]
        P = phxkart.parameters(manual); S = phxkart.state;
        command = [0 1 0];
        if manual, S.gear = -1; command = [1 0 0]; end
        b = phx.Body([], 'Mass',P.mass,'Inertia',P.inertia,'Shape',{'Box','Size',[1.65 1.12 .32]});
        sim = phx.Simulation(b,'Gravity',[0 0 0]);
        cleanup = onCleanup(@()dispose(sim,b));
        for k = 1:1000
            v = (b.Orientation'*b.LinearVelocity')'; w = b.AngularVelocity;
            [S,F,M] = phxkart.forces(S,P,v,w(3),command,true,.008);
            b.applyForce(F); b.applyTorque(M); sim.step(.008,1,-1);
        end
        assert(b.Position(1)<-5 && b.LinearVelocity(1)<-.5);
        assert(abs(b.LinearVelocity(1))<=P.reverseMaxSpeed+.1);
        [~,~,M] = phxkart.forces(S,P,[-2 0 0],0,[1 0 1],true,.1);
        assert(M(3)<0,'Steering yaw must reverse when backing up.');
        clear cleanup
    end
    f = phx_kart_demo(Start=true,Players=2,Visible="off",RunTimer=false);
    cleanup = onCleanup(@()closeIfValid(f));
    a = getappdata(f,'PHXKartDemo'); initial = a.Snapshot();
    f.WindowKeyPressFcn(f,struct('Key','w'));
    f.WindowKeyPressFcn(f,struct('Key','uparrow'));
    for k = 1:32, a.Step(); end
    data = a.Snapshot(); assert(data.StartLights==1 && ~data.StartReady);
    for k = 33:190, a.Step(); end
    data = a.Snapshot(); assert(data.StartLights==5 && ~data.StartReady);
    assert(max(abs(data.Position(:)-initial.Position(:)))<1e-9);
    assert(all(data.Velocity(:)==0),'Neither player may move before lights-out.');
    frame = getframe(f); imwrite(frame.cdata,fullfile(fileparts(mfilename('fullpath')),'kart_start_preview.png'));
    for k = 1:20, a.Step(); end
    data = a.Snapshot(); assert(data.StartReady && data.StartLights==0);
    assert(all(vecnorm(data.Velocity,2,2)>.1));
    f.WindowKeyPressFcn(f,struct('Key','r'));
    data = a.Snapshot(); assert(~data.StartReady && all(data.Velocity(:)==0));
    close(f); clear cleanup
    disp('PASS: five-light start, both grid locks, release, reset, R/N sequence, interlocks and reversing dynamics.');
end
function dispose(sim,b)
    if isvalid(sim), delete(sim); end
    if isvalid(b), delete(b); end
end
function closeIfValid(f), if isgraphics(f), close(f); end, end
