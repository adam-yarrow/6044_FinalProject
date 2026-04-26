function plotPF_KS_Test(pfResults, DmeanVariance, qt)
figure('Name','PF KS Test Results');
subplot(1,2,1); 
hold on;
h = plot(pfResults.t, squeeze(qt(1,:,:))','ko');
set(h(2:end),'HandleVisibility','off');
plot(pfResults.t, 2*DmeanVariance.^0.5,'r--','LineWidth',1.5);
plot(pfResults.t, -2*DmeanVariance.^0.5,'r--','LineWidth',1.5);
legend('Test Statistic', '2-sigma Bound');
title('Doppler Shift Measurements');
grid on;
xlabel('Time (s)');
ylabel('KS Test Statistic');
ax = gca;
ax.LineWidth = 2;  % Thicker axes
ax.FontSize = 12;

subplot(1,2,2); 
hold on;
h2 =plot(pfResults.t, squeeze(qt(2,:,:)),'ko');
set(h2(2:end),'HandleVisibility','off');
plot(pfResults.t, 2*DmeanVariance.^0.5,'r--','LineWidth',1.5);
plot(pfResults.t, -2*DmeanVariance.^0.5,'r--','LineWidth',1.5);
legend('Test Statistic', '2-sigma Bound');
title('Time of Flight Measurements');
grid on;
xlabel('Time (s)');
ylabel('KS Test Statistic');
ax = gca;
ax.LineWidth = 2;  % Thicker axes
ax.FontSize = 12;

sgtitle('KS Test Statistic Vs Time')
end