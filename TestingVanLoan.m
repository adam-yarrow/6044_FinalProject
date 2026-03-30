params = ModelParams();

x = [400+params.rEarth; 0; 0; 7.672];

[A] = getAfromState(x, params.mu);
gamma = [0, 0;
         1, 0;
         0, 0;
         0, 1];
W = diag([5,7]);
dT = params.dT;

F = expm(A*dT);


z = [-A, gamma*W*gamma';
    zeros(4,4), A'];

Z = expm(dT*z);
FinvQ = Z(1:4,5:end);

Q = F*FinvQ;

Qapprox = dT*gamma*W;
