function [m0mapOut,t1mapOut,r2mapOut] = dotheT1fit_slice(inputImages,mask,tis,rSquare,tiSelection)

%------------------------------------------------------------
%
% performs least-squares fitting of T1 map for 1 slice
%
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% 12/08/2022
%
%------------------------------------------------------------

% image dimensions
[~,dimx,dimy] = size(inputImages);
r2map = zeros(dimx,dimy);
x1 = zeros(dimx,dimy);
x2 = zeros(dimx,dimy);
x3 = zeros(dimx,dimy);

% drop the TEs that are deselected in the app
delements = find(tiSelection==0);
tis(delements) = [];
inputImages(delements,:,:) = [];

% Inversion recovery function
irfun = @(x,xdata)abs(x(1)-x(2)*exp(-x(3)*xdata));
opts = optimset('Display','off');

% Pre-determine fit parameter estimates
for j = 1:dimx
    for k = 1:dimy
        ydata(j,k,:) = squeeze(inputImages(:,j,k)); %#ok<*AGROW> 
        [~,indx] = min(squeeze(ydata(j,k,:)));
        t1estimate = 0.6931/tis(indx);
        x0(j,k,1) = ydata(j,k,end);
        x0(j,k,2) = ydata(j,k,1)+ ydata(j,k,end);
        x0(j,k,3) = t1estimate;

    end
end

% For all x-coordinates
parfor j=1:dimx
    
   % For all y-coordinates 
    for k=1:dimy
     
        % Only fit when mask value indicates valid data point
        if mask(j,k) == 1
     
            % Y data
            yd = squeeze(ydata(j,k,:));

            % LSQ fit
            x = lsqcurvefit(irfun,x0(j,k,:),tis,yd,[],[],opts);

            x1(j,k) = x(1);
            x2(j,k) = x(2);
            x3(j,k) = x(3);

            % R2 map
            func = abs(x(1)-x(2).*exp(-x(3).*tis));
            rss = sum((yd-func).^2);
            tss = sum((yd-mean(yd)).^2);
            r2map(j,k) = 1-rss/tss;

        end

    end
    
end

% Calculate M0 and T1 from fit parameters
m0map = abs(x1-x2);
t1map = ((x2./x1)-1).*(1./x3);
       
% Remove outliers
m0map(r2map < rSquare) = 0;
t1map(r2map < rSquare) = 0;
r2map(r2map < rSquare) = 0;
m0map(isnan(m0map)) = 0;
m0map(isinf(m0map)) = 0;
t1map(isnan(t1map)) = 0;
t1map(isinf(t1map)) = 0;
t1map(t1map > 5000) = 0;
t1map(t1map < 0) = 0;

t1mapOut = t1map;
m0mapOut = m0map;    
r2mapOut = r2map;
    
end