function S = filterControls(S,C,input,dt,speed,maxSteer)
%FILTERCONTROLS Applied pedal/steering commands, independent of rendering.
    S.throttle = ramp(S.throttle,input(1),C.throttleTime,.12,dt);
    S.brake = ramp(S.brake,input(2),C.brakeTime,.12,dt);
    target = input(3);
    remaining = dt;
    if target*S.steerInput<0
        % Countersteering unwinds at least as quickly as releasing the key.
        % Split a step at zero so the outgoing side keeps its normal ramp
        % and the response does not depend on where zero falls in a frame.
        unwindTime = min(C.returnTime,C.steerTime);
        toCenter = abs(S.steerInput)*unwindTime;
        used = min(remaining,toCenter);
        S.steerInput = approach(S.steerInput,0,used/unwindTime);
        remaining = max(0,remaining-used);
    end
    steeringTime = C.steerTime;
    if target==0, steeringTime = C.returnTime; end
    S.steerInput = approach(S.steerInput,target,remaining/steeringTime);
    S.steerInput = max(-1,min(1,S.steerInput));
    if nargin<6
        S.steer = phxkart.steeringAngle(S.steerInput,speed,phxkart.parameters(false));
    else
        S.steer = S.steerInput*maxSteer;
    end
end
function value = approach(value,target,amount)
    value = value+max(-amount,min(amount,target-value));
end
function value = ramp(value,target,rise,release,dt)
    time = rise; if target<value, time = release; end
    value = max(0,min(1,value+max(-dt/time,min(dt/time,target-value))));
end
