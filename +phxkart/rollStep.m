function [roll,rate,tipped] = rollStep(roll,rate,tipped,difference,width,airborne,dt)
%ROLLSTEP Reduced roll dynamics driven by unequal wheel support.
% Once past the balance limit, gravity carries the kart onto its side.
% This is a gameplay approximation, not a full suspension/contact model.
    if tipped
        target=sign(roll)*pi/2;
        acceleration=28*(target-roll)-8*rate;
    elseif airborne
        acceleration=-.5*rate;
    else
        target=asin(max(-.99,min(.99,difference/width)));
        acceleration=55*(target-roll)-7*rate;
    end
    rate=rate+acceleration*dt; roll=roll+rate*dt;
    if abs(roll)>42*pi/180, tipped=true; end
    roll=max(-pi*.65,min(pi*.65,roll));
end
