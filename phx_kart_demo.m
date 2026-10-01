function fig = phx_kart_demo(options)
%PHX_KART_DEMO Interactive PHX kart demo, with third-person split screen.
%   PHX_KART_DEMO opens the menu. Requires PHX Toolbox on the MATLAB path.
%   F = PHX_KART_DEMO(Start=true,Track="eight",Players=2,Manual=true)
%   starts directly. Manual may be scalar or one logical per player.
%   NPCs=0..8 adds opponents; Difficulty="easy"/"medium"/"hard"/"race".
%   Track="obstacle" adds ramps, airborne motion, a hammer and movable hay.
%   ThrottleTime, BrakeTime, SteerTime and ReturnTime set keyboard ramps
%   in seconds (0.05..2). Larger values mean smoother/slower application.
%   The menu allows separate values for each player; HUD bars show applied
%   filtered controls, not merely the pressed keys.
%   WASD / arrows: throttle, brake, steer. X/C and N/M: down/up shift.
%   P: pause, R: reset both karts, Escape: menu. Close window to release PHX.
%   Five red lights release the grid after 6.5 simulation seconds.
%   StartLights=false skips the sequence. Manual gears: R/N/1..6.
%   Single-speed: press S/down again at rest to reverse; W/up brakes back
%   to a stop and then drives forwards. Reverse is limited to about 12 km/h.
%   RunTimer=false exposes deterministic Step/Snapshot handles in appdata
%   'PHXKartDemo' for automated testing. No other timers/figures are touched.
%   This is an approximate planar model, not a validated kart simulator.
    arguments
        options.Start (1,1) logical = false
        options.Track (1,1) string {mustBeMember(options.Track,["technical","oval","eight","obstacle"])} = "technical"
        options.Players (1,1) double {mustBeMember(options.Players,[1 2])} = 1
        options.Manual (1,:) logical = false
        options.NPCs (1,1) double {mustBeInteger,mustBeInRange(options.NPCs,0,8)} = 0
        options.Difficulty (1,1) string {mustBeMember(options.Difficulty,["easy","medium","hard","race"])} = "medium"
        options.Visible (1,1) string {mustBeMember(options.Visible,["on","off"])} = "on"
        options.RunTimer (1,1) logical = true
        options.StartLights (1,1) logical = true
        options.ThrottleTime (1,1) double {mustBeInRange(options.ThrottleTime,.05,2)} = .45
        options.BrakeTime (1,1) double {mustBeInRange(options.BrakeTime,.05,2)} = .30
        options.SteerTime (1,1) double {mustBeInRange(options.SteerTime,.05,2)} = .70
        options.ReturnTime (1,1) double {mustBeInRange(options.ReturnTime,.05,2)} = .35
    end
    if isempty(which('phx.Simulation'))
        error('phxkart:MissingToolbox','Add PHX Toolbox to the MATLAB path first.');
    end
    if ~ismember(numel(options.Manual),[1 options.Players])
        error('phxkart:ManualSize','Manual must be scalar or one value per player.');
    end
    bg = [.055 .075 .105]; white = [.88 .93 .97];
    fig = figure('Name','PHX | Kart Lab','NumberTitle','off','Color',bg, ...
        'MenuBar','none','ToolBar','none','Position',[80 80 1280 780], ...
        'Visible',options.Visible,'CloseRequestFcn',@closeDemo, ...
        'WindowKeyPressFcn',@keyDown,'WindowKeyReleaseFcn',@keyUp);
    sim = []; bodies = phx.Body.empty; obstacles = phx.Body.empty; clockTimer = [];
    courseBodies=phx.Body.empty; courseViews={}; airborne=[];
    running = false; paused = false; busy = false; keys = struct;
    steeringPriority = [0 0];
    T = []; P = {}; S = {}; race = {}; diagnostics = {};
    axs = gobjects(0); hud = gobjects(0); lapText = gobjects(0);
    G = {}; cameraPos = {}; cameraTarget = {}; count = 1; nowTime = 0;
    totalCount = 1; npcCount = options.NPCs; difficulty = options.Difficulty;
    npcPlan = []; npcState = {}; npcCommands = []; selectorNPCs = []; selectorDifficulty = [];
    tickDuration = .032; dt = .008; status = []; % 125 Hz physics / 31.25 Hz display
    selectorPlayers = []; selectorTrack = []; selectorDrive = gobjects(0);
    settingsOpen = false; menuChildren = gobjects(0);
    inputBars = {};
    startGates = {}; startSequenceTime = 0;
    renderedLights = -1; renderedBrake = []; renderedSteer = [];
    controlConfig = repmat(struct('throttleTime',options.ThrottleTime, ...
        'brakeTime',options.BrakeTime,'steerTime',options.SteerTime, ...
        'returnTime',options.ReturnTime),1,2);
    if isprop(fig,'WindowFocusLostFcn'), fig.WindowFocusLostFcn = @lostFocus; end
    api = struct('Step',@tick,'Snapshot',@snapshot,'Menu',@showMenu);
    setappdata(fig,'PHXKartDemo',api);
    try
        if options.Start
            startRace(options.Track,options.Players,options.Manual);
        else
            showMenu();
        end
    catch err
        closeDemo(); rethrow(err);
    end

    function h = label(pos,text,size,color)
        h = uicontrol(fig,'Style','text','Units','normalized','Position',pos, ...
            'String',text,'BackgroundColor',bg,'ForegroundColor',color, ...
            'FontName','Segoe UI','FontSize',size,'HorizontalAlignment','left');
    end

    function showMenu(varargin)
        releaseWorld();
        settingsOpen = false; menuChildren = gobjects(0);
        delete(fig.Children);
        label([.09 .86 .8 .08],'PHX / KART LAB',36,white);
        label([.09 .80 .82 .04],'Real-time physics / steering, traction and drift assistance',17,[.3 .82 .80]);
        label([.09 .72 .22 .035],'PLAYERS',12,white);
        selectorPlayers = uicontrol(fig,'Style','popupmenu','Units','normalized', ...
            'Position',[.09 .665 .33 .05],'String',{'Single player','Two players - split screen'},'FontSize',13,'Tag','KartPlayers');
        label([.52 .72 .25 .035],'CIRCUIT',12,white);
        selectorTrack = uicontrol(fig,'Style','popupmenu','Units','normalized', ...
            'Position',[.52 .665 .33 .05],'String',{'Technical Circuit - default','Oval','Figure eight - level crossing','Obstacle Course - jumps & hammer'},'FontSize',13);
        for j = 1:2
            x = .09+(j-1)*.43;
            label([x .60 .35 .035],sprintf('PLAYER %d / POWERTRAIN',j),12,white);
            selectorDrive(j) = uicontrol(fig,'Style','popupmenu','Units','normalized', ...
                'Position',[x .545 .33 .05],'String',{'Single-speed 125 cc','Manual 6-speed 125 cc'},'FontSize',13);
        end
        label([.09 .505 .33 .03],'NPC OPPONENTS',11,white);
        selectorNPCs = uicontrol(fig,'Style','popupmenu','Units','normalized', ...
            'Position',[.09 .46 .33 .04],'String',{'0 - time trial','1','2','3','4','5','6','7','8'}, ...
            'Value',npcCount+1,'FontSize',12,'Tag','KartNPCCount');
        label([.52 .505 .33 .03],'NPC DIFFICULTY',11,white);
        selectorDifficulty = uicontrol(fig,'Style','popupmenu','Units','normalized', ...
            'Position',[.52 .46 .33 .04],'String',{'Easy','Medium','Hard','Race'}, ...
            'Value',find(difficulty==["easy","medium","hard","race"]),'FontSize',12,'Tag','KartNPCDifficulty');
        uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[.09 .19 .33 .085], ...
            'String','START DRIVING','FontSize',18,'FontWeight','bold', ...
            'BackgroundColor',[.20 .75 .69],'Callback',@startFromMenu);
        uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[.52 .19 .33 .085], ...
            'String','Settings','FontSize',18,'Tag','KartSettings','Callback',@showSettings);
        label([.09 .075 .8 .075],sprintf('P1  WASD + X/C  |  P2  Arrows + N/M\nP pause  /  R reset  /  Esc menu'),11,[.57 .65 .72]);
        drawnow;
    end

    function showSettings(varargin)
        if settingsOpen || running, return; end
        menuChildren = fig.Children;
        set(menuChildren,'Visible','off');
        settingsOpen = true; keys = struct;
        label([.09 .86 .8 .08],'SETTINGS',36,white);
        label([.09 .77 .82 .055],'CONTROL RESPONSE  /  Higher seconds = gentler response.',16,[.3 .82 .80]);
        for j = 1:2
            label([.09+(j-1)*.43 .68 .33 .04],sprintf('PLAYER %d',j),16,white);
        end
        fields = {'throttleTime','brakeTime','steerTime','returnTime'};
        names = {'Throttle 0-100%','Brake 0-100%','Steering center to full','Steering return to center'};
        for j = 1:2
            for k = 1:4
                x = .09+(j-1)*.43; y = .59-(k-1)*.11;
                valueLabel = label([x y+.025 .36 .028], ...
                    sprintf('%s   %.2f s',names{k},controlConfig(j).(fields{k})),11,white);
                uicontrol(fig,'Style','slider','Units','normalized','Position',[x y .33 .023], ...
                    'Min',.05,'Max',2,'Value',controlConfig(j).(fields{k}), ...
                    'SliderStep',[.01 .1],'Tag',sprintf('KartControl%d_%s',j,fields{k}), ...
                    'TooltipString','Time in seconds: longer means smoother. Pedals release in 0.12 s.', ...
                    'Callback',@(src,~)setControl(src,j,fields{k},names{k},valueLabel));
            end
        end
        uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[.09 .10 .33 .085], ...
            'String','Back to menu','FontSize',18,'Tag','KartSettingsBack','Callback',@closeSettings);
        label([.52 .10 .40 .085],sprintf('Changes are saved automatically for this session.\nEsc / Back to menu'),11,[.57 .65 .72]);
        drawnow;
    end

    function closeSettings(varargin)
        if ~settingsOpen, return; end
        delete(setdiff(fig.Children,menuChildren));
        set(menuChildren,'Visible','on');
        menuChildren = gobjects(0); settingsOpen = false; keys = struct;
        drawnow;
    end

    function setControl(src,j,field,name,valueLabel)
        controlConfig(j).(field) = src.Value;
        valueLabel.String = sprintf('%s   %.2f s',name,src.Value);
    end

    function startFromMenu(varargin)
        tracks = ["technical","oval","eight","obstacle"];
        npcCount = selectorNPCs.Value-1;
        levels = ["easy","medium","hard","race"]; difficulty = levels(selectorDifficulty.Value);
        try
            startRace(tracks(selectorTrack.Value),selectorPlayers.Value, ...
                [selectorDrive(1).Value==2 selectorDrive(2).Value==2]);
        catch err
            releaseWorld();
            errordlg(err.message,'PHX Kart Demo');
            warning('phxkart:Start','%s',getReport(err,'extended','hyperlinks','off'));
        end
    end

    function startRace(trackName,n,manual)
        releaseWorld(); delete(fig.Children);
        count = n; T = phxkart.track(trackName); nowTime = 0; startSequenceTime = 0;
        totalCount = n+npcCount; npcPlan = phxkart.npcPlan(T,difficulty);
        airborne=false(1,totalCount); courseViews=cell(1,n);
        npcState = cell(1,totalCount); npcCommands = zeros(totalCount,3);
        if isscalar(manual), manual = repmat(manual,1,n); end
        P = cell(1,totalCount); S = cell(1,totalCount); race = cell(1,totalCount); diagnostics = cell(1,totalCount);
        axs = gobjects(1,n); hud = gobjects(1,n); lapText = gobjects(1,n);
        G = cell(n,totalCount); cameraPos = cell(1,n); cameraTarget = cell(1,n);
        inputBars = cell(1,n);
        startGates = cell(1,n);
        renderedLights = -1; renderedBrake = nan(n,totalCount); renderedSteer = nan(n,totalCount);
        label([.018 .943 .7 .046],'PHX / KART LAB     |     LIVE PHYSICS',18,white);
        status = label([.018 .005 .75 .037],'WASD + X/C  |  Arrows + N/M  |  P pause  |  R reset  |  Esc menu',11,white);
        uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[.83 .946 .075 .037], ...
            'String','Pause [P]','Callback',@togglePause);
        uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[.92 .946 .065 .037], ...
            'String','Menu','Callback',@showMenu);
        colors = [.1 .78 .80;1 .42 .20; .9 .2 .3;.45 .8 .2;.65 .3 .95;1 .8 .15;.2 .45 1;1 .3 .65;.65 .7 .8;.7 .45 .15];
        for j = 1:totalCount
            if j<=count
                P{j} = phxkart.parameters(manual(j));
                P{j}.controls = controlConfig(j);
            else
                P{j} = phxkart.parameters(false); P{j}.npc = true;
                P{j}.controls = struct('throttleTime',.25,'brakeTime',.15,'steerTime',.18,'returnTime',.12);
            end
            bodies(j) = phx.Body([], 'Mass',P{j}.mass,'Inertia',P{j}.inertia, ...
                'Shape',{'Box','Size',[1.65 1.12 .32]},'Friction',[0 0 0], 'Restitution',.1);
        end
        if ~isempty(T.escape)
            for k = 1:numel(T.escape.obstacles)
                O = T.escape.obstacles(k);
                obstacles(k) = phx.Body([], 'Type','static','Position',[O.position O.size(3)/2], ...
                    'EulerAngles',[0 0 O.angle],'Shape',{'Box','Size',O.size}, ...
                    'Friction',[.3 0 0],'Restitution',.05);
            end
        end
        for k = 1:numel(T.bankWalls)
            O = T.bankWalls(k);
            % XY contact proxy spans the raised visual wall down to the
            % planar chassis solver, so karts cannot pass beneath it.
            height = O.base+O.size(3);
            obstacles(end+1) = phx.Body([], 'Type','static','Position',[O.position height/2], ...
                'EulerAngles',[0 0 O.angle],'Shape',{'Box','Size',[O.size(1:2) height]}, ...
                'Friction',[.15 0 0],'Restitution',.05);
        end
        courseBodies=phxkart.courseBodies(T);
        sim = phx.Simulation([bodies obstacles courseBodies],'Gravity',[0 0 0]);
        for j = 1:n
            if n==1, y = .065; h = .86; else, h = .42; y = .065+(2-j)*.44; end
            viewport = uipanel(fig,'Units','normalized','Position',[.01 y .77 h], ...
                'BorderType','none','BackgroundColor',[.55 .70 .79]);
            axs(j) = axes(viewport,'Units','normalized','Position',[0 0 1 1], ...
                'Color',[.55 .70 .79],'Clipping','on','ClippingStyle','rectangle');
            phxkart.drawTrack(axs(j),T);
            courseViews{j}=phxkart.drawCourse(axs(j),T);
            startGates{j} = phxkart.drawStartGate(axs(j),T);
            disableDefaultInteractivity(axs(j)); axs(j).Toolbar.Visible = 'off';
            for k = 1:totalCount, G{j,k} = phxkart.drawKart(axs(j),colors(k,:)); end
            fontSize = 15; if n==2, fontSize = 12; end
            hud(j) = label([.79 y+h*.70 .205 h*.29],'',fontSize,colors(j,:));
            inputBars{j} = phxkart.inputBars(fig,[.79 y+h*.39 .205 h*.30],j);
            lapText(j) = label([.79 y .205 h*.37],'',11,white);
        end
        for j = 1:totalCount, resetKart(j); end
        keys = struct; steeringPriority = [0 0]; paused = false; running = true;
        render(); drawnow;
        if options.RunTimer
            clockTimer = timer('Name','PHXKartDemo','ExecutionMode','fixedRate', ...
                'Period',tickDuration,'BusyMode','drop','TimerFcn',@tick,'ErrorFcn',@timerError);
            start(clockTimer);
        end
    end

    function resetKart(j)
        offset = 0; if count==2, offset = (j-1.5)*2.5; end
        xy = T.xy(1,:)-T.tangent(1,:)*3+T.normal(1,:)*offset;
        yaw = atan2(T.tangent(1,2),T.tangent(1,1)); index = 1;
        if npcCount>0
            % Opponents ahead, humans in the final grid row(s).
            slot = j-count; if j<=count, slot = npcCount+j; end
            [xy,yaw,index] = phxkart.gridPose(T,slot,totalCount);
        end
        bodies(j).Position = [xy .25];
        if ~isempty(T.course), bodies(j).Position=[xy .25+phxkart.roadSurface(T,xy)]; end
        airborne(j)=false;
        bodies(j).EulerAngles = [0 0 yaw];
        bodies(j).LinearVelocity = [0 0 0]; bodies(j).AngularVelocity = [0 0 0];
        S{j} = phxkart.state;
        race{j} = struct('gate',1,'started',false,'startTime',nowTime, ...
            'times',[],'valid',true,'validTimes',[]);
        diagnostics{j} = struct('grip',0,'speed',0,'onRoad',true);
        if j<=count
            cameraPos{j} = []; cameraTarget{j} = [];
        else
            side = 2*mod(j-count-1,2)-1;
            npcState{j} = struct('index',index,'lane',side*.65,'offset',side*1.25, ...
                'pace',1-.012*mod(j-count-1,4),'stuck',0,'recoveries',0,'targetSpeed',0);
            npcCommands(j,:) = [0 0 0];
        end
    end

    function tick(varargin)
        if ~running || paused || busy || ~isgraphics(fig), return; end
        busy = true; cleanup = onCleanup(@unlock);
        try
            ticFrame = tic;
            % One AI update per display tick, reused for four physics steps.
            [~,locked] = phxkart.startSignal(nowTime-startSequenceTime,options.StartLights);
            positions = zeros(totalCount,2);
            for j = 1:totalCount, p = bodies(j).Position; positions(j,:) = p(1:2); end
            for j = count+1:totalCount
                releaseTime = 0; if options.StartLights, releaseTime = 6.5; end
                if locked || nowTime-startSequenceTime<releaseTime+npcPlan.reaction+.035*(j-count-1)
                    npcCommands(j,:) = [0 0 0]; continue;
                end
                angle = bodies(j).EulerAngles; w = bodies(j).AngularVelocity;
                velocity = (bodies(j).Orientation'*bodies(j).LinearVelocity')';
                [npcCommands(j,:),npcState{j}] = phxkart.npcInput(npcState{j},npcPlan,P{j}, ...
                    positions(j,:),angle(3),velocity,w(3),positions([1:j-1 j+1:end],:),tickDuration);
                if npcState{j}.stuck>6
                    recoverNPC(j,positions);
                    p = bodies(j).Position; positions(j,:) = p(1:2);
                end
            end
            for sub = 1:4
                phxkart.stepCourse(T,courseBodies,nowTime-startSequenceTime,dt,false);
                [~,gridLocked] = phxkart.startSignal(nowTime-startSequenceTime,options.StartLights);
                prev = zeros(totalCount,2);
                for j = 1:totalCount
                    pos = bodies(j).Position; prev(j,:) = pos(1:2);
                    distance = min(vecnorm(T.roadXY-pos(1:2),2,2));
                    onRoad = distance < T.width/2;
                    if race{j}.started && distance>T.width/2+.5, race{j}.valid = false; end
                    velocity = (bodies(j).Orientation'*bodies(j).LinearVelocity')';
                    w = bodies(j).AngularVelocity;
                    [height,grade,gripScale] = phxkart.roadSurface(T,pos(1:2));
                    if ~isempty(T.course)
                        airborne(j)=pos(3)>height+.285;
                    end
                    rotation = bodies(j).Orientation;
                    grade = (rotation(1:2,1:2)'*grade')';
                    [S{j},force,moment,diagnostics{j}] = phxkart.forces( ...
                        S{j},P{j},velocity,w(3),readInput(j),onRoad,dt,grade,gripScale);
                    if ~isempty(T.course)
                        if airborne(j)
                            force=[-.25*velocity(1)*abs(velocity(1)) -.25*velocity(2)*abs(velocity(2)) 0];
                            moment=[0 0 0]; diagnostics{j}.grip=0;
                        end
                        force(3)=-P{j}.mass*9.81;
                    end
                    if gridLocked
                        bodies(j).LinearVelocity = [0 0 0]; bodies(j).AngularVelocity = [0 0 0];
                        S{j}.ax = 0; S{j}.ay = 0;
                    else
                        bodies(j).applyForce(force); bodies(j).applyTorque(moment);
                    end
                end
                sim.step(dt,1,-1);
                nowTime = nowTime+dt;
                for j = 1:totalCount
                    % Constrain this deliberately planar model after contact resolution.
                    pos = bodies(j).Position; angle = bodies(j).EulerAngles;
                    v = bodies(j).LinearVelocity; w = bodies(j).AngularVelocity;
                    if isempty(T.course)
                        pos(3)=.25; v(3)=0;
                    else
                        [height,grade]=phxkart.roadSurface(T,pos(1:2));
                        if pos(3)<=height+.25
                            pos(3)=height+.25; v(3)=dot(grade,v(1:2));
                        end
                        airborne(j)=pos(3)>height+.285;
                    end
                    bodies(j).Position=pos; bodies(j).EulerAngles=[0 0 angle(3)];
                    bodies(j).LinearVelocity=v; bodies(j).AngularVelocity=[0 0 w(3)];
                    race{j} = phxkart.checkGate(race{j},T,prev(j,:),pos(1:2),nowTime,dt);
                    if norm(pos(1:2))>160, resetKart(j); end
                end
            end
            render();
            drawnow limitrate;
            if isgraphics(status) && running && ~paused
                [lights,gridLocked] = phxkart.startSignal(nowTime-startSequenceTime,options.StartLights);
                if gridLocked
                    status.String = sprintf('START | %d / 5 red lights | Hold throttle, wait for LIGHTS OUT',lights);
                elseif options.StartLights && nowTime-startSequenceTime<8.5
                    status.String = 'LIGHTS OUT - GO!';
                elseif toc(ticFrame)>tickDuration*1.5
                    status.String = 'Rendering below real time | lap clock follows simulation time | P pause / R reset / Esc menu';
                else
                    status.String = 'WASD + X/C  |  Arrows + N/M  |  P pause  |  R reset  |  Esc menu';
                end
            end
        catch err
            paused = true;
            if isgraphics(status), status.String = ['Paused after error: ' err.message]; end
            if ~isempty(clockTimer) && isvalid(clockTimer), stop(clockTimer); end
            if ~options.RunTimer, rethrow(err); end
            warning('phxkart:Runtime','%s',getReport(err,'extended','hyperlinks','off'));
        end
    end

    function unlock
        if isgraphics(fig), busy = false; end
    end

    function recoverNPC(j,positions)
        % Return behind the last passed checkpoint, never advance lap progress.
        gate = mod(race{j}.gate-2,numel(T.gates))+1;
        index = T.gates(gate);
        if ~race{j}.started
            [xy,yaw,index] = phxkart.gridPose(T,j-count,totalCount);
        else
            xy = T.xy(index,:)-2*T.tangent(index,:);
            yaw = atan2(T.tangent(index,2),T.tangent(index,1));
        end
        others = positions([1:j-1 j+1:end],:);
        if any(vecnorm(others-xy,2,2)<5), return; end
        bodies(j).Position = [xy .25]; bodies(j).EulerAngles = [0 0 yaw];
        if ~isempty(T.course), bodies(j).Position=[xy .25+phxkart.roadSurface(T,xy)]; end
        airborne(j)=false;
        bodies(j).LinearVelocity = [0 0 0]; bodies(j).AngularVelocity = [0 0 0];
        S{j} = phxkart.state; race{j}.valid = false;
        npcState{j}.index = index; npcState{j}.stuck = 0;
        npcState{j}.recoveries = npcState{j}.recoveries+1;
        npcCommands(j,:) = [0 0 0];
    end

    function input = readInput(j)
        if j>count, input = npcCommands(j,:); return; end
        if j==1, names = {'w','s','a','d'}; else, names = {'uparrow','downarrow','leftarrow','rightarrow'}; end
        steering = held(names{3})-held(names{4});
        if held(names{3}) && held(names{4}), steering = steeringPriority(j); end
        input = [held(names{1}),held(names{2}),steering];
    end
    function value = held(name)
        value = isfield(keys,name) && keys.(name);
    end

    function keyDown(~,event)
        name = event.Key;
        if isempty(name) || ~isvarname(name), return; end
        wasHeld = held(name); keys.(name) = true;
        if settingsOpen && strcmp(name,'escape')
            closeSettings(); return;
        end
        if wasHeld || ~running, return; end
        switch name
            case 'p', togglePause();
            case 'escape', showMenu(); return;
            case 'r'
                startSequenceTime = nowTime;
                phxkart.stepCourse(T,courseBodies,0,0,true);
                for j = 1:totalCount, resetKart(j); end
                render();
            otherwise
                if paused, return; end
                directions = {'a','d';'leftarrow','rightarrow'};
                for j = 1:count
                    if strcmp(name,directions{j,1}), steeringPriority(j) = 1; end
                    if strcmp(name,directions{j,2}), steeringPriority(j) = -1; end
                end
                mapping = {'x','c';'n','m'};
                for j = 1:count
                    if P{j}.manual && S{j}.shift==0
                        change = strcmp(name,mapping{j,2})-strcmp(name,mapping{j,1});
                        velocity = (bodies(j).Orientation'*bodies(j).LinearVelocity')';
                        S{j} = phxkart.shiftGear(S{j},P{j},change,velocity);
                    end
                end
        end
    end
    function keyUp(~,event)
        if isvarname(event.Key), keys.(event.Key) = false; end
    end
    function lostFocus(varargin)
        keys = struct;
        if running, paused = true; status.String = 'PAUSED - focus lost. Click the track, then press P.'; end
    end
    function togglePause(varargin)
        if ~running, return; end
        paused = ~paused; keys = struct;
        if paused, status.String = 'PAUSED | P to resume'; end
    end

    function render
        poses = zeros(totalCount,3); anglesAll = zeros(totalCount,3);
        matrices = cell(1,totalCount); wheelMatrices = cell(totalCount,2);
        for j = 1:totalCount
            poses(j,:) = bodies(j).Position; anglesAll(j,:) = bodies(j).EulerAngles;
            matrices{j} = phxkart.surfacePose(T,poses(j,1:2),anglesAll(j,3));
            if isempty(T.course)
                poses(j,3) = poses(j,3)+matrices{j}(3,4);
            else
                matrices{j}(3,4)=poses(j,3)-.25;
                if airborne(j)
                    v=bodies(j).LinearVelocity; pitch=atan2(v(3),max(norm(v(1:2)),1));
                    yaw=anglesAll(j,3); f=[cos(yaw)*cos(pitch);sin(yaw)*cos(pitch);sin(pitch)];
                    side=[-sin(yaw);cos(yaw);0];
                    matrices{j}(1:3,1:3)=[f side cross(f,side)];
                end
            end
            for k = 1:2
                wheelMatrices{j,k} = poseMatrix([G{1,j}.points(k,:) .17],S{j}.steer);
            end
        end
        [lights,~] = phxkart.startSignal(nowTime-startSequenceTime,options.StartLights);
        for viewIndex = 1:count
            phxkart.updateCourse(courseViews{viewIndex},T,courseBodies);
            if lights~=renderedLights
                for lamp = 1:5
                    color = [.13 .018 .015]; if lamp<=lights, color = [1 .035 .015]; end
                    set(startGates{viewIndex}.lamps(lamp,:),'FaceColor',color);
                end
            end
            for j = 1:totalCount
                G{viewIndex,j}.root.Matrix = matrices{j};
                active = S{j}.brake>.02;
                if active~=renderedBrake(viewIndex,j)
                    brakeColor = [.22 .015 .01];
                    if active, brakeColor = [1 .08 .025]; end
                    set(G{viewIndex,j}.brakeLights,'FaceColor',brakeColor);
                    renderedBrake(viewIndex,j) = active;
                end
                if ~isfinite(renderedSteer(viewIndex,j)) || abs(S{j}.steer-renderedSteer(viewIndex,j))>.001
                    for k = 1:2, G{viewIndex,j}.wheels(k).Matrix = wheelMatrices{j,k}; end
                    renderedSteer(viewIndex,j) = S{j}.steer;
                end
            end
            j = viewIndex; pos = poses(j,:); angles = anglesAll(j,:);
            forward = matrices{j}(1:3,1)';
            desiredPos = pos-forward*4.3+[0 0 2.3];
            desiredTarget = pos+forward*3.5+[0 0 .35];
            if isempty(cameraPos{j})
                cameraPos{j} = desiredPos; cameraTarget{j} = desiredTarget;
            else
                cameraPos{j} = .78*cameraPos{j}+.22*desiredPos;
                cameraTarget{j} = .65*cameraTarget{j}+.35*desiredTarget;
            end
            campos(axs(j),cameraPos{j}); camtarget(axs(j),cameraTarget{j});
            d = diagnostics{j}; s = S{j}; r = race{j};
            phxkart.updateBars(inputBars{j},s);
            gear = sprintf('%d',s.gear); if ~P{j}.manual, gear = 'FIXED'; end
            if s.gear==-1, gear = 'R'; elseif s.gear==0, gear = 'N'; end
            hudText = sprintf('PLAYER %d\n%5.1f km/h\n%5.0f RPM   /   %s\nGRIP %3.0f%%  |  %s', ...
                j,d.speed,s.rpm,gear,100*d.grip,roadName(d.onRoad));
            if airborne(j), hudText=[hudText newline 'AIRBORNE']; end
            hud(j).String=hudText;
            elapsed = 0; if r.started, elapsed = nowTime-r.startTime; end
            good = r.times(logical(r.validTimes)); best = '--';
            if ~isempty(good), best = sprintf('%.3f s',min(good)); end
            lines = {sprintf('LAP %d   /   %.2f s',numel(r.times)+1,elapsed),['BEST  ' best]};
            if ~r.started, lines{end+1} = 'Cross the line to start';
            elseif ~r.valid, lines{end+1} = 'INVALID LAP - off track'; end
            lines{end+1} = sprintf('CHECKPOINT %d / %d',r.gate,numel(T.gates));
            if npcCount>0
                completed = cellfun(@(q)numel(q.times),race(count+1:end));
                lines{end+1} = sprintf('NPC %d / %s | leader lap %d',npcCount,upper(difficulty),max(completed)+1);
            end
            historyCount = 5; if count==2, historyCount = 2; end
            for k = max(1,numel(r.times)-historyCount+1):numel(r.times)
                suffix = ''; if ~r.validTimes(k), suffix = ' INVALID'; end
                lines{end+1} = sprintf('%02d    %.3f s%s',k,r.times(k),suffix); %#ok<AGROW>
            end
            lapText(j).String = lines;
        end
        renderedLights = lights;
    end

    function matrix = poseMatrix(position,yaw)
        c = cos(yaw); s = sin(yaw);
        matrix = [c -s 0 position(1);s c 0 position(2);0 0 1 position(3);0 0 0 1];
    end

    function text = roadName(onRoad)
        if onRoad, text = 'ASPHALT'; else, text = 'GRASS'; end
    end
    function data = snapshot
        data = struct('Time',nowTime,'States',{S},'Race',{race},'Paused',paused,'Running',running);
        data.Controls = controlConfig(1:count);
        data.NPCs = npcCount; data.Difficulty = difficulty; data.NPCState = npcState;
        data.Airborne=airborne;
        data.CoursePosition=zeros(numel(courseBodies),3);
        for k=1:numel(courseBodies), data.CoursePosition(k,:)=courseBodies(k).Position; end
        [data.StartLights,locked] = phxkart.startSignal(nowTime-startSequenceTime,options.StartLights);
        data.StartReady = ~locked;
        data.Position = zeros(totalCount,3); data.Velocity = zeros(totalCount,3);
        for j = 1:numel(bodies)
            data.Position(j,:) = bodies(j).Position; data.Velocity(j,:) = bodies(j).LinearVelocity;
        end
    end
    function timerError(~,event)
        paused = true;
        if isgraphics(status), status.String = 'Timer stopped. Return to Menu to restart.'; end
        warning('phxkart:Timer','%s',event.Data.Message);
    end
    function releaseWorld
        running = false; keys = struct;
        if ~isempty(clockTimer) && isvalid(clockTimer)
            stop(clockTimer); delete(clockTimer);
        end
        clockTimer = [];
        if ~isempty(sim) && isvalid(sim), delete(sim); end
        sim = [];
        for j = 1:numel(bodies)
            if isvalid(bodies(j)), delete(bodies(j)); end
        end
        bodies = phx.Body.empty;
        for j = 1:numel(obstacles)
            if isvalid(obstacles(j)), delete(obstacles(j)); end
        end
        obstacles = phx.Body.empty;
        for j=1:numel(courseBodies)
            if isvalid(courseBodies(j)), delete(courseBodies(j)); end
        end
        courseBodies=phx.Body.empty; courseViews={};
    end
    function closeDemo(varargin)
        releaseWorld();
        if isgraphics(fig), delete(fig); end
    end
end
