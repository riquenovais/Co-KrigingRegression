function NegLnLikec=likelihoodc(x)
% NegLnLikec=likelihoodc(x)
%
% Calculates the negative of the concentrated ln-likelihood 
% of the cheap data
%
% Inputs:
%	x - vector of log(theta) parameters
%
% Global variables used:
%	ModelInfo.Xc - n x k matrix of sample locations
%	ModelInfo.yc - n x 1 vector of observed data
%
% Outputs:
%	NegLnLike - concentrated log-likelihood *-1 for minimising
%
% Copyright 2007 A I J Forrester
%
global ModelInfo
Xc=ModelInfo.Xc;
yc=ModelInfo.yc;
nc=size(Xc,1); 
thetac=10.^x(1);
pc=x(2);  
lambda_c = x(3);
one=ones(nc,1);
PsicXc=zeros(nc,nc);
for i=1:nc
	for j=i+1:nc
		PsicXc(i,j)=exp(-sum(thetac.*abs(Xc(i,:)-Xc(j,:)).^pc)); 
	end
end
PsicXc=PsicXc+PsicXc'+eye(nc)+eye(nc).*eps; 
PsicXc = PsicXc + lambda_c * eye(nc); 
[U,p]=chol(PsicXc);
if p>0
    NegLnLikec=100;
else
LnDetPsicXc=2*sum(log(abs(diag(U))));
muc=(one'*(U\(U'\yc)))/(one'*(U\(U'\one)));
SigmaSqrc=(yc-one.*muc)'*(U\(U'\(yc-one.*muc)))/nc;
NegLnLikec=-1*(-(nc/2)*log(SigmaSqrc)-0.5*LnDetPsicXc);
end
