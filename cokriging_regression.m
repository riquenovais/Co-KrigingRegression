%-----------------------------------------------------------------
% Description:
% This script implements the co-kriging regression, adapted from
% Multi-fidelity optimization via surrogate modelling - Forrester,
% Sobester and Keane (2007)
%-----------------------------------------------------------------
% Author: Henrique Cordeiro Novais
%-----------------------------------------------------------------
% Outputs:
%                ye_co: co-Kriging regression estimator
%                    s: estimated mean-squared error
%-----------------------------------------------------------------
% Inputs:
%               Xc, Yc: cheap data samples
%               Xe, Ye: expensive data samples
% pc, thetac, lambda_c: hyper-parameters of the cheap data
% pd, thetad, lambda_e: hyper-parameters of the difference model
%                  rho: scaling factor
%                yc_xe: cheap data evaluated at expensive samples
%                xplot: range for the regression
%-----------------------------------------------------------------
function [ye_co, s] = cokriging_regression(Xc,Yc,pc, thetac, ...
    lambda_c,Xe,Ye,pd,thetad,rho,lambda_d,yc_xe,xplot)

% Working with A
Xc = Xc';
[nc, ~] = size(Xc);
PsiC_xc_xc = zeros(nc,nc);
one = ones(nc,1);

for i=1:nc
    for j=1:nc
        PsiC_xc_xc(i,j) = exp(-thetac*(abs(Xc(i) - Xc(j))^pc));
    end
end

Yc = Yc';
mic = (one'*pinv(PsiC_xc_xc + eye(nc,nc)*lambda_c)*Yc) / (one'*pinv ...
    (PsiC_xc_xc + eye(nc,nc)*lambda_c)*one);
sigma2c = ((Yc-one*mic)' * pinv(PsiC_xc_xc + eye(nc,nc)*lambda_c) * ...
    (Yc-one*mic))/(nc);

% Working with B
[ne, ~] = size(Xe);
PsiC_xc_xe = zeros(nc,ne);

for i=1:nc
    for j=1:ne
        PsiC_xc_xe(i,j) = exp(-thetac*(abs(Xc(i) - Xe(j))^pc));
    end
end

% Working with C
for i=1:ne
    for j=1:nc
        PsiC_xe_xc(i,j) = exp(-thetac*(abs(Xe(i) - Xc(j))^pc));
    end
end

% Working with D
for i=1:ne
    for j=1:ne
        PsiC_xe_xe(i,j) = exp(-thetac*(abs(Xe(i) - Xe(j))^pc));
    end
end

PsiD_xe_xe = zeros(ne,ne);

one = ones(ne,1);

for i=1:ne
    for j=1:ne
        PsiD_xe_xe(i,j) = exp(-thetad*(abs(Xe(i) - Xe(j))^pd));
    end
end

d = Ye - rho.*yc_xe';
mid = (one'*pinv(PsiD_xe_xe + eye(ne,ne)*lambda_d)*d) / (one' ...
    *pinv(PsiD_xe_xe + eye(ne,ne)*lambda_d)*one);
sigma2d = ((d-one*mid)' * pinv(PsiD_xe_xe + eye(ne,ne)*lambda_d) * ...
    (d-one*mid)) / (ne);

% Complete Covariance Matrix Cm = [A B; C D]
A = sigma2c * (PsiC_xc_xc + eye(nc,nc)*lambda_c);
B = rho * sigma2c * (PsiC_xc_xe + [zeros(nc-ne,ne); eye(ne,ne)] * ...
    lambda_c);
C = rho * sigma2c * (PsiC_xe_xc + [zeros(ne,nc-ne) eye(ne,ne)] * ...
    lambda_c);
D = ((rho^2) * sigma2c * (PsiC_xe_xe + eye(ne,ne)*lambda_c)) + ...
    (sigma2d * (PsiD_xe_xe + eye(ne,ne)*lambda_d));
Cm = [A B; C D];

% Expensive estimator Ye(x)
y = [Yc; Ye];
for n=1:length(xplot)
    fprintf('%d / %d \n',n,length(xplot));
    for i=1:nc
        corr1(i,1) = exp(-thetac*(abs(Xc(i) - xplot(n))^pc));
    end

    for i=1:ne
        corr2(i,1) = exp(-thetac*(abs(Xe(i) - xplot(n))^pc));
        corr3(i,1) = exp(-(thetad*(abs(Xe(i) - xplot(n))^pd)));
    end

    above = rho * sigma2c * corr1;
    below = ((rho^2) * sigma2c * corr2) + (sigma2d * corr3);
    c = [above; below];
    mi = (ones(1,length(Cm)) * pinv(Cm) * y) / (ones(1,length(Cm)) * ...
        pinv(Cm) * ones(length(Cm),1));

    ye_co(n) = mi + ((c)' * pinv(Cm) * (y - ones(length(Cm),1)*mi));
    s(n) = abs( ((rho^2)*sigma2c*(1+lambda_c)) + (sigma2d*lambda_d) - ...
        (c'*pinv(Cm)*c) );
end
