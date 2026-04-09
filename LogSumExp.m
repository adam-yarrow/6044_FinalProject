function [y] = LogSumExp(x)
    % Does the log sum exponential
    c = max(x);
    y = c + log(sum(exp(x-c)));
end