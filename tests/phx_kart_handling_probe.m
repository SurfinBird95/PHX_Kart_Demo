function results = phx_kart_handling_probe(cases,holdSpeed,manual)
%PHX_KART_HANDLING_PROBE Reproducible free-running corner-entry experiments.
% Initial speed, constant pedal input, steering for 2 s, then release.
% holdSpeed=true is a lateral test bench: forward speed is externally held
% while lateral velocity and yaw remain free. It is not a free-driving lap.
    if nargin<2, holdSpeed = false; end
    if nargin<3, manual = false; end
    if nargin<1
        cases = [30 0 .25;30 1 .25;30 0 .8;30 1 .8;50 0 .8;50 1 .8;50 0 .9;50 1 .9;50 0 1;50 1 1;90 0 .8;90 1 .8];
    end
    results = zeros(size(cases,1),7);
    for j = 1:size(cases,1)
        P = phxkart.parameters(manual); S = phxkart.state;
        if manual, S.gear = 3; end
        b = phx.Body([], 'Mass',P.mass,'Inertia',P.inertia, ...
            'Shape',{'Box','Size',[1.65 1.12 .32]},'LinearVelocity',[cases(j,1)/3.6 0 0]);
        sim = phx.Simulation(b,'Gravity',[0 0 0]);
        cleanup = onCleanup(@()dispose(sim,b));
        maxSlip = 0; maxYaw = 0;
        for k = 1:500
            v = (b.Orientation'*b.LinearVelocity')'; w = b.AngularVelocity;
            if holdSpeed
                v(1) = cases(j,1)/3.6;
                b.LinearVelocity = (b.Orientation*v')';
            end
            steer = cases(j,3)*(k<=250);
            [S,F,M] = phxkart.forces(S,P,v,w(3),[cases(j,2) 0 steer],true,.008);
            b.applyForce(F); b.applyTorque(M); sim.step(.008,1,-1);
            if norm(v(1:2))>2, maxSlip = max(maxSlip,abs(atan2(v(2),v(1)))*180/pi); end
            maxYaw = max(maxYaw,abs(w(3))*180/pi);
        end
        v = (b.Orientation'*b.LinearVelocity')';
        results(j,:) = [cases(j,:) maxSlip maxYaw norm(b.LinearVelocity)*3.6 abs(atan2(v(2),v(1)))*180/pi];
        clear cleanup
    end
    results = array2table(results,'VariableNames', ...
        {'InitialKmh','Throttle','Steering','PeakSlipDeg','PeakYawDegSec','FinalKmh','FinalSlipDeg'});
    disp(results);
end
function dispose(sim,b)
    if isvalid(sim), delete(sim); end
    if isvalid(b), delete(b); end
end
