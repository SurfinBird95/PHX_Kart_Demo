function [xy,yaw,index] = recoveryPose(T,position,others,props)
%RECOVERYPOSE Nearest clear, flat road within 12 m of the stranded kart.
% If the local area is blocked, wait instead of teleporting to the start.
    xy=[]; yaw=[]; index=[]; n=size(T.xy,1);
    points=[T.xy;T.xy-1.7*T.normal;T.xy+1.7*T.normal];
    distances=vecnorm(points-position(1:2),2,2);
    [~,order]=sort(distances);
    for candidate=order'
            if distances(candidate)>12, break; end
            k=mod(candidate-1,n)+1; p=points(candidate,:);
            if any(vecnorm(others-p,2,2)<4) || any(vecnorm(props-p,2,2)<3), continue; end
            if ~isempty(T.course)
                if norm(p-T.course.pivot(1:2))<8, continue; end
                % Check the whole chassis footprint, including either axle.
                safe=true;
                for along=[-.9 0 .9]
                    for across=[-.6 0 .6]
                        q=p+along*T.tangent(k,:)+across*T.normal(k,:);
                        [h,grade]=phxkart.roadSurface(T,q);
                        if h>.01 || norm(grade)>.01, safe=false; end
                    end
                end
                if ~safe, continue; end
            end
            xy=p; index=k; yaw=atan2(T.tangent(k,2),T.tangent(k,1)); return;
    end
end
