function updateCourse(G,T,B)
    if isempty(G), return; end
    for k=1:numel(G.hay), G.hay(k).Matrix=[B(k).Orientation B(k).Position';0 0 0 1]; end
    b=B(end); G.head.Matrix=[b.Orientation b.Position';0 0 0 1];
    p=T.course.pivot; q=b.Position;
    set(G.arm,'XData',[p(1) q(1)],'YData',[p(2) q(2)],'ZData',[p(3) q(3)]);
end
