function NegLnLiked=likelihoodd(x)
% NegLnLiked=likelihoodd(x)
%
% Calculates the negative of the concentrated ln-likelihood of the
% difference model
%
% Inputs:
%	x - vetor of log(thetad) parameters
%
% Global variables used:
%	ModelInfo.Xe - ne x k matrix of expensive sample locations
%	ModelInfo.ye - ne x 1 vector of expensive observed data
%	ModelInfo.yc - nc x 1 vector of cheap observed data
%
% Outputs:
%	NegLnLiked - concentrated ln-likelihood *-1 for minimising
%
% Copyright 2007 A I J Forrester
%
global ModelInfo
Xe=ModelInfo.Xe;
ye=ModelInfo.ye;
yc=ModelInfo.yc;
ne=size(Xe,1); 
k=size(Xe,2);
thetad=10.^x(1);
rho=x(2);
pd = x(3);
lambda_e = x(4);
one=ones(ne,1);

% Pre-allocate memory
PsidXe=zeros(ne,ne);

% Build upper half of correlation matrix
for i=1:ne
	for j=i+1:ne
		PsidXe(i,j)=exp(-sum(thetad.*abs(Xe(i,:)-Xe(j,:)).^pd)); 
	end
end

% Add upper and lower halves and diagonal of ones plus 
% small number to reduce ill-conditioning
PsidXe=PsidXe+PsidXe'+eye(ne)+eye(ne).*eps; 
PsidXe = PsidXe + eye(ne,ne)*lambda_e;

% Cholesky factorisation
[U,p]=chol(PsidXe);

% Use penalty if ill-conditioned
if p>0
    NegLnLiked=1e4;
else
    % Sum lns of diagonal to find ln(abs(det(Psi)))
    LnDetPsidXe=2*sum(log(abs(diag(U))));

    % Difference vector
    d=ye-rho.*yc(end-ne+1:end);

    % Use back-substitution of Cholesky instead of inverse
    mud=(one'*(U\(U'\d)))/(one'*(U\(U'\one)));
    SigmaSqrd=(d-one.*mud)'*(U\(U'\(d-one.*mud)))/ne;
    NegLnLiked=-1*(-(ne/2)*log(SigmaSqrd)-0.5*LnDetPsidXe);
end
