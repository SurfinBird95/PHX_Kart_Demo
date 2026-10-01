function P = parameters(manual)
%PARAMETERS SI units. Estimates are intentionally separate from source data.
% Rotax Senior MAX: 22 kW @ 11500 rpm, 21 Nm @ 9000 rpm; 1.04 m wheelbase.
% https://www.rotax-racing.com/assets/uploads/Engines/Senior-MAX-Datasheet.pdf
% 162 kg = 2026 Senior minimum INCLUDING driver/equipment, not bare kart.
% Shifter: inspired by Vortex ROK 125, 43 HP @ 13900 rpm, six gears.
% https://vortex-engines.com/motori-rok-shifter_en.php
% All intermediate torque points, ratios, inertia, CG and tyre data below
% are engineering estimates, NOT identified manufacturer parameters.
    P.mass = 162; P.inertia = [18 22 32];
    P.L = 1.04; P.a = .60; P.b = .44;
    P.track = 1.12; P.cgHeight = .25; P.radius = .14;
    P.mu = 1.15; P.grassMu = .60; P.dragArea = .5;
    % Lateral stiffness per unit normal load [1/rad], front/rear.
    % Slightly stiffer rear response gives a mild understeer balance.
    P.corneringPerLoad = [10 12];
    P.keyboardLateralAccel = 8.5; % m/s^2 at 80% steering, assist not a tyre limit
    P.steeringKnee = .8; % last 20% of travel reaches beyond the assisted range
    P.overLimitAccel = 14;
    P.longitudinalTransferGain = .4; % softened pitch-load transfer for keyboard play
    P.rearPostPeakLoss = .05;
    P.driftYawDamping = 120; % N*m*s/rad, progressive anti-spin gameplay assist
    P.rpmPoints = [1500 3000 4500 6000 7500 9000 10500 11500 12500 14000];
    P.torquePoints = [4 7 10 13 17 21 20 18.27 15 0];
    P.ratios = 7.2; P.redline = 14000;
    P.reverseRatio = 16; P.reverseMaxSpeed = 3.3;
    P.manual = logical(manual);
    P.controls = phxkart.controls;
    if manual
        P.mass = 175;
        P.ratios = [16 12.8 10.6 9 7.8 6.8];
        P.rpmPoints = [1500 3000 4500 6000 7500 9000 11000 12500 13900 15000];
        P.torquePoints = [3 5 8 12 16 20 23 23 22 0];
        P.redline = 15000;
    end
end
