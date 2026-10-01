function matrix = surfacePose(T,position,yaw)
%SURFACEPOSE Render the kart tangent to the local road, including transitions.
    [height,gradient] = phxkart.roadSurface(T,position);
    forward = [cos(yaw);sin(yaw);dot(gradient,[cos(yaw) sin(yaw)])];
    forward = forward/norm(forward);
    up = [-gradient(:);1]; up = up/norm(up);
    left = cross(up,forward); left = left/norm(left);
    up = cross(forward,left);
    matrix = [forward left up [position(:);height];0 0 0 1];
end
