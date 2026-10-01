function S = shiftGear(S,P,change,velocity)
%SHIFTGEAR Sequential R / N / 1...6 with reverse and overspeed interlocks.
    if ~P.manual || S.shift>0 || change==0, return; end
    gear = max(-1,min(numel(P.ratios),S.gear+change));
    if gear==S.gear, return; end
    if gear==-1 && norm(velocity(1:2))>=.35, return; end
    if gear>0
        if velocity(1)<-.35, return; end
        rpm = abs(velocity(1))/P.radius*P.ratios(gear)*60/(2*pi);
        if rpm>=P.redline, return; end
    end
    S.gear = gear; S.shift = .12;
end
