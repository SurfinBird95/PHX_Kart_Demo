function B = courseBodies(T)
%COURSEBODIES Movable hay/cones and a kinematic pendulum hammer.
    B=phx.Body.empty;
    if isempty(T.course), return; end
    for k=1:size(T.course.hay,1)
        p=T.course.hay(k,:);
        B(k)=phx.Body([],'Mass',32,'Inertia',[9 13 15], ...
            'Position',[p(1:2) .55],'EulerAngles',[0 0 p(3)], ...
            'Shape',{'Box','Size',[1.8 1.2 1.1]},'Friction',[.5 0 0],'Restitution',.08);
    end
    for k=1:size(T.course.cones,1)
        p=T.course.cones(k,:);
        B(end+1)=phx.Body([],'Mass',4,'Inertia',[.25 .25 .25], ...
            'Position',[p(1:2) .4],'EulerAngles',[0 0 p(3)], ...
            'Shape',{'Box','Size',[.7 .7 .8]},'Friction',[.4 0 0],'Restitution',.1);
    end
    [p,R]=phxkart.hammerPose(T.course,0);
    B(end+1)=phx.Body([],'Type','kinematic','Position',p, ...
        'Shape',{'Box','Size',[1.1 2.4 1.1]},'Friction',[.35 0 0],'Restitution',.12);
    B(end).Orientation=R;
end
