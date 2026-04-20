
rngSeed = 100;
nMC = 10;
alpha = 0.05;
nWorkers = 6;
Np = 1000;

params = ModelParams();
%% TODO define mu0 and P0 with NLS warm start - for now copied from workspace

neesData = PF_NEES(nMC, rngSeed, alpha, nWorkers, params, mu0, P0, Np);