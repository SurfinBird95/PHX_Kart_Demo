function report = phx_kart_controls_test
%PHX_KART_CONTROLS_TEST Verify applied ramps, HUD and independent menu settings.
    C = struct('throttleTime',.5,'brakeTime',.25,'steerTime',.8,'returnTime',.4);
    P = phxkart.parameters(false);
    assert(abs(phxkart.steeringAngle(.1,0,P)-.048)<1e-12, ...
        'Small inputs at low speed must not jump to full steering lock.');
    S = phxkart.state;
    for k = 1:25, S = phxkart.filterControls(S,C,[1 1 1],.008,10); end
    assert(max(abs([S.throttle S.brake S.steerInput]-[.4 .8 .25]))<1e-12);
    other = phxkart.state;
    for k = 1:50, other = phxkart.filterControls(other,C,[1 1 1],.004,10); end
    assert(abs(other.steer-S.steer)<1e-12,'Ramps must not depend on frame rate.');
    released = S;
    for k = 1:15, released = phxkart.filterControls(released,C,[0 0 0],.008,10); end
    assert(max(abs([released.throttle released.brake released.steerInput]))<1e-12);
    other = S;
    for k = 1:50, S = phxkart.filterControls(S,C,[1 1 -1],.008,10); end
    for k = 1:100, other = phxkart.filterControls(other,C,[1 1 -1],.004,10); end
    assert(abs(S.steerInput+.375)<1e-12,'Countersteering must unwind quickly, then ramp normally.');
    assert(abs(other.steerInput-S.steerInput)<1e-12,'Crossing zero must be time-step independent.');
    % Direct reversal must never lag behind release-then-opposite, even if
    % the user has chosen a centring time slower than the steering ramp.
    for returnTime = [.2 1.2]
        settings = C; settings.returnTime = returnTime;
        for direction = [-1 1]
            direct = phxkart.state; direct.steerInput = direction*.65;
            delayed = direct;
            for k = 1:150
                direct = phxkart.filterControls(direct,settings,[0 0 -direction],.008,10);
                delayed = phxkart.filterControls(delayed,settings,[0 0 -direction*(k>20)],.008,10);
                assert(-direction*direct.steerInput>=-direction*delayed.steerInput-1e-12);
                assert(abs(direct.steerInput)<=1);
            end
        end
    end
    for k = 1:300, S = phxkart.filterControls(S,C,[1 1 -1],.008,10); end
    assert(isequal([S.throttle S.brake S.steerInput],[1 1 -1]));
    f = phx_kart_demo(Visible="off",RunTimer=false,StartLights=false);
    cleanup = onCleanup(@()closeIfValid(f));
    root = fileparts(mfilename('fullpath'));
    assert(isempty(findobj(f,'Style','slider')),'Control sliders belong in Settings only.');
    players = findobj(f,'Tag','KartPlayers'); players.Value = 2;
    settings = findobj(f,'Tag','KartSettings'); settings.Callback(settings,[]);
    one = findobj(f,'Tag','KartControl1_throttleTime'); one.Value = 1; one.Callback(one,[]);
    two = findobj(f,'Tag','KartControl2_throttleTime'); two.Value = .2; two.Callback(two,[]);
    steer = findobj(f,'Tag','KartControl1_steerTime'); steer.Value = 1.2; steer.Callback(steer,[]);
    capture(f,fullfile(root,'kart_settings.png'));
    back = findobj(f,'Tag','KartSettingsBack'); back.Callback(back,[]);
    assert(players.Value==2 && strcmp(players.Visible,'on'),'Settings must preserve race selections.');
    assert(isempty(findobj(f,'Style','slider')));
    capture(f,fullfile(root,'kart_controls_menu.png'));
    start = findobj(f,'String','START DRIVING'); start.Callback(start,[]);
    api = getappdata(f,'PHXKartDemo');
    f.WindowKeyPressFcn(f,struct('Key','w'));
    f.WindowKeyPressFcn(f,struct('Key','a'));
    f.WindowKeyPressFcn(f,struct('Key','uparrow'));
    f.WindowKeyPressFcn(f,struct('Key','rightarrow'));
    for k = 1:10, api.Step(); end
    data = api.Snapshot();
    assert(abs(data.States{1}.throttle-.32)<1e-12);
    assert(data.States{2}.throttle==1);
    assert(abs(data.States{1}.steerInput-.32/1.2)<1e-12);
    for j = 1:2
        p = findobj(f,'Tag',sprintf('KartInput%d_1',j));
        assert(abs(p.XData(2)-data.States{j}.throttle)<1e-12);
        p = findobj(f,'Tag',sprintf('KartInput%d_3',j));
        assert(abs(p.XData(2)-(.5-.5*data.States{j}.steerInput))<1e-12);
    end
    f.WindowKeyPressFcn(f,struct('Key','downarrow'));
    for k = 1:4, api.Step(); end
    capture(f,fullfile(root,'kart_controls_preview.png'));
    % Roll from one direction to the other without lifting the first key.
    f.WindowKeyPressFcn(f,struct('Key','d'));
    f.WindowKeyPressFcn(f,struct('Key','leftarrow'));
    for k = 1:12, api.Step(); end
    data = api.Snapshot();
    assert(data.States{1}.steerInput<0 && data.States{2}.steerInput>0, ...
        'Most recently pressed direction must win for both players.');
    previous = data.States{1}.steerInput;
    f.WindowKeyPressFcn(f,struct('Key','a')); % autorepeat of the old held key
    api.Step(); data = api.Snapshot();
    assert(data.States{1}.steerInput<previous,'Autorepeat must not steal steering priority.');
    f.WindowKeyReleaseFcn(f,struct('Key','d'));
    for k = 1:12, api.Step(); end
    data = api.Snapshot();
    assert(data.States{1}.steerInput>0,'Releasing the new key must restore the still-held direction.');
    api.Menu();
    settings = findobj(f,'Tag','KartSettings'); settings.Callback(settings,[]);
    one = findobj(f,'Tag','KartControl1_throttleTime');
    two = findobj(f,'Tag','KartControl2_throttleTime');
    assert(one.Value==1 && two.Value==.2,'Menu must preserve per-player response settings.');
    f.WindowKeyPressFcn(f,struct('Key','escape'));
    assert(isempty(findobj(f,'Tag','KartSettingsBack')) && strcmp(settings.Visible,'on'));
    close(f); clear cleanup
    report = 'PASS: ramp timing, countersteering, step independence, overlapping keys, autorepeat, HUD and menu settings';
    disp(report);
end
function closeIfValid(f), if isgraphics(f), close(f); end, end
function capture(f,path)
    try, exportapp(f,path); catch, frame = getframe(f); imwrite(frame.cdata,path); end
end
