function plotNLS(nlsDetails,xTrue,times,xEst,xMeas)
% Diagnostics Plots
figure('Name','Diagnostics Plot');

subplot(5,1,1);
semilogy(nlsDetails.Jnls);
xlabel('Iteration');
ylabel('Jnls');
grid on;

subplot(5,1,2);
plot(nlsDetails.alpha);
xlabel('Iteration');
ylabel('Alpha [0,1]');
grid on;

subplot(5,1,3);
plot(nlsDetails.nAlphaItPerIt);
xlabel('Iteration');
ylabel('Alpha Iterations');
grid on;

subplot(5,1,4);
semilogy((sum((nlsDetails.x0Log - xTrue(:,1)).^2,1).^0.5));
xlabel('Iteration');
ylabel('||x_{k} - x_{true}||_2')
grid on;

subplot(5,1,5);
x0Convergence = sum((nlsDetails.x0Log(:,2:end) - nlsDetails.x0Log(:,1:end-1)).^2,1).^0.5;
semilogy(2:1:numel(x0Convergence)+1, x0Convergence);
xlabel('Iteration');
ylabel('||x_{k} - x_{k-1}||_2');
grid on;

sgtitle('Diagnostics Information');


% Plot Estimated Traj
figure('Name','Trajectory Plot');
hold on;
plot(xTrue(1,:),xTrue(3,:),'ko','DisplayName','Truth');
plot(xEst(1,:),xEst(3,:),'b','DisplayName','Estimated');
plot(xMeas(1,:),xMeas(2,:),'r*','DisplayName','Measurements');
grid on;
title('Comparison of truth and estimated trajectories');
xlabel('\zeta (m)');
ylabel('a (m)');
legend();

% Plot Errors
fPlotError = false;
if fPlotError
    figure('Name','Error Plot');
    xError = xTrue - xEst;
    stateNames = {'\zeta Error (m)','a Error (m)'};
    stateIdx = [1,3];
    for i = 1:2
        subplot(2,1,i);
        plot(times, xError(stateIdx(i),:));
        grid on;
        xlabel('Time (s)');
        ylabel(stateNames{i});
    end
    sgtitle('Error vs Time');
end
end