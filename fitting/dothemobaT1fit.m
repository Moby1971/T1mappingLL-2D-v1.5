function [m0MapOut, t1MapOut] = dothemobaT1fit(app, slice, dynamic)

% -----------------------------------------------------------------------
% Performs a model-based T1 map fitting of multi-echo data for 1 slice
%
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% 12/08/2022
%
%------------------------------------------------------------


app.TextMessage('WARNING: MODEL BASED T1 FITTING IS WORK IN PROGRESS ...');


% Multicoil data
for k = 1:app.nrCoils
    kSpace(k,:,:,:) = squeeze(app.data{k}(:,:,:,slice,dynamic)); %#ok<AGROW> 
end


% Remove the TEs that are deselected in the app
delements = app.tiSelection==0;
tis = app.tis;
tis(delements) = [];
kSpace(:,delements,:,:) = [];


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
kSpacePics = permute(kSpace,[5 ,3 ,4 ,1 ,6 ,2 ,7 ,8 ,9 ,10,11,12,13,14]);


% Do a simple bart reconstruction of the individual images first
sensitivities = ones(size(kSpacePics));
picsCommand = 'pics -RW:6:0:0.001 ';
images = bart(app,picsCommand,kSpacePics,sensitivities);


% Do a phase correction
phaseImages = angle(images);
images = images.*exp(-1i.*phaseImages);
kSpacePics = bart(app,'fft -u 6',images);


% Prepare the inversion times matrix
TI(1,1,1,1,1,:) = tis*0.001; 


% Moba reco
bartCommand = 'moba -L -l1 -d4 -i8 -C100 -B0.0 -j0.01 -n ';
T1fit = bart(app,bartCommand,kSpacePics,TI);

T1fits(1,:,:,1,1,1,1) = T1fit(1,:,:,1,1,1,1);
T1fits(1,:,:,1,1,1,2) = T1fit(1,:,:,1,1,1,2);
T1fits(1,:,:,1,1,1,3) = T1fit(1,:,:,1,1,1,3);


% Calculate T1 map
T1map = bart(app,'looklocker ',T1fits);
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


app.TextMessage('WARNING: MODEL BASED T1 FITTING IS WORK IN PROGRESS ...');


end