function [xErrMean, xErrMalhalanobis] = generatePF_NEES(simData,pfResults)
    nTimes = numel(pfResults.Ness);
    Np = pfResults.Np;

    xErrMalhalanobis = NaN(nTimes,Np);

    % Truth
    truthIdxMatchingPF = ismembertol(simData.t, pfResults.t, 1E-9); % Tolerance could be sketchy
    xDebrisTruth = simData.truth.debris(:,truthIdxMatchingPF);

    for iTime = 2:nTimes % First time will be NaN
        PkInv = inv(pfResults.xCov(:,:,iTime));
        for iParticle = 1:Np
            xErr = xDebrisTruth(:,iTime) - pfResults.x(:,iParticle,iTime);
            xErrMalhalanobis(iTime,iParticle) = xErr'*PkInv*xErr;
        end
    end

    xErrMean = mean(xErrMalhalanobis,2);
end