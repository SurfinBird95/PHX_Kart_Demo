function A = npcPlan(T,difficulty)
%NPCPLAN Shared, precomputed closed-path speed profile (SI units).
    level = find(strcmpi(difficulty,{'easy','medium','hard','race'}));
    assert(~isempty(level),'Unknown NPC difficulty.');
    A.xy = T.xy; A.normal = T.normal; A.tangent = T.tangent;
    A.ds = vecnorm(circshift(T.xy,-1)-T.xy,2,2);
    A.arc = [0;cumsum(A.ds)]; A.length = A.arc(end);
    heading = atan2(T.tangent(:,2),T.tangent(:,1));
    turn = mod(circshift(heading,-1)-circshift(heading,1)+pi,2*pi)-pi;
    A.curvature = turn./(A.ds+circshift(A.ds,1));
    lateral = [3.2 4.6 6.0 7.8]; top = [12 16 20 24];
    braking = [2.5 2.5 2.5 3.4];
    A.speed = min(top(level),sqrt(lateral(level)./max(abs(A.curvature),.002)));
    if isfield(T,'course') && ~isempty(T.course), A.speed=min(A.speed,10); end
    % Anticipate corners using a braking envelope, including across finish.
    for pass = 1:3
        for k = numel(A.ds):-1:1
            next = mod(k,numel(A.ds))+1;
            A.speed(k) = min(A.speed(k),sqrt(A.speed(next)^2+2*braking(level)*A.ds(k)));
        end
    end
    A.reaction = [.85 .5 .2 .10]; A.reaction = A.reaction(level);
    A.level = level;
end
