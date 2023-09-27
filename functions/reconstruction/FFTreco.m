function images = FFTreco(app)


kspacesum = zeros(app.dimx,app.dimy);
for coil = 1:app.nrCoils
    kspacesum = kspacesum + squeeze(sum(app.data{coil},[1 4 5]));
end
[row, col] = find(ismember(kspacesum, max(kspacesum(:))));
tukeyfilter = circtukey2D(app.dimx,app.dimy,row,col,0.1);

coilimages = zeros(app.dimx,app.dimy,app.nrCoils);
app.images = zeros(app.ir,app.dimx,app.dimy,app.ns,app.nd);
for dynamic = 1:app.nd
    for irTime = 1:app.ir
        for slice = 1:app.ns
            for coil = 1:app.nrCoils
                coilimages(:,:,coil) = fft2reco(squeeze(app.data{coil}(irTime,:,:,slice,dynamic)).*tukeyfilter);
            end
            app.images(irTime,:,:,slice,dynamic) = rssq(coilimages,3);
        end
    end
end


images = app.images;


% --------------------------------------------------------------------------------

    function output = circtukey2D(dimy,dimx,row,col,filterwidth)

        % 2D Tukey filter

        domain = 512;
        base = zeros(domain,domain);

        tukey1 = tukeywin(domain,filterwidth);
        tukey1 = tukey1(domain/2+1:domain);

        shifty = (row-dimy/2)*domain/dimy;
        shiftx = (col-dimx/2)*domain/dimx;

        y = linspace(-domain/2, domain/2, domain);
        x = linspace(-domain/2, domain/2, domain);

        for i=1:domain

            for j=1:domain

                rad = round(sqrt((shiftx-x(i))^2 + (shifty-y(j))^2));

                if (rad <= domain/2) && (rad > 0)

                    base(j,i) = tukey1(rad);

                end

            end

        end

        output = imresize(base,[dimy dimx]);

    end % circtukey2D


    function X = fft2reco(x)

        % 2D FFT

        X=fftshift(ifft(fftshift(x,1),[],1),1)*sqrt(size(x,1));
        X=fftshift(ifft(fftshift(X,2),[],2),2)*sqrt(size(x,2));

        X = abs(X);

        X = flip(X,2);

    end % fft2reco





end