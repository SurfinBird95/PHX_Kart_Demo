function drawBank(ax,T)
%DRAWBANK Solid outer wall and vector-lettered motorsport advertising panels.
    brands = {'Škoda','Continental','Valeo','Humusoft','#AutaVUT','UADI'};
    colors = [.02 .35 .22;.95 .62 .03;.15 .45 .03;.06 .25 .55;.62 .04 .12;.15 .17 .21];
    locations = round(linspace(4,numel(T.bankWalls)-3,numel(brands)));
    faces = [1 4 3 2;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8];
    for k = 1:numel(T.bankWalls)
        O = T.bankWalls(k); c = cos(O.angle); s = sin(O.angle);
        R = [c -s;s c];
        v = [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1;-1 -1 1;1 -1 1;1 1 1;-1 1 1].*O.size/2;
        v(:,1:2) = v(:,1:2)*R'+O.position; v(:,3) = v(:,3)+O.base+O.size(3)/2;
        patch(ax,'Vertices',v,'Faces',faces,'FaceColor',[.65 .68 .70],'EdgeColor','none');
        brand = find(locations==k,1);
        if isempty(brand), continue; end
        word = brands{brand};
        % The road is to the left of these forward-oriented outer segments.
        center = O.position+.225*[-s c]; width = O.size(1)*.91;
        p = center+[-width/2;width/2;width/2;-width/2]*[c s];
        patch(ax,p(:,1),p(:,2),O.base+[.14;.14;1.02;1.02],colors(brand,:), ...
            'EdgeColor','none','FaceLighting','none','Tag','KartSponsor','UserData',word);
        ink = [1 1 1]; if brand==2, ink = [.08 .08 .08]; end
        letterWidth = width/(numel(word)*1.4); letterHeight = .54;
        for letter = 1:numel(word)
            strokes = glyph(upper(word(letter)));
            x = -width/2+letterWidth*.2+(letter-1)*letterWidth*1.4+strokes(:,1)*letterWidth;
            % Viewed from the road, reading direction is opposite travel.
            p = center+.012*[-s c]-x*[c s];
            plot3(ax,p(:,1),p(:,2),O.base+.31+letterHeight*strokes(:,2), ...
                'Color',ink,'LineWidth',max(.65,1.8*min(1,6/numel(word))),'Clipping','on');
        end
    end
end
function p = glyph(c)
    switch c
        case 'M', p = [0 0;0 1;.5 .45;1 1;1 0];
        case 'O', p = [0 0;0 1;1 1;1 0;0 0];
        case 'T', p = [0 1;1 1;NaN NaN;.5 1;.5 0];
        case 'U', p = [0 1;0 0;1 0;1 1];
        case 'L', p = [0 1;0 0;1 0];
        case 'B', p = [0 0;0 1;.75 1;1 .8;.75 .55;0 .55;NaN NaN;.75 .55;1 .3;.75 0;0 0];
        case 'R', p = [0 0;0 1;1 1;1 .55;0 .55;NaN NaN;.4 .55;1 0];
        case 'E', p = [1 1;0 1;0 0;1 0;NaN NaN;0 .5;.8 .5];
        case 'S', p = [1 1;0 1;0 .5;1 .5;1 0;0 0];
        case 'C', p = [1 1;0 1;0 0;1 0];
        case 'H', p = [0 0;0 1;NaN NaN;1 0;1 1;NaN NaN;0 .5;1 .5];
        case 'N', p = [0 0;0 1;1 0;1 1];
        case 'G', p = [1 1;0 1;0 0;1 0;1 .5;.5 .5];
        case 'K', p = [0 0;0 1;NaN NaN;1 1;0 .5;1 0];
        case 'Š', p = [1 1;0 1;0 .5;1 .5;1 0;0 0;NaN NaN;.2 1.3;.5 1.1;.8 1.3];
        case 'D', p = [0 0;0 1;.7 1;1 .75;1 .25;.7 0;0 0];
        case 'A', p = [0 0;.5 1;1 0;NaN NaN;.25 .5;.75 .5];
        case 'I', p = [0 1;1 1;NaN NaN;.5 1;.5 0;NaN NaN;0 0;1 0];
        case 'V', p = [0 1;.5 0;1 1];
        case 'F', p = [0 0;0 1;1 1;NaN NaN;0 .5;.8 .5];
        case '#', p = [.2 0;.4 1;NaN NaN;.6 0;.8 1;NaN NaN;0 .3;1 .3;NaN NaN;0 .7;1 .7];
    end
end
