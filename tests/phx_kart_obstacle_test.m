function phx_kart_obstacle_test
%PHX_KART_OBSTACLE_TEST Flight/landing, physical props and lifecycle checks.
    T=phxkart.track('obstacle'); assert(T.length<200 && numel(T.course.ramps)==2);
    [h,g]=phxkart.roadSurface(T,[-2 -14]); assert(abs(h-.55)<1e-9 && g(1)>0);
    props=phxkart.courseBodies(T);
    kart=phx.Body([],'Mass',162,'Position',[-9 14 .25],'LinearVelocity',[8 0 0], ...
        'Shape',{'Box','Size',[1.65 1.12 .32]});
    sim=phx.Simulation([kart props],'Gravity',[0 0 0]);
    cleanup=onCleanup(@()dispose(sim,[kart props]));
    initial=props(1).Position;
    for k=1:160
        phxkart.stepCourse(T,props,k*.008,.008,false); sim.step(.008,1,-1);
    end
    assert(norm(props(1).Position-initial)>.5,'Hay must move after a real kart contact.');
    phxkart.stepCourse(T,props,0,0,true);
    assert(norm(props(1).Position-initial)<1e-9,'Reset must restore hay.');
    cone=size(T.course.hay,1)+1; initialCone=props(cone).Position;
    kart.Position=initialCone+[-3 0 -.15]; kart.EulerAngles=[0 0 0];
    kart.LinearVelocity=[6 0 0]; kart.AngularVelocity=[0 0 0];
    for k=1:100
        phxkart.stepCourse(T,props,k*.008,.008,false); sim.step(.008,1,-1);
    end
    assert(norm(props(cone).Position-initialCone)>.5,'Cone must slide after contact.');
    phxkart.stepCourse(T,props,0,0,true);
    assert(norm(props(cone).Position-initialCone)<1e-9,'Reset must restore cones.');
    % Put a kart in the pendulum sweep and let the moving PHX collider hit it.
    kart.Position=[36 -.3 .25]; kart.LinearVelocity=[0 0 0]; kart.AngularVelocity=[0 0 0];
    speed=0;
    for k=1:100
        phxkart.stepCourse(T,props,-.4+k*.008,.008,false); sim.step(.008,1,-1);
        speed=max(speed,norm(kart.LinearVelocity));
    end
    assert(speed>1,'The hammer must transfer momentum to a kart.');
    clear cleanup
    f=phx_kart_demo(Start=true,Track="obstacle",Visible="off",RunTimer=false,StartLights=false);
    cleanFigure=onCleanup(@()closeValid(f)); api=getappdata(f,'PHXKartDemo');
    f.WindowKeyPressFcn(f,struct('Key','w')); flew=false; landed=false; maxHeight=0;
    for k=1:180
        api.Step(); s=api.Snapshot(); maxHeight=max(maxHeight,s.Position(1,3));
        if flew && ~s.Airborne(1) && s.Position(1,1)>3, landed=true; end
        flew=flew||s.Airborne(1);
    end
    assert(flew && landed && maxHeight>1.35,'Kart must launch and land after the ramp.');
    f.WindowKeyPressFcn(f,struct('Key','p')); before=api.Snapshot(); api.Step(); after=api.Snapshot();
    assert(isequal(before.CoursePosition,after.CoursePosition),'Pause must freeze obstacles.');
    f.WindowKeyPressFcn(f,struct('Key','r')); s=api.Snapshot();
    assert(~any(s.Airborne) && norm(s.CoursePosition(1,1:2)-T.course.hay(1,1:2))<1e-9);
    close(f); clear cleanFigure
    f=phx_kart_demo(Start=true,Track="obstacle",Players=2,NPCs=8,Visible="off",RunTimer=false,StartLights=false);
    cleanFigure=onCleanup(@()closeValid(f)); api=getappdata(f,'PHXKartDemo');
    for k=1:50, api.Step(); end
    s=api.Snapshot(); assert(size(s.Position,1)==10 && all(isfinite(s.Position),'all'));
    fprintf('PASS: obstacle course, movable hay/cones, hammer contact, jump/landing, pause/reset and 10-kart split screen.\n');
end
function closeValid(f), if isgraphics(f), close(f); end, end
function dispose(sim,bodies)
    if isvalid(sim), delete(sim); end
    for b=bodies, if isvalid(b), delete(b); end, end
end
