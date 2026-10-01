function [height,gradient,difference] = rampSupport(T,position,yaw,width)
%RAMPSUPPORT Resolve left/right wheel support instead of the centre point.
    side=[-sin(yaw) cos(yaw)];
    [left,gl]=phxkart.roadSurface(T,position+side*width/2);
    [right,gr]=phxkart.roadSurface(T,position-side*width/2);
    height=(left+right)/2; gradient=(gl+gr)/2; difference=left-right;
end
