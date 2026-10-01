function updateBars(H,S)
%UPDATEBARS Steering positive = left; 100% = speed-dependent steering lock.
    H.fill(1).XData = [0 S.throttle S.throttle 0];
    H.fill(2).XData = [0 S.brake S.brake 0];
    edge = .5-.5*S.steerInput;
    H.fill(3).XData = [.5 edge edge .5];
    H.label(1).String = sprintf('THROTTLE    %3.0f%%',100*S.throttle);
    H.label(2).String = sprintf('BRAKE          %3.0f%%',100*S.brake);
    direction = 'CENTER';
    if S.steerInput>1e-6, direction = 'LEFT'; elseif S.steerInput< -1e-6, direction = 'RIGHT'; end
    H.label(3).String = sprintf('STEER %s %3.0f%% / %.1f deg',direction,100*abs(S.steerInput),abs(S.steer)*180/pi);
end
