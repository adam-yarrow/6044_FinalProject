function [xIC] = generateGaussianX_IC(P0, mu0, n)
%{
    Draws n MV gaussian initial states from a given covariance matrix and
    mean vector.
%}

S = chol(P0,'lower');
xIC = mu0 + S*randn(ModelParams('nStates'),n);
end