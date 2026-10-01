function [position,rotation,velocity] = hammerPose(C,time)
%HAMMERPOSE Prescribed pendulum motion; contact response is solved by PHX.
    phase=2*pi*time/C.period;
    angle=C.amplitude*sin(phase); rate=C.amplitude*2*pi/C.period*cos(phase);
    forward=[cos(C.yaw) sin(C.yaw) 0]; side=[-forward(2) forward(1) 0];
    up=[0 0 1];
    position=C.pivot+C.arm*(sin(angle)*side-cos(angle)*up);
    rotation=[forward' (cos(angle)*side+sin(angle)*up)' (-sin(angle)*side+cos(angle)*up)'];
    velocity=C.arm*rate*(cos(angle)*side+sin(angle)*up);
end
