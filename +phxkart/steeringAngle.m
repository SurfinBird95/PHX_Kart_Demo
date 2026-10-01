function angle = steeringAngle(command,speed,P)
%STEERINGANGLE Keyboard map with a stable range and extra corner-entry travel.
% Understeer feed-forward offsets the linear tyre compliance. This is a
% gameplay steering assist, not a measured steering rack characteristic.
    magnitude = abs(command);
    demand = P.keyboardLateralAccel*min(magnitude/P.steeringKnee,1);
    excess = max(0,(magnitude-P.steeringKnee)/(1-P.steeringKnee));
    demand = demand+(P.overLimitAccel-P.keyboardLateralAccel)*excess;
    compliance = (1/P.corneringPerLoad(1)-1/P.corneringPerLoad(2))/9.81;
    compliance = compliance/(1+(abs(speed)/22)^4);
    speedAngle = sign(command)*min(.48,atan(demand*P.L/max(speed^2,.1))+demand*compliance);
    % At parking speed preserve proportional steering and its ramp. Applying
    % the acceleration formula near zero would jump straight to full lock.
    blend = max(0,min(1,(abs(speed)-3)/5));
    blend = blend^2*(3-2*blend);
    angle = (1-blend)*.48*command+blend*speedAngle;
end
