function imagesOut = register_images(app,imagesIn,mask)

%------------------------------------------------------------
% Image registration for inversion recovery T1 mapping tool
%
%
% Gustav Strijkers
% Amsterdam UMC
% g.j.strijkers@amsterdamumc.nl
% 12/08/2022
%
%------------------------------------------------------------

% pp.mask = ones(app.dimx,app.dimy,app.ns,app.nd);

[nEchoes,~,~,nSlices,nDynamics] = size(imagesIn);

mask = permute(mask,[5 1 2 3 4]);
imagesIn = imagesIn.*mask;


[optimizer, metric] = imregconfig('multimodal');


loops = nDynamics*nSlices*(nEchoes-1);
cnt = 0;

for slice = 1:nSlices

    for dynamic = 1:nDynamics

        for echo = 2:nEchoes

            image0 = squeeze(imagesIn(1,:,:,slice,dynamic));
            image1 = squeeze(imagesIn(echo,:,:,slice,dynamic));

            max0 = median(image0(:));
            max1 = median(image1(:));

            image2 = imregister(image1/max1,image0/max0,'affine',optimizer, metric, 'DisplayOptimization', 0);

            imagesIn(echo,:,:,dynamic) = image2*max1;

            cnt = cnt + 1;

            app.RegProgressGauge.Value = round(100*cnt/loops);
            drawnow;

        end

    end

end

imagesOut = imagesIn;

end