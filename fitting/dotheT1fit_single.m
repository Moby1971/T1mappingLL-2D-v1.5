function [AvalueOut,BvalueOut,m0ValueOut,t1ValueOut,r2ValueOut] = dotheT1fit_single(yData,tis,rSquare,tiSelection)

%------------------------------------------------------------
%
% performs the T1 map fitting for 1 point or mean ROI value
%
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% 12/08/2022
%
%------------------------------------------------------------

% drop the TEs that are deselected in the app
delements = find(tiSelection==0);
tis(delements) = [];
yData(delements) = [];

% Inversion recovery function
irfun = @(x,xData)abs(x(1)-x(2)*exp(x(3)*xData));
opts = optimset('Display','off');

% Estimates
[~,indx] = min(yData(:));
x0(1) = yData(end);
x0(2) = yData(1)+yData(end);
x0(3) = -0.6931/tis(indx);

% LSQ fit
x = lsqcurvefit(irfun,x0,tis',yData,[],[],opts);

% M0 and T1
m0Value = abs(x(1));
t1Value = (x(2)/x(1)-1)*(-1/x(3));

% R^2 value
func = abs(x(1)-x(2).*exp(x(3).*tis'));
rss = sum((yData-func).^2);
tss = sum((yData-mean(yData)).^2);
r2Value = 1-rss/tss;

% Check for low R-square
if r2Value < rSquare
    m0Value = 0;
    t1Value = 0;
    r2Value = 0;
end

% Some limits
t1Value(isnan(t1Value)) = 0;
t1Value(isinf(t1Value)) = 0;
t1Value(t1Value < 0) = 0;
t1Value(t1Value > 5000) = 0;

m0Value(isnan(t1Value)) = 0;
m0Value(isinf(t1Value)) = 0;
m0Value(t1Value < 0) = 0;
m0Value(t1Value > 5000) = 0;

r2Value(isnan(t1Value)) = 0;
r2Value(isinf(t1Value)) = 0;
r2Value(t1Value < 0) = 0;
r2Value(t1Value > 5000) = 0;

% Return the values
t1ValueOut = t1Value;
m0ValueOut = m0Value;
r2ValueOut = r2Value;
AvalueOut = x(1);
BvalueOut = x(2);

end