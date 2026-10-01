function [input,N] = npcInput(N,A,P,pos,yaw,velocity,yawRate,traffic,dt)
%NPCINPUT Local path tracking, corner preview and short-range traffic response.
% Only pedal/steering commands: motion and collisions remain PHX-driven.
    count = size(A.xy,1);
    candidates = mod(N.index+(-20:35)-1,count)+1;
    [~,nearest] = min(sum((A.xy(candidates,:)-pos).^2,2));
    N.index = candidates(nearest);
    u = max(0,velocity(1));
    lateral = dot(pos-A.xy(N.index,:),A.normal(N.index,:));
    % Choose space alongside a slower kart; brake if that space is occupied.
    forward = [cos(yaw) sin(yaw)]; normal = [-forward(2) forward(1)];
    delta = traffic-pos;
    ahead = delta*forward'; beside = delta*normal';
    nearby = ahead>0 & ahead<max(7,u*1.2) & abs(beside)<1.5;
    desiredLane = N.lane;
    targetSpeed = A.speed(N.index)*N.pace;
    if any(nearby)
        leftFree = ~any(ahead>-3 & ahead<8 & beside>1 & beside<3.8);
        rightFree = ~any(ahead>-3 & ahead<8 & beside<-1 & beside>-3.8);
        if leftFree, desiredLane = 2;
        elseif rightFree, desiredLane = -2;
        end
        gap = min(ahead(nearby));
        targetSpeed = min(targetSpeed,max(0,(gap-2)*1.8));
    end
    N.offset = N.offset+max(-dt,min(dt,desiredLane-N.offset));
    look = 2.8+.48*u;
    if isfield(A,'lookBase'), look=A.lookBase+A.lookFactor*u; end
    s = mod(A.arc(N.index)+look,A.length);
    idx = find(A.arc(1:end-1)<=s,1,'last');
    f = (s-A.arc(idx))/A.ds(idx); next = mod(idx,count)+1;
    target = (1-f)*(A.xy(idx,:)+N.offset*A.normal(idx,:))+ ...
        f*(A.xy(next,:)+N.offset*A.normal(next,:));
    d = target-pos;
    curvature = 2*dot(d,normal)/max(dot(d,d),1);
    compliance = (1/P.corneringPerLoad(1)-1/P.corneringPerLoad(2))/9.81;
    angle = atan(P.L*curvature)+compliance*u^2*curvature;
    angle = angle+.045*(u*curvature-yawRate)-.10*atan2(velocity(2),max(u,2));
    % Invert the same speed-dependent steering map used by human players.
    lo = 0; hi = 1;
    for k = 1:12
        mid = (lo+hi)/2;
        if phxkart.steeringAngle(mid,u,P)<abs(angle), lo = mid; else, hi = mid; end
    end
    steer = sign(angle)*(lo+hi)/2;
    headingError = atan2(sin(atan2(d(2),d(1))-yaw),cos(atan2(d(2),d(1))-yaw));
    if abs(lateral)>3, targetSpeed = min(targetSpeed,5); end
    headingLimit=.65; if isfield(A,'headingLimit'), headingLimit=A.headingLimit; end
    if abs(headingError)>headingLimit, targetSpeed = min(targetSpeed,3.5); end
    error = targetSpeed-u;
    input = [max(0,min(1,.5*error)),max(0,min(1,-.45*error)),steer];
    N.targetSpeed = targetSpeed;
    % A stopped or spun kart can be returned to its last safe checkpoint by
    % the game after a delay, only when the recovery position is unoccupied.
    if u<.6 || abs(lateral)>5 || abs(headingError)>1.5
        N.stuck = N.stuck+dt;
    else
        N.stuck = 0;
    end
end
