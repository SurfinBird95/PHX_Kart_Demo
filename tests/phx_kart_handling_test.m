function report = phx_kart_handling_test
%PHX_KART_HANDLING_TEST Regression for the high-speed oversteer defect.
% Tests model stability, not agreement with measured real-kart behaviour.
    report = phx_kart_handling_probe;
    safe = report.Steering<=.8;
    assert(all(report.PeakSlipDeg(safe)<8),'Assisted steering range developed excessive sideslip.');
    assert(all(report.PeakSlipDeg<30),'Over-limit steering caused an abrupt spin.');
    assert(all(report.FinalSlipDeg<2),'Kart must recover after steering release.');
    assert(all(report.FinalKmh>10),'Kart spun to a stop during corner entry.');
    for manual = [false true]
        P = phxkart.parameters(manual);
        % Constant-forward-speed bench isolates throttle sensitivity from
        % the very different speeds reached during free acceleration.
        bench = phx_kart_handling_probe([50 0 .8;50 1 .8;50 0 1;50 1 1],true,manual);
        assert(all(bench.PeakSlipDeg(1:2)<6),'80% must remain stable at 50 km/h.');
        assert(bench.PeakSlipDeg(3)>8 && bench.PeakSlipDeg(3)>2*bench.PeakSlipDeg(1), ...
            'Full steering must allow a slide beyond the assisted range.');
        assert(bench.PeakSlipDeg(4)>1.5*bench.PeakSlipDeg(2));
        assert(bench.PeakYawDegSec(2)>.7*bench.PeakYawDegSec(1), ...
            'Full throttle must not remove most of the cornering response.');
        assert(all(bench.FinalSlipDeg<2) && all(bench.PeakSlipDeg<30));
        [~,grassNew] = phxkart.forces(phxkart.state,P,[8 2 0],0,[0 0 0],false,.008);
        oldGrass = P; oldGrass.grassMu = .48;
        [~,grassOld] = phxkart.forces(phxkart.state,oldGrass,[8 2 0],0,[0 0 0],false,.008);
        assert(abs(grassNew(2))>1.1*abs(grassOld(2)),'Grass lateral grip must increase.');
        assert(abs(P.b/P.L-.423076923076923)<1e-12);
        for speed = [30 50 90]/3.6
            J = zeros(2); h = 1e-5;
            for j = 1:2
                perturbation = zeros(1,2); perturbation(j) = h;
                [~,Fp,Mp] = phxkart.forces(phxkart.state,P,[speed perturbation(1) 0],perturbation(2),[0 0 0],true,.008);
                [~,Fm,Mm] = phxkart.forces(phxkart.state,P,[speed -perturbation(1) 0],-perturbation(2),[0 0 0],true,.008);
                J(:,j) = [(Fp(2)-Fm(2))/P.mass-2*speed*perturbation(2); ...
                    (Mp(3)-Mm(3))/P.inertia(3)]/(2*h);
            end
            assert(all(real(eig(J))<0),'Straight-running lateral dynamics must be stable.');
            assert(all(abs(eig(eye(2)+.008*J))<1),'Fixed time step must resolve lateral dynamics.');
        end
        L = phxkart.state; R = phxkart.state;
        for k = 1:100
            [L,Fl,Ml] = phxkart.forces(L,P,[10 .2 0],.1,[.5 0 .5],true,.008);
            [R,Fr,Mr] = phxkart.forces(R,P,[10 -.2 0],-.1,[.5 0 -.5],true,.008);
            assert(max(abs(Fl-[Fr(1) -Fr(2) Fr(3)]))<1e-9);
            assert(abs(Ml(3)+Mr(3))<1e-9,'Left/right response must be symmetric.');
        end
    end
    disp('PASS: 80% stable / full steering slide, throttle response, recovery, grass grip, lateral stability and symmetry.');
end
