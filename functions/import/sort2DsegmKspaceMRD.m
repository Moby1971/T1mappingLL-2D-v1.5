function data = sort2DsegmKspaceMRD(data, parameters)


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


end % sort2DsegmKspaceMRD