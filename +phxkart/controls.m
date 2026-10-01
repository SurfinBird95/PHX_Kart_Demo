function C = controls
%CONTROLS Keyboard ramp times (seconds), shared defaults for both players.
% Full pedal travel and centre-to-lock steering are linear ramps. Pedals
% release in 0.12 s; steering has a separately adjustable centring time.
    C = struct('throttleTime',.45,'brakeTime',.30, ...
        'steerTime',.70,'returnTime',.35);
end
