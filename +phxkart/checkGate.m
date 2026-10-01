function r = checkGate(r,T,p0,p1,nowTime,dt)
%CHECKGATE Ordered, forward-only crossing with interpolated lap timestamp.
    if ~isfield(r,'route'), r.route = 0; end
    idx = T.gates(r.gate); c = T.xy(idx,:); t = T.tangent(idx,:);
    normal = T.normal(idx,:); halfWidth = T.width/2;
    hasChoice = ~isempty(T.gateAlternatives{r.gate});
    if hasChoice
        choices = [1 2]; if r.route~=0, choices = r.route; end
        for route = choices
            if route==1
                center = c; tangent = t; n = normal; width = halfWidth;
            else
                alt = T.gateAlternatives{r.gate};
                center = alt.center; tangent = alt.tangent; n = alt.normal; width = alt.halfWidth;
            end
            [hit,~] = crosses(p0,p1,center,tangent,n,width);
            if hit
                r.route = route;
                r.gate = mod(r.gate,numel(T.gates))+1;
                return;
            end
        end
        return;
    end
    a = dot(p0-c,t); b = dot(p1-c,t);
    if a < 0 && b >= 0
        fraction = -a/(b-a); crossing = p0+fraction*(p1-p0);
        if abs(dot(crossing-c,T.normal(idx,:))) <= T.width/2
            crossTime = nowTime-dt+fraction*dt;
            if r.gate==1
                if r.started
                    r.times(end+1) = crossTime-r.startTime;
                    r.validTimes(end+1) = r.valid;
                end
                r.started = true; r.startTime = crossTime; r.valid = true;
            end
            r.gate = mod(r.gate,numel(T.gates))+1;
            r.route = 0;
        end
    end
end
function [hit,fraction] = crosses(p0,p1,c,t,n,width)
    a = dot(p0-c,t); b = dot(p1-c,t); hit = false; fraction = 0;
    if a<0 && b>=0
        fraction = -a/(b-a);
        hit = abs(dot(p0+fraction*(p1-p0)-c,n))<=width;
    end
end
