function [A] = getAfromState(x, mu)
    x1 = x(1);
    x3 = x(3);

    term_sq = x1^2 + x3^2;
    denom = term_sq^(5/2);
    a21 = (3 * mu * x1^2 - mu * term_sq) / denom;
    a23 = (3 * mu * x1 * x3) / denom;
    a41 = a23; 
    a43 = (3 * mu * x3^2 - mu * term_sq) / denom;
    
    A = [ ...
          0,   1,   0,   0; ...
        a21,   0, a23,   0; ...
          0,   0,   0,   1; ...
        a41,   0, a43,   0 ...
    ];
end