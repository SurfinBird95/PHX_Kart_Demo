function [height,gradient,gripScale] = roadSurface(T,position)
%ROADSURFACE Banked ribbon with a sloping outer earth shoulder.
% Gradient is dz/dx,dz/dy. PHX chassis contacts remain projected in XY.
    height = 0; gradient = [0 0]; gripScale = 1;
    if ~any(T.bank), return; end
    [~,index] = min(sum((T.xy-position).^2,2));
    count = size(T.xy,1); starts = [mod(index-2,count)+1 index];
    ends = mod(starts,count)+1;
    d = T.xy(ends,:)-T.xy(starts,:);
    fractions = max(0,min(1,sum((position-T.xy(starts,:)).*d,2)./sum(d.^2,2)));
    centers = T.xy(starts,:)+fractions.*d;
    [~,best] = min(sum((centers-position).^2,2));
    i = starts(best); j = ends(best); f = fractions(best);
    normal = (1-f)*T.normal(i,:)+f*T.normal(j,:); normal = normal/norm(normal);
    tangent = [normal(2) -normal(1)];
    lateral = dot(position-centers(best,:),normal);
    if abs(lateral)<=T.width/2
        gripScale = 1+.55*((1-f)*T.gripBoost(i)+f*T.gripBoost(j));
    end
    slope = (1-f)*tan(T.bank(i))+f*tan(T.bank(j));
    change = (tan(T.bank(j))-tan(T.bank(i)))/norm(d(best,:));
    edge = T.width/2+.55; across = edge-lateral;
    if across<=0 || slope==0, return; end
    height = -slope*across;
    gradient = slope*normal-across*change*tangent;
    if lateral < -edge
        % Match the earth embankment from the upper kerb to flat grass.
        factor = max(0,1-(-lateral-edge)/6);
        height = -slope*2*edge*factor;
        gradient = -2*edge*change*factor*tangent-slope*2*edge/6*normal;
        if factor==0, gradient = [0 0]; end
    end
end
