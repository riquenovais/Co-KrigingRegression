%-----------------------------------------------------------------
% Title: Co-kriging estimator (regression)
% Authors: Henrique Cordeiro Novais, Samuel da Silva
% Date: August 15, 2023
%
% Description:
% This script demonstrates an example application of the 
% co-kriging regression method using a mathematical function.
%-----------------------------------------------------------------
clc; clear; close all;
%-----------------------------------------------------------------
% Seed definition to guarantee repeatability of random processes
%-----------------------------------------------------------------
mySeed = 626303;
rng_stream = RandStream('mt19937ar', 'Seed', mySeed);
RandStream.setGlobalStream(rng_stream);

% Configuration of plot appearance
nfonte = 25; % Font size for plots
marker = 20; % Marker size for plots

global ModelInfo % Declare global structure for model information

%% Step 1: Define Model Parameters and Input Distributions
%-----------------------------------------------------------------

% Load UQLab and configure the mathematical model
uqlab
ModelOpts.mString = 'X.*sin(X)'; % Model equation: X*sin(X)
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts); % Create model in UQLab

% Define uniform input distribution in the range [-3*pi, 3*pi]
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [-3*pi 3*pi];
myInput = uq_createInput(InputOpts);

% Define training sample size for the expensive model
Ntrain = 20;
Xe = uq_getSample(myInput, Ntrain); 
Ye = uq_evalModel(myModel, Xe); 
Ye = Ye + 0.2*std(Ye)*randn(size(Ye,1),1); 

% Define testing sample size for validation
Ntest = 100;
Xe_test = uq_getSample(myInput, Ntest); 
Ye_test = uq_evalModel(myModel, Xe_test); 
Ye_test = Ye_test + 0.2*std(Ye_test)*randn(size(Ye_test,1),1);

% Define data for cheaper model
Xc = linspace(-3*pi,3*pi,50);
Yc = 0.4*Xc.*sin(Xc) - 7; 

%% Step 2: Plot Training and Cheaper Model Data
%-----------------------------------------------------------------

figure;
plot(Xe, Ye, 'r.', 'MarkerSize', 35); hold on; 
plot(Xc, Yc, 'b.', 'MarkerSize', 35); 

% Add legend and labels
l = legend('$y_e$', '$y_c$', 'Location', 'Northwest');
set(l, 'interpreter', 'latex', 'fontsize', marker);
xlabel('$x$', 'FontSize', nfonte, 'interpreter', 'latex');
ylabel('$y$', 'FontSize', nfonte, 'interpreter', 'latex');
set(gca, 'FontSize', nfonte, 'TickLabelInterpreter', 'latex', ...
    'LineWidth', 1.5);
box on
xlim([-12 12]);
grid off

%% Step 3: Store Data for Co-Kriging Model
%-----------------------------------------------------------------

% Transpose cheaper model data for compatibility
Xc = Xc';
Yc = Yc';

% Store expensive and cheaper model data in a global structure
ModelInfo.Xe = Xe;
ModelInfo.Xc = Xc;
ModelInfo.ye = Ye;
ModelInfo.yc = Yc;

%% Step 4: Optimize Parameters for Co-Kriging Model
%-----------------------------------------------------------------

% Optimize parameters for the cheaper model 
Paramsc = ga(@likelihoodc, 3, [], [], [], [], [0.1 2 0.1], [5 2 10]);
thetac = Paramsc(1); 
pc = Paramsc(2); 
lambda_c = Paramsc(3); 

% Optimize parameters for the difference model
Paramsd = ga(@likelihoodd, 4, [], [], [], [], [0 2.5 2 5], [10 3 2 10]);
thetad = Paramsd(1); 
rho = Paramsd(2); 
pd = Paramsd(3); 
lambda_e = Paramsd(4); 

%% Step 5: Kriging Model for Expensive Data
%-----------------------------------------------------------------

% Set up the kriging model with training data
MetaOpts.ExpDesign.X = Xe;
MetaOpts.ExpDesign.Y = Ye;
MetaOpts.ExpDesign.Sampling = 'User';
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Regression.SigmaNSQ = 'auto';

% Create the kriging model and evaluate over a fine grid
myKriging = uq_createModel(MetaOpts);
Xc_kriging = linspace(min(Xe), max(Xe), 200);
[Yc_kriging, stdV, ~] = uq_evalModel(myKriging, Xc_kriging');

% Calculate the 95% confidence interval (Kriging)
u_band = Yc_kriging + 1.96*sqrt(stdV);
l_band = Yc_kriging - 1.96*sqrt(stdV);

%% Step 6: Plot Kriging Results with Validation Data
%-----------------------------------------------------------------

figure;
fill([Xc_kriging, fliplr(Xc_kriging)], [u_band', fliplr(l_band')], ...
    [0.8 0.8 0.8], 'facealpha', 0.8, 'EdgeColor', 'none') 
hold on; grid off;
plot(Xe, Ye, 'r.', 'MarkerSize', 35); 
plot(Xc_kriging, Yc_kriging, '-k', 'LineWidth', 3); 
plot(Xe_test, Ye_test, 'b.', 'MarkerSize', 30); 

% Add legend and labels
l = legend('', '$y_e$', 'Kriging', 'Validation');
set(l, 'interpreter', 'latex', 'fontsize', marker, 'location', ...
    'southeast', 'NumColumns', 3);
xlabel('$x$', 'FontSize', nfonte, 'interpreter', 'latex');
ylabel('$y$', 'FontSize', nfonte, 'interpreter', 'latex');
set(gca, 'FontSize', nfonte, 'TickLabelInterpreter', 'latex', ...
    'LineWidth', 1.5);
box on
xlim([min(Xe) max(Xe)]);
xticks(-12:4:12);
ylim([-12 12]);
grid on;

%% Step 7: Co-Kriging Prediction and Visualization
%-----------------------------------------------------------------

% Compute cheap model values at expensive model points
yc_xe = 0.4*Xe.*sin(Xe) - 7;

% Generate co-Kriging predictions
xplot = linspace(min(Xe), max(Xe), 100);
[ye_co, s] = cokriging_regression(Xc', Yc', pc, thetac, lambda_c, ...
    Xe, Ye, pd, thetad, rho, lambda_e, yc_xe', xplot);
sup = ye_co + 1.96*sqrt(s);
inf = ye_co - 1.96*sqrt(s);

% Plot co-Kriging results
figure
plot(Xc, Yc, 'b.', 'MarkerSize', 35); hold on; grid off;
fill([xplot, fliplr(xplot)], [sup, fliplr(inf)], [0.8 0.8 0.8], ...
    'facealpha', 0.8, 'EdgeColor', 'none'); 
plot(Xe, Ye, 'r.', 'MarkerSize', 35); 
plot(Xc_kriging, Yc_kriging, '--k', 'LineWidth', 3); 
plot(xplot, ye_co', 'color', [0 0.75 0], 'LineWidth', 3, ...
    'LineStyle', '--'); 
plot(Xe_test, Ye_test, 'k.', 'MarkerSize', 30); 

% Add legend and labels
l = legend('$y_c$', '', '$y_e$', 'Kriging', 'Co-Kriging', ...
    'Validation', 'Location', 'Northoutside', ...
    'Orientation', 'horizontal');
set(l, 'interpreter', 'latex', 'fontsize', marker);
xlabel('$x$', 'FontSize', nfonte, 'interpreter', 'latex');
ylabel('$y$', 'FontSize', nfonte, 'interpreter', 'latex');
set(gca, 'FontSize', nfonte, 'TickLabelInterpreter', 'latex', ...
    'LineWidth', 1.5);
box on
xlim([min(Xe) max(Xe)]);
xticks(-12:4:12);
ylim([-15 15]);
yticks(-15:5:15);
grid on;

% Display optimized parameters
fprintf('pc = %f \n', pc);
fprintf('pd = %f \n', pd);
fprintf('thetac = %f \n', thetac);
fprintf('thetad = %f \n', thetad);
fprintf('rho = %f \n', rho);
fprintf('lambda_c = %f \n', lambda_c);
fprintf('lambda_d = %f \n', lambda_e);
