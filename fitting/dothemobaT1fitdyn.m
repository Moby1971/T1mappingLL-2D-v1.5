function [m0MapOut, t1MapOut] = dothemobaT1fitdyn(app, slice, dynamicRange)

% -----------------------------------------------------------------------
% Performs a model-based T1 map fitting of multi-echo data for 1 slice
% and all dynamics
%
% MOBAFIT does not seem to work for multiple dynamics
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% 12/08/2022
%
%------------------------------------------------------------


% Multicoil data
for k = 1:app.nrCoils
    kSpace(k,:,:,:,:) = squeeze(app.data{k}(:,:,:,slice,dynamicRange)); %#ok<AGROW> 
end

disp(size(kSpace))

% Remove the TEs that are deselected in the app
delements = app.tiSelection==0;
tis = app.tis;
tis(delements) = [];
kSpace(:,delements,:,:,:) = [];


% Bart dimensions
% 	READ_DIM,       1   z  
% 	PHS1_DIM,       2   y  
% 	PHS2_DIM,       3   x  
% 	COIL_DIM,       4   coils
% 	MAPS_DIM,       5   sense maps
% 	TE_DIM,         6   TIs
% 	COEFF_DIM,      7
% 	COEFF2_DIM,     8
% 	ITER_DIM,       9
% 	CSHIFT_DIM,     10
% 	TIME_DIM,       11  dynamics
% 	TIME2_DIM,      12  
% 	LEVEL_DIM,      13
% 	SLICE_DIM,      14  slices
% 	AVG_DIM,        15

%          1      2   3  4  5       
% kspace = coils, ir, x, y, dynamics
% 
%                            0  1  2  3  4  5  6  7  8  9  10 11 12 13
%                            1  2  3  4  5  6  7  8  9  10 11 12 13 14
kSpacePics = permute(kSpace,[6 ,3 ,4 ,1 ,7 ,2 ,8 ,9 ,10,11,5 ,12,13,14]);


% Do a simple bart reconstruction of the individual images first
sensitivities = ones(size(kSpacePics));
picsCommand = 'pics -RW:6:0:0.001 ';
images = bart(app,picsCommand,kSpacePics,sensitivities);

disp(size(images))

imageCorr = images(:,:,:,:,:,1,:,:,:,:,1);

% Do a phase correction
phaseImage = angle(imageCorr);
images = images.*exp(-1i.*phaseImage);
kSpacePics = bart(app,'fft -u 6',images);

disp(size(kSpacePics))


% Prepare the inversion times matrix
for i = dynamicRange
    TI(1,1,1,1,1,:,1,1,1,1,i) = tis*0.001;
end

disp(size(TI))


% Moba reco
bartCommand = 'moba -L -l1 -d4 -i8 -C100 -B0.0 -j0.01 -n ';
T1fit = bart(app,bartCommand,kSpacePics,TI);



% Calculate T1 map
T1map = bart(app,'looklocker ',T1fit);
T1map = flip(T1map,3);
T1map = 1000*squeeze(T1map(1,:,:));

% Extract M0
M0map = flip(squeeze(T1fit(1,:,:,1,1,1,2)),2);


% Remove outliers
T1map(isinf(T1map)) = 0;
T1map(isnan(T1map)) = 0;
M0map(isinf(M0map)) = 0;
M0map(isnan(M0map)) = 0;


% Masking
t1MapOut = abs(T1map).*squeeze(app.mask(:,:,slice,dynamic));
m0MapOut = abs(M0map).*squeeze(app.mask(:,:,slice,dynamic));



end