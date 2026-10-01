function S = state
    S = struct('throttle',0,'brake',0,'steer',0,'steerInput',0,'rpm',1600, ...
        'gear',1,'shift',0,'ax',0,'ay',0,'previousBrakeKey',false);
end
