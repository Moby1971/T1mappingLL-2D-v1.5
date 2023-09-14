function export_dicom_t1_dcm(directory,dcm_files_path,m0map,t1map,r2map,parameters)

%------------------------------------------------------------
%
% DICOM EXPORT OF T1 MAPS
% DICOM HEADER INFORMATION AVAILABLE
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% 12/08/2022
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
        dcm_header(slice,dynamic) = dicominfo([dcm_files_path,filesep,files{ (dynamic-1)*dimz*dimr + (slice-1)*dimr + 1 }]); %#ok<*AGROW>

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

% create folders if not exist, and delete folders content
outDir1 = strcat(directory,filesep,"DICOM",filesep,num2str(dcm_header(1).SeriesNumber),"T1",filesep,"1");
outDir2 = strcat(directory,filesep,"DICOM",filesep,num2str(dcm_header(1).SeriesNumber),"T1",filesep,"2");
outDir3 = strcat(directory,filesep,"DICOM",filesep,num2str(dcm_header(1).SeriesNumber),"T1",filesep,"3");

if ~exist(outDir1, 'dir')
    mkdir(outDir1);
end
delete(strcat(outDir1,filesep,'*'));

if ~exist(outDir2, 'dir')
    mkdir(outDir2);
end
delete(strcat(outDir2,filesep,'*'));

if ~exist(outDir3, 'dir')
    mkdir(outDir3);
end
delete(strcat(outDir3,filesep,'*'));



% Export the T1 map Dicoms
for dynamic = 1:dimd

    for slice=1:dimz

        dcm_header(slice,dynamic).ProtocolName = 'T1-map';
        dcm_header(slice,dynamic).SequenceName = 'T1-map';
        dcm_header(slice,dynamic).EchoTime = 1.1;
        dcm_header(slice,dynamic).ImageType = 'DERIVED\RELAXATION\T1';

        fn = ['0000',num2str(slice)];
        fn = fn(size(fn,2)-4:size(fn,2));

        dn = ['0000',num2str(dynamic)];
        dn = dn(size(dn,2)-4:size(dn,2));

        fname = strcat(outDir1,filesep,'T1-slice',fn,'-dynamic',dn,'.dcm');
        image = rot90(squeeze(cast(round(t1map(:,:,slice,dynamic)),'uint16')));
        dicomwrite(image, fname, dcm_header(slice,dynamic));

    end

end



% Export the M0 map Dicoms
for dynamic = 1:dimd

    for slice=1:dimz

        dcm_header(slice,dynamic).ProtocolName = 'M0-map';
        dcm_header(slice,dynamic).SequenceName = 'M0-map';
        dcm_header(slice,dynamic).EchoTime = 1.2;
        dcm_header(slice,dynamic).ImageType = 'DERIVED\RELAXATION\M0';

        fn = ['0000',num2str(slice)];
        fn = fn(size(fn,2)-4:size(fn,2));
        dn = ['0000',num2str(dynamic)];
        dn = dn(size(dn,2)-4:size(dn,2));

        fname = strcat(outDir2,filesep,'M0-slice',fn,'-dynamic',dn,'.dcm');
        image = rot90(squeeze(cast(round(m0map(:,:,slice,dynamic)),'uint16')));
        dicomwrite(image, fname, dcm_header(slice,dynamic));

    end

end



% Export the  R^2 map Dicoms
for dynamic = 1:dimd

    for slice=1:dimz

        dcm_header(slice,dynamic).ProtocolName = 'R^2-map';
        dcm_header(slice,dynamic).SequenceName = 'R^2-map';
        dcm_header(slice,dynamic).EchoTime = 1.3;
        dcm_header(slice,dynamic).ImageType = 'DERIVED\RELAXATION\R2';

        fn = ['0000',num2str(slice)];
        fn = fn(size(fn,2)-4:size(fn,2));
        dn = ['0000',num2str(dynamic)];
        dn = dn(size(dn,2)-4:size(dn,2));

        fname = strcat(outDir3,filesep,'R2-slice',fn,'-dynamic',dn,'.dcm');
        image = rot90(squeeze(cast(round(100*r2map(:,:,slice,dynamic)),'uint16')));
        dicomwrite(image, fname, dcm_header(slice,dynamic));

    end

end




end