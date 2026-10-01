function stepCourse(T,B,time,dt,reset)
%STEPCOURSE Ground drag for movable hay; timed physical hammer collider.
    if isempty(B), return; end
    for k=1:numel(B)-1
        if k<=size(T.course.hay,1)
            initial=T.course.hay(k,:); height=.55; resistance=2.8;
        else
            initial=T.course.cones(k-size(T.course.hay,1),:); height=.4; resistance=4;
        end
        p=B(k).Position; a=B(k).EulerAngles; v=B(k).LinearVelocity; w=B(k).AngularVelocity;
        if reset
            p=[initial(1:2) height]; a=[0 0 initial(3)]; v=[0 0 0]; w=v;
        end
        B(k).Position=[p(1:2) height]; B(k).EulerAngles=[0 0 a(3)];
        speed=norm(v(1:2)); drag=max(0,1-resistance*dt/max(speed,1e-9));
        B(k).LinearVelocity=[v(1:2)*drag 0]; B(k).AngularVelocity=[0 0 w(3)*exp(-2*dt)];
    end
    [p,R,v]=phxkart.hammerPose(T.course,time);
    B(end).Position=p; B(end).Orientation=R; B(end).LinearVelocity=v;
end
