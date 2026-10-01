function [S,input] = driveInput(S,P,input,velocity)
%DRIVEINPUT Single-speed arcade reverse, preserving brake-to-stop behaviour.
    brakePressed = input(2)>0 && ~S.previousBrakeKey;
    S.previousBrakeKey = input(2)>0;
    if isfield(P,'npc') && P.npc, return; end
    if P.manual, return; end
    stopped = norm(velocity(1:2))<.35;
    if S.gear==1 && stopped && brakePressed && input(1)==0
        S.gear = -1; S.throttle = 0; S.brake = 0;
    elseif S.gear==-1 && stopped && input(1)>0 && input(2)==0
        S.gear = 1; S.throttle = 0; S.brake = 0;
    end
    if S.gear==-1, input(1:2) = input([2 1]); end
end
