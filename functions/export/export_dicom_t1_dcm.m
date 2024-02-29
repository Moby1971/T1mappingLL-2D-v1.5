function export_dicom_t1_dcm(directory,dcm_files_path,m0map,t1map,r2map,parameters,tag)

%------------------------------------------------------------
%
% DICOM EXPORT OF T1 MAPS
% DICOM HEADER INFORMATION AVAILABLE
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% Feb 2024
%
%------------------------------------------------------------

% Phase orientation correction
if isfield(parameters, 'PHASE_ORIENTATION')
    if parameters.PHASE_ORIENTATION == 1
        t1map = permute(rot90(permute(t1map,[2 1 3 4]),1),[2 1 3 4]);
        m0map = permute(rot90(permute(m0map,[2 1 3 4]),1),[2 1 3 4]);
        r2map = permute(rot90(permute(r2map,[2 1 3 4]),1),[2 1 3 4]);
    end
end

[~,~,dimz,dimd] = size(t1map);
dimr = parameters.NO_ECHOES; % number of inversion times


% List of dicom file names
flist = dir(fullfile(dcm_files_path,'*.dcm'));
files = sort({flist.name});

% Assuming order is slices, inversion times, dynamics
% Will have to check if I have data


% Generate new dicom headers
for dynamic = 1:dimd

    for slice = 1:dimz

        % Read the Dicom header
        dcm_header(slice,dynamic) = dicominfo(strcat(dcm_files_path,filesep,files{ (dynamic-1)*dimz*dimr + (slice-1)*dimr + 1 })); %#ok<*AGROW>

        % Changes some tags
        dcm_header(slice,dynamic).ImageType = 'DERIVED\RELAXATION\';
        dcm_header(slice,dynamic).InstitutionName = 'Amsterdam UMC';
        dcm_header(slice,dynamic).InstitutionAddress = 'Amsterdam, Netherlands';
        dcm_header(slice,dynamic).TemporalPositionIdentifier = dynamic;
        dcm_header(slice,dynamic).NumberOfTemporalPositions = dimd;
        %dcm_header(slice,dynamic).ImagesInAcquisition = dimz*dimd;
        dcm_header(slice,dynamic).TemporalResolution = parameters.prep_delay + parameters.NO_ECHOES*parameters.ti; 

    end

end

% Create new directory
ready = false;
cnt = 1;
while ~ready
    folderName = strcat(directory,filesep,'DICOM',filesep,tag,'T1',filesep,num2str(cnt),filesep);
    if ~exist(folderName, 'dir')
        mkdir(folderName);
        ready = true;
    end
    cnt = cnt + 1;
end

dir41 = 'T1';
dir42 = 'M0';
dir43 = 'R2';

output_directory1 = strcat(folderName,dir41);
if ~exist(output_directory1, 'dir') 
    mkdir(output_directory1); 
end
delete(strcat(output_directory1,filesep,'*'));

output_directory2 = strcat(folderName,dir42);
if ~exist(output_directory2, 'dir')
    mkdir(output_directory2); 
end
delete(strcat(output_directory2,filesep,'*'));

output_directory3 = strcat(folderName,dir43);
if ~exist(output_directory3, 'dir')
    mkdir(output_directory3); 
end
delete(strcat(output_directory3,filesep,'*'));


% Export the T1 map Dicoms
seriesInstanceID = dicomuid;
for dynamic = 1:dimd

    for slice=1:dimz

        dcm_header(slice,dynamic).ProtocolName = 'T1-map';
        dcm_header(slice,dynamic).SequenceName = 'T1-map';
        dcm_header(slice,dynamic).SeriesInstanceUID = seriesInstanceID;
        dcm_header(slice,dynamic).ImageType = 'DERIVED\RELAXATION\T1';

        fn = strcat('0000',num2str(slice));
        fn = fn(size(fn,2)-4:size(fn,2));

        dn = strcat('0000',num2str(dynamic));
        dn = dn(size(dn,2)-4:size(dn,2));

        fname = strcat(output_directory1,filesep,'T1-slice',fn,'-dynamic',dn,'.dcm');
        image = rot90(squeeze(cast(round(t1map(:,:,slice,dynamic)),'uint16')));
        dicomwrite(image, fname, dcm_header(slice,dynamic));

    end

end



% Export the M0 map Dicoms
seriesInstanceID = dicomuid;
for dynamic = 1:dimd

    for slice=1:dimz

        dcm_header(slice,dynamic).ProtocolName = 'M0-map';
        dcm_header(slice,dynamic).SequenceName = 'M0-map';
        dcm_header(slice,dynamic).SeriesInstanceUID = seriesInstanceID;
        dcm_header(slice,dynamic).ImageType = 'DERIVED\RELAXATION\M0';

        fn = strcat('0000',num2str(slice));
        fn = fn(size(fn,2)-4:size(fn,2));
        dn = strcat('0000',num2str(dynamic));
        dn = dn(size(dn,2)-4:size(dn,2));

        fname = strcat(output_directory2,filesep,'M0-slice',fn,'-dynamic',dn,'.dcm');
        image = rot90(squeeze(cast(round(m0map(:,:,slice,dynamic)),'uint16')));
        dicomwrite(image, fname, dcm_header(slice,dynamic));

    end

end



% Export the  R^2 map Dicoms
seriesInstanceID = dicomuid;
for dynamic = 1:dimd

    for slice=1:dimz

        dcm_header(slice,dynamic).ProtocolName = 'R2-map';
        dcm_header(slice,dynamic).SequenceName = 'R2-map';
        dcm_header(slice,dynamic).SeriesInstanceUID = seriesInstanceID;
        dcm_header(slice,dynamic).ImageType = 'DERIVED\RELAXATION\R2';

        fn = strcat('0000',num2str(slice));
        fn = fn(size(fn,2)-4:size(fn,2));
        dn = strcat('0000',num2str(dynamic));
        dn = dn(size(dn,2)-4:size(dn,2));

        fname = strcat(output_directory3,filesep,'R2-slice',fn,'-dynamic',dn,'.dcm');
        image = rot90(squeeze(cast(round(100*r2map(:,:,slice,dynamic)),'uint16')));
        dicomwrite(image, fname, dcm_header(slice,dynamic));

    end

end




end