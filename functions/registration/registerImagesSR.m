function registerImagesSR(app)

% Registration of multi-echo images

imagesIn = app.images;

[dimI,~,~,dimZ,dimD] = size(imagesIn);

app.TextMessage('Image registration ...');

try
    
    % Temp directory for storing registration files
    outputDir = tempdir;
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    [~,elastix_version] = system('elastix --version');
    app.TextMessage(elastix_version);
  
    switch app.RegistrationDropDown.Value
        case 'Translation'
            fileName = 'regParsTrans.txt';
        case 'Rigid'
            fileName = 'regParsRigid.txt';
        case 'Affine'
            fileName = 'regParsAffine.txt';
        case 'B-Spline'
            fileName = 'regParsBSpline.txt';
    end
    [regParDir , ~] = fileparts(which(fileName));
    regParFile = strcat(regParDir,filesep,fileName);

    % Timing parameters
    app.EstimatedRegTimeViewField.Value = 'Calculating ...';
    elapsedTime = 0;
    totalNumberOfSteps = dimD*dimZ*(dimI-1);
    app.RegProgressGauge.Value = 0;
    app.abortRegFlag = false;
    cnt = 1;

    dynamic = 0;

    while dynamic<dimD && ~app.abortRegFlag

        dynamic = dynamic + 1;

        slice = 0;

        while slice<dimZ && ~app.abortRegFlag

            slice = slice + 1;

            app.TextMessage(strcat("Slice = ",num2str(slice),", dynamic = ",num2str(dynamic)," ..."));

            echo = 0;

            while echo<(dimI-1)  && ~app.abortRegFlag

                echo = echo + 1;

                tic;

                % Fixed and moving image
                image0 = squeeze(imagesIn(dimI,:,:,slice,dynamic));
                image1 = squeeze(imagesIn(echo,:,:,slice,dynamic));

                % Register
                image2 = elastix(image1,image0,outputDir,regParFile);

                % New registered image
                imagesIn(echo,:,:,slice,dynamic) = image2;

                % Update the registration progress gauge
                app.RegProgressGauge.Value = round(100*(cnt/totalNumberOfSteps));

                % Update the timing indicator
                elapsedTime = elapsedTime + toc;
                estimatedtotaltime = elapsedTime * totalNumberOfSteps / cnt;
                timeRemaining = estimatedtotaltime * (totalNumberOfSteps - cnt) / totalNumberOfSteps;
                timeRemaining(timeRemaining<0) = 0;
                app.EstimatedRegTimeViewField.Value = strcat(datestr(seconds(timeRemaining),'MM:SS')," min:sec"); %#ok<*DATST>
                drawnow;

                cnt = cnt+1;

            end

        end

    end

    app.TextMessage('Finished ... ');
    app.EstimatedRegTimeViewField.Value = 'Finished ...';

catch ME

    app.TextMessage(ME.message)

    % Matlab

    app.TextMessage('Elastix failed, registering images using Matlab ...');

    [optimizer, metric] = imregconfig('multimodal');

    switch app.RegistrationDropDown.Value
        case 'Translation'
            method = 'translation';
        case 'Rigid'
            method = 'rigid';
        case 'Affine'
            method = 'similarity';
        case 'B-Spline'
            method = 'affine';
    end

    % Timing parameters
    app.EstimatedRegTimeViewField.Value = 'Calculating ...';
    elapsedTime = 0;
    totalNumberOfSteps = dimD*dimZ*(dimI-1);
    app.RegProgressGauge.Value = 0;
    app.abortRegFlag = false;
    cnt = 1;

    dynamic = 0;

    while dynamic<dimD && ~app.abortRegFlag

        dynamic = dynamic + 1;

        slice = 0;

        while slice<dimZ && ~app.abortRegFlag

            slice = slice + 1;

            app.TextMessage(strcat("Slice = ",num2str(slice),", dynamic = ",num2str(dynamic)," ..."));

            echo = 0;

            while echo<(dimI-1)  && ~app.abortRegFlag

                echo = echo + 1;

                tic;

                % Fixed and moving image
                image0 = squeeze(imagesIn(dimI,:,:,slice,dynamic));
                image1 = squeeze(imagesIn(echo,:,:,slice,dynamic));

                % Register
                image2 = imregister(image1,image0,method,optimizer, metric,'DisplayOptimization',0);

                % New registered image
                imagesIn(echo,:,:,slice,dynamic) = image2;

                % Update the registration progress gauge
                app.RegProgressGauge.Value = round(100*(cnt/totalNumberOfSteps));

                % Update the timing indicator
                elapsedTime = elapsedTime + toc;
                estimatedtotaltime = elapsedTime * totalNumberOfSteps / cnt;
                timeRemaining = estimatedtotaltime * (totalNumberOfSteps - cnt) / totalNumberOfSteps;
                timeRemaining(timeRemaining<0) = 0;
                app.EstimatedRegTimeViewField.Value = strcat(datestr(seconds(timeRemaining),'MM:SS')," min:sec"); %#ok<*DATST>
                drawnow;

                cnt = cnt+1;

            end

        end

    end

    app.TextMessage('Finished ... ');
    app.EstimatedRegTimeViewField.Value = 'Finished ...';

end

% Renormalize
imagesIn = 32767*imagesIn/max(imagesIn(:));

app.images = imagesIn;


end