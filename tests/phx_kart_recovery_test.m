function phx_kart_recovery_test
%PHX_KART_RECOVERY_TEST Safe placement and isolated single-kart reset.
    T=phxkart.track('obstacle');
    stranded=[.8 -9.5];
    props=[T.course.hay(:,1:2);T.course.cones(:,1:2)];
    [p,~,~]=phxkart.recoveryPose(T,stranded,zeros(0,2),props);
    assert(~isempty(p) && phxkart.roadSurface(T,p)==0);
    assert(norm(p-stranded)<8 && norm(p-T.xy(1,:))>15,'Recover near the crash, not the start.');
    [q,~,~]=phxkart.recoveryPose(T,stranded,p,props);
    assert(~isempty(q) && norm(q-p)>=4,'Recovery must avoid another kart.');
    blocked=[T.xy;T.xy+1.7*T.normal;T.xy-1.7*T.normal];
    p=phxkart.recoveryPose(T,stranded,blocked,props);
    assert(isempty(p),'Recovery must wait when every candidate is blocked.');
    f=phx_kart_demo(Start=true,Track="obstacle",Players=2,NPCs=2,Visible="off",RunTimer=false,StartLights=false);
    cleanup=onCleanup(@()closeValid(f)); api=getappdata(f,'PHXKartDemo');
    for k=1:25, api.Step(); end
    before=api.Snapshot(); assert(api.Recover(1)); after=api.Snapshot();
    assert(norm(after.Position(1,1:2)-before.Position(1,1:2))<=12);
    assert(~after.RolledOver(1) && after.Roll(1)==0 && after.RecoveryTime(1)==0);
    assert(all(after.Velocity(1,:)==0) && ~after.Race{1}.valid);
    assert(isequal(before.Position(2:end,:),after.Position(2:end,:)));
    assert(isequal(before.CoursePosition,after.CoursePosition) && before.Time==after.Time);
    assert(isequal(before.Race{1}.times,after.Race{1}.times) && before.Race{1}.gate==after.Race{1}.gate);
    fprintf('PASS: clear recovery placement, blocked-road waiting, isolated reset and lap preservation.\n');
end
function closeValid(f), if isgraphics(f), close(f); end, end
