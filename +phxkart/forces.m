function [S,F,M,D] = forces(S,P,velocity,yawRate,input,onRoad,dt,grade,gripScale)
%FORCES Four contact patches, regularised slip, friction-circle saturation.
% Returns BODY-frame force/torque for PHX to integrate. No prescribed path.
% Planar approximation: quasi-static load transfer, no chassis flex/jacking,
% no wheel-spin DOF or identified Magic Formula. Locked-axle scrub is omitted.
    if nargin<8, grade = [0 0]; end
    if nargin<9 || ~onRoad, gripScale = 1; end
    normalGravity = 9.81/sqrt(1+dot(grade,grade));
    u = velocity(1); v = velocity(2);
    [S,input] = phxkart.driveInput(S,P,input,velocity);
    S = phxkart.filterControls(S,P.controls,input,dt,u,1);
    S.steer = phxkart.steeringAngle(S.steerInput,u,P);
    S.shift = max(0,S.shift-dt);
    ratio = 0;
    if S.gear>0, ratio = P.ratios(S.gear); end
    if S.gear==-1, ratio = P.reverseRatio; end
    wheelRPM = abs(u)/P.radius*ratio*60/(2*pi);
    % Automatic launch clutch: simplified slipping phase below 4200 rpm.
    S.rpm = max(1600+S.throttle*2600,wheelRPM);
    torque = interp1(P.rpmPoints,P.torquePoints,min(S.rpm,P.redline),'linear',0);
    drive = S.throttle*torque*ratio*.92/P.radius;
    if S.gear==0, S.rpm = 1600+S.throttle*(P.redline-2200); end
    if S.gear==-1
        drive = -.35*drive*max(0,min(1,(P.reverseMaxSpeed-max(0,-u))/.8));
    end
    if S.shift > 0 || S.rpm >= P.redline, drive = 0; end
    drag = -.5*1.225*P.dragArea*u*abs(u)-P.mass*9.81*.018*tanh(u/.5);
    if ~onRoad, drag = drag - 110*u; end
    mu = P.mu*gripScale;
    if ~onRoad, mu = P.grassMu; end
    frontLoad = P.mass*normalGravity*P.b/P.L-P.longitudinalTransferGain*P.mass*S.ax*P.cgHeight/P.L;
    frontLoad = max(.12*P.mass*normalGravity,min(.85*P.mass*normalGravity,frontLoad));
    rearLoad = P.mass*normalGravity-frontLoad;
    transfer = max(-.38*P.mass*9.81,min(.38*P.mass*9.81, ...
        P.mass*S.ay*P.cgHeight/P.track));
    loads = [frontLoad/2-transfer*.4,frontLoad/2+transfer*.4, ...
        rearLoad/2-transfer*.6,rearLoad/2+transfer*.6];
    loads = max(20,loads); loads = loads*P.mass*normalGravity/sum(loads);
    points = [P.a P.track/2;P.a -P.track/2;-P.b P.track/2;-P.b -P.track/2];
    F = [drag 0 0]; M = [0 0 0]; usage = zeros(1,4);
    wheelForce = zeros(2,4); wheelRotation = zeros(2,2,4);
    availableDrive = zeros(1,4);
    brakeFraction = [0 0 .5 .5];
    if P.manual, brakeFraction = [.3 .3 .2 .2]; end
    for k = 1:4
        x = points(k,1); y = points(k,2);
        delta = 0;
        if k <= 2
            delta = atan(tan(S.steer)/(1-y*tan(S.steer)/P.L));
        end
        R = [cos(delta) -sin(delta);sin(delta) cos(delta)];
        vel = R'*[u-yawRate*y; v+yawRate*x];
        slip = atan2(vel(2),max(abs(vel(1)),2));
        stiffness = P.corneringPerLoad(1+(k>2))*loads(k)*sqrt(gripScale);
        fy = -mu*loads(k)*tanh(stiffness*slip/(mu*loads(k)));
        if k>2
            % Gradual rear force drop beyond the peak slip angle. No yaw
            % impulse or steering-command-dependent change of friction.
            postPeak = max(0,min(1,(abs(slip)-.10)/.16));
            fy = fy*(1-P.rearPostPeakLoss*postPeak^2*(3-2*postPeak));
        end
        limit = mu*loads(k);
        fx = -S.brake*P.mass*9.81*.95*brakeFraction(k)*tanh(vel(1)/.4);
        wheelForce(:,k) = [fx;fy]; wheelRotation(:,:,k) = R;
        availableDrive(k) = sqrt(max(0,limit^2-fy^2));
    end
    % A common rear-axle traction limit preserves lateral grip without
    % inadvertently adding torque-vectoring yaw from unequal drive caps.
    axleDrive = sign(drive)*min(abs(drive)/2,min(availableDrive(3:4)));
    wheelForce(1,3:4) = wheelForce(1,3:4)+axleDrive;
    for k = 1:4
        fx = wheelForce(1,k); fy = wheelForce(2,k); limit = mu*loads(k);
        usage(k) = min(1,hypot(fx,fy)/limit);
        scale = min(1,limit/max(hypot(fx,fy),1e-9));
        f = wheelRotation(:,:,k)*[fx;fy]*scale;
        F(1:2) = F(1:2)+f';
        M(3) = M(3)+points(k,1)*f(2)-points(k,2)*f(1);
    end
    % Progressive anti-spin damping only after a substantial sideslip has
    % developed. It limits snap rotation; it never prescribes orientation.
    beta = atan2(v,max(abs(u),2));
    drift = max(0,min(1,(abs(beta)-8*pi/180)/(12*pi/180)));
    M(3) = M(3)-P.driftYawDamping*drift*yawRate;
    % Project gravity onto the road tangent; yaw/contact integration is XY.
    F(1:2) = F(1:2)-P.mass*9.81*grade/(1+dot(grade,grade));
    S.ax = max(-15,min(15,F(1)/P.mass));
    S.ay = max(-15,min(15,F(2)/P.mass));
    D = struct('grip',max(usage),'onRoad',onRoad,'speed',hypot(u,v)*3.6);
end
