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


% Prepare the inversion times matrix
TI(1,1,1,1,1,:) = tis*0.00001; 


% Moba reco
picscommand = 'moba -L -d4 -l1 -i8 -C100 -B0.0 -j0.1 -n';
t1Fit = bart(app,picscommand,kSpacePics,TI);

t1Fits(:,:,:,:,:,:,1) = t1Fit(:,:,:,:,:,:,2);
t1Fits(:,:,:,:,:,:,2) = t1Fit(:,:,:,:,:,:,1);
t1Fits(:,:,:,:,:,:,3) = t1Fit(:,:,:,:,:,:,3);


% Calculate T1 map
T1map = 10000*bart(app,'looklocker ',t1Fits);


% Extract Mss, M0, R1*
Mssmap = flip(squeeze(t1Fit(1,:,:,1,1,1,1)),2);
M0map = flip(squeeze(t1Fit(1,:,:,1,1,1,2)),2);
R1map = flip(squeeze(t1Fit(1,:,:,1,1,1,3)),2);
T1map = flip(T1map,2);


% Remove outliers
T1map(isinf(T1map)) = 0;
T1map(isnan(T1map)) = 0;
M0map(isinf(M0map)) = 0;
M0map(isnan(M0map)) = 0;
Mssmap(isinf(Mssmap)) = 0;
Mssmap(isnan(Mssmap)) = 0;


% Masking
t1MapOut = abs(T1map).*squeeze(app.mask(:,:,slice,dynamic));
m0MapOut = abs(Mssmap).*squeeze(app.mask(:,:,slice,dynamic));


app.TextMessage('WARNING: MODEL BASED T1 FITTING IS WORK IN PROGRESS ...');


end