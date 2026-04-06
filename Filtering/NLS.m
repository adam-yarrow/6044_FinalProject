function [x0, P, details] = NLS(x0_0,h,H,y,R,options)
%{
Non-linear least squares solver using Gauss-Newton algorithm.

Inputs:
    x0_0: Initial x0 vector (nx1)
    h: Vector measurements function (function of x0) (N*p x 1)
    H: Jacobian matrix (function of x0) (nxn)
    y: Measurements vector (N*p x 1) (N = number of measurements, p =
    number of sensor states)
    R: Measurements covariance (N*p x N*p)
    options: Struct with options
%}

% Diagnostics
details = struct();
details.convergenceTrigger = '';
details.Jnls = [];
details.nAlphaItPerIt = [];
details.hitAlphaItLimiter = [];
details.alpha = [];
details.x0Log = [];
details.Jnls = [];

% Convergence Vars
nIts = 0;
fConverged = false;
x0_kt1 = x0_0; % for convergence purposes only
Jnls_kt1 = 10E100;
% Helpers
Rinv = inv(R);

% Solution Vars
x0 = x0_0;

while ~fConverged    
    nIts = nIts+1;

    % Get Measurements and Gradient at new point
    y_k = h(x0);
    H_k = H(x0);
    residuals_k = (y - y_k);
    dx = (H_k' * Rinv * H_k) \ (H_k' * Rinv * residuals_k);
    Jcurr = residuals_k'*Rinv*residuals_k;

    % Alpha Updates
    if ~options.fAlphaGoldenSearch
        [alpha, alphaIt] = alphaReductionAlgo(Rinv,Jcurr,y,options,dx,x0,h);
    else
        JnlsAlphaFunc = @(alpha) getJnlsForAlpha(alpha,x0,dx,h,Rinv,y);
        [alpha, alphaIt] = goldenSearch(JnlsAlphaFunc, options.minAlpha, 1, ...
            options.alphaRelTol, options.maxAlphaIterations);
    end

    details.nAlphaItPerIt(end+1) = alphaIt;
    details.alpha(end+1) = alpha;
    details.hitAlphaItLimiter(end+1) = alphaIt == options.maxAlphaIterations;
 
    % Get latest x0 and Jnls
    x0 = x0 + alpha*dx;
    residuals = y - h(x0);
    Jnls = residuals'*Rinv*residuals;
    details.Jnls(end+1) = Jnls;
    details.x0Log(:,end+1) = x0;

    % Check convergence
    [fConverged, details.convergenceTrigger] = checkConvergence(nIts, Jnls, Jnls_kt1, ...
        x0, x0_kt1, options);

    % Update persistent states
    x0_kt1 = x0;
    Jnls_kt1 = Jnls;
end

% Evaluate Covariance
P = inv(H(x0)'*Rinv*H(x0));

% Update Details
details.nIts = nIts;
end


%% Helper functions
function [alpha, alphaIt] = alphaReductionAlgo(Rinv,Jcurr,y,options,dx,x0,h)

    alphaIt = 0;
    alpha = 1;
    while alphaIt < options.maxAlphaIterations
        alphaIt = alphaIt+1;

        x0new = x0 + alpha*dx;
        residuals = y -  h(x0new);
        Jnls = residuals'*Rinv*residuals;
        if Jnls > Jcurr
            alpha = alpha*options.alphaSF;
        else
            break;
        end        
    end

end

function [alphaEst, itCounter] = goldenSearch(f, a, b, tol, maxIts)
    % Assumes unimodal function
    phi = 2/(sqrt(5) - 1);
    
    alphaEstPrev = 1;
    alphaEst = (b+a)/2;
    itCounter = 0;
    while (abs(alphaEst - alphaEstPrev)/alphaEstPrev > tol) && (itCounter < maxIts)
        c = b - (b-a)/phi;
        d = a + (b-a)/phi;

        if f(c) < f(d)
            b = d;
        else
            a = c;
        end          
        alphaEstPrev = alphaEst;
        alphaEst = (b+a)/2;
        itCounter = itCounter + 1;
    end
end

%% Helper Functions
% Jnls Alpha Function
function Jnls = getJnlsForAlpha(alpha,x0,dx,h,Rinv,y)
    x0New = x0 + alpha*dx;
    residuals = y - h(x0New);
    Jnls = residuals'*Rinv*residuals;   
end

% Global Convergence Check
function [fConverged, convergenceTrigger] = checkConvergence(nIts, Jnls, Jnls_kt1, x0, x0_kt1, options)
    convergenceTrigger = '';
    
    % Iterations
    fIterationsLimit = nIts >= options.maxIterations;
    if fIterationsLimit
        warning('Exceeded number of iterations for convergence');
        convergenceTrigger = 'Max Iterations';
    end
    
    % Jnls Tolerance
    fJnls = false;
    if isfield(options,'JnlsRelTol')
        fJnls = abs(Jnls - Jnls_kt1)/Jnls_kt1 < options.JnlsRelTol;
        if fJnls
            convergenceTrigger = 'Jnls';
        end
    end

    % Estimate Tolerance
    fX0 = false;
    if isfield(options,'x0Tol')
        fX0 = norm(x0 - x0_kt1) < options.x0Tol;
        if fX0
            convergenceTrigger = 'x0';
        end
    end   
    
    % Any flag is valid
    fConverged = fIterationsLimit | fJnls | fX0;
end