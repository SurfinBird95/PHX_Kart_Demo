function [position,yaw,index] = gridPose(T,slot,total)
%GRIDPOSE Two columns following the road backwards from the finish.
    spacing = vecnorm(circshift(T.xy,-1)-T.xy,2,2);
    arc = [0;cumsum(spacing)];
    distance = 3+3.2*floor((slot-1)/2);
    s = mod(arc(end)-distance,arc(end));
    index = find(arc(1:end-1)<=s,1,'last');
    fraction = (s-arc(index))/spacing(index);
    next = mod(index,size(T.xy,1))+1;
    center = (1-fraction)*T.xy(index,:)+fraction*T.xy(next,:);
    tangent = (1-fraction)*T.tangent(index,:)+fraction*T.tangent(next,:);
    tangent = tangent/norm(tangent);
    offset = 0; if total>1, offset = (2*mod(slot-1,2)-1)*1.25; end
    position = center+offset*[-tangent(2) tangent(1)];
    yaw = atan2(tangent(2),tangent(1));
end
