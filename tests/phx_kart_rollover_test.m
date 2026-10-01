function phx_kart_rollover_test
%PHX_KART_ROLLOVER_TEST Symmetric support and mirrored edge-entry rollovers.
    T=phxkart.track('obstacle');
    assert(all([T.course.ramps.width]==T.width));
    for ramp=T.course.ramps
      for side=[-1 0 1]
        roll=0; rate=0; tipped=false; maxRoll=0;
        for k=1:1800
            forward=[cos(ramp.yaw) sin(ramp.yaw)]; normal=[-forward(2) forward(1)];
            p=ramp.center+min(k*.008,ramp.length-.01)*forward+side*T.width/2*normal;
            [~,~,difference]=phxkart.rampSupport(T,p,ramp.yaw,1.12);
            [roll,rate,tipped]=phxkart.rollStep(roll,rate,tipped,difference,1.12,false,.008);
            maxRoll=max(maxRoll,abs(roll));
        end
        if side==0
            assert(~tipped && maxRoll<1e-10,'Centred ramp entry must not induce roll.');
        else
            assert(tipped && abs(abs(roll)-pi/2)<.01,'Half-width entry must settle on its side.');
            assert(sign(roll)==-side,'The kart must fall towards the unsupported side.');
        end
      end
    end
    fprintf('PASS: full-width ramps, symmetric support and both edge-entry rollovers.\n');
end
