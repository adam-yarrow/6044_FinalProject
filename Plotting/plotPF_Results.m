function plotPF_Results(simData, pfResults)
    %{
        Plots the response of the PF for a single run.
    %}

    const = ModelParams();

    %% States Plot - MMSE and covariance 


    %% Error Plot - Ground Truth - Estimate + covariance bounds
    sigmaLevel = 2;
    plotErrors(simData, pfResults, const, sigmaLevel);

    %% measurements plot around the truth?

    %% States Plot - Animation with particles
    plotAnimatedStates(simData, pfResults, const);
    
end

%% Helper Functions
function plotErrors(simData, pfResults, const, sigmaLevel)
    
    figure('Name','State Errors');
    truthIdxMatchingPF = ismembertol(simData.t, pfResults.t,1E-9); % Tolerance could be sketchy?
    stateErrors = pfResults.xMMSE - simData.truth.debris(:,truthIdxMatchingPF);
    for iState = 1:const.nStates
        subplot(2,2,iState);
        hold on;
        plot(simData.t(truthIdxMatchingPF), stateErrors(iState,:),'r');
        stdDevOfState = squeeze(pfResults.xCov(iState,iState,:)).^0.5;
        plot(simData.t(truthIdxMatchingPF),-sigmaLevel*stdDevOfState,'k--');
        plot(simData.t(truthIdxMatchingPF),sigmaLevel*stdDevOfState,'k--');
        grid on;
        xlabel('Time (s)');
        ylabel(sprintf('%s (%s)',const.stateNames{iState},...
            const.stateUnits{iState}))
        legend('Error',sprintf('%i-sigma Bound',sigmaLevel));
    end
    sgtitle('State Errors vs Time')
    
end


function plotAnimatedStates(simData, pfResults, const)
    nParticles = size(pfResults.x,2);

    figure('Name','Particle Animation');
    % Setup initial truth plot
    ax = [];
    hParticles = [];
    for iState = 1:const.nStates
        ax(end+1) = subplot(2,2,iState);
        hold(ax(iState), 'on');
        plot(ax(iState), simData.t, simData.truth.debris(iState,:),'k',...
            'DisplayName','Truth Debris');
        plot(ax(iState), pfResults.t, pfResults.xMMSE(iState,:),'*m',...
            'DisplayName','MMSE');
        hParticles(end+1) = plot(ax(iState),NaN,NaN,'ro',... ...
            'DisplayName','Particles');
        
        % Plot settings
        xlabel(ax(iState),'Time (s)');
        ylabel(ax(iState),sprintf('%s (%s)',const.stateNames{iState},...
            const.stateUnits{iState}));
        grid(ax(iState),'on');
        xlim(ax(iState),[simData.t(1), simData.t(end)]);
        ylim(ax(iState),[min(simData.truth.debris(iState,:)), ...
            max(simData.truth.debris(iState,:))]);
        legend(ax(iState));
    end

    for iTime = 1:size(pfResults.x,3)
        for iState = 1:const.nStates
            set(hParticles(iState), ...
                'XData', repmat(pfResults.t(iTime),nParticles,1),...
                'YData',squeeze(pfResults.x(iState,:,iTime)));
            drawnow;
        end
        pause(0.075);
    end


    sgtitle('Particle States Vs Truth Debris States');

end
