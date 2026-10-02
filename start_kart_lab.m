function fig = start_kart_lab
%START_KART_LAB Open the game menu after project dependencies are resolved.
% Can also be run directly on older MATLAB releases with PHX installed.
    if isempty(which('phx.Simulation'))
        error('phxkart:MissingToolbox', ...
            ['PHX Toolbox is not available. In R2026b or newer, open matlab.toml ' ...
             'as a project and resolve its dependencies. Alternatively install ' ...
             'PHX Toolbox through Add-On Explorer or run mpminstall PHXToolbox, ' ...
             'then run start_kart_lab again.']);
    end
    fig=findall(groot,'Type','figure','Tag','PHXKartLabLauncher');
    if ~isempty(fig)
        fig=fig(1); figure(fig); return;
    end
    fig=phx_kart_demo;
    fig.Tag='PHXKartLabLauncher';
end
