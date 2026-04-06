function plotPF_Results(simData, pfResults)
    %{
        Plots the response of the PF for a single run.
    %}

    const = ModelParams();

    %% States Plot - MMSE and covariance 


    %% Error Plot - Ground Truth - Estimate + covariance bounds
    

    %% measurements plot around the truth?

    %% States Plot - Animation with particles
    plotAnimatedStates(simData, pfResults, const);
    
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
        plot(ax(iState), simData.t, simData.truth.debris(iState,:),'k','DisplayName','Truth Debris');
        hParticles(end+1) = plot(ax(iState),NaN,NaN,'ro','DisplayName','Particles');
        
        % Plot settings
        xlabel(ax(iState),'Time (s)');
        ylabel(ax(iState),sprintf('%s (%s)',const.stateNames{iState},...
            const.stateUnits{iState}));
        grid(ax(iState),'on');
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

    legend();

    sgtitle('Particle States Vs Truth Debris States');

end
