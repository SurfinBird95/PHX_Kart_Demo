function [xy,yaw,index] = recoveryPose(T,r,others,props)
%RECOVERYPOSE Find clear, flat road behind the last passed checkpoint.
    gate=mod(r.gate-2,numel(T.gates))+1;
    if ~r.started, gate=1; end
    anchor=T.gates(gate); xy=[]; yaw=[]; index=[];
    for back=2:2:90
        k=mod(anchor-back-1,size(T.xy,1))+1;
        for offset=[0 -1.7 1.7]
            p=T.xy(k,:)+offset*T.normal(k,:);
            if any(vecnorm(others-p,2,2)<4) || any(vecnorm(props-p,2,2)<3), continue; end
            if ~isempty(T.course)
                if norm(p-T.course.pivot(1:2))<8, continue; end
                h=phxkart.roadSurface(T,p);
                [support,grade]=phxkart.rampSupport(T,p,atan2(T.tangent(k,2),T.tangent(k,1)),1.12);
                if max(h,support)>.01 || norm(grade)>.01, continue; end
            end
            xy=p; index=k; yaw=atan2(T.tangent(k,2),T.tangent(k,1)); return;
        end
    end
end
