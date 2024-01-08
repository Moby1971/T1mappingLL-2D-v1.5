%------------------------------------------------------------
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% 26/4/2023
%
%------------------------------------------------------------


function data = sort2DsegmKspaceMRD(data, parameters, toggle)

% PPL version
version = regexp(parameters.PPL,'\d*','Match');
version = str2num(cell2mat(version(end))); %#ok<ST2NM>
crit1 = version > 634;
if version==606
    crit1 = true;
end

if toggle
    crit1 = ~crit1;
end

% FLASH yes or no ?
crit2 = contains(parameters.PPL,"flash");

if crit1 && crit2

    % data = (echoes, dimx, dimy, dimz, dynamics)

    [ne, dimx, dimy, dimz, nrd] = size(data);

    nrLines = parameters.lines_per_segment;

    for slices = 1:dimz

        for dynamic = 1:nrd

            ks = squeeze(data(:,:,:,slices,dynamic));
            ks = permute(ks,[1 3 2]);
            ks = reshape(ks(:),[nrLines ne dimy/nrLines dimx]);
            ks = permute(ks,[2 1 3 4]);
            ks = reshape(ks(:),[ne dimy dimx]);
            ks = permute(ks,[1 3 2]);
            data(:,:,:,slices,dynamic) = ks(:,:,:);

        end

    end

end


end % sort2DsegmKspaceMRD