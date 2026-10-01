function [lights,locked] = startSignal(elapsed,enabled)
%STARTSIGNAL Five red banks at 1..5 s; lights-out releases the grid at 6.5 s.
    locked = enabled && elapsed<6.5;
    lights = 0;
    if locked, lights = max(0,min(5,floor(elapsed))); end
end
