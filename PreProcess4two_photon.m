
%{
Required files are as following
    Image Processing Toolbox 
    Parallel Computing Toolbox (if you will not use, just change "parfor" >> "for")
    saveastiff.m (https://www.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack)
    imread_big.m   (https://www.mathworks.com/matlabcentral/fileexchange/61376-imread_big-read-in-tiff-stacks-larger-than-4gb)
 
Required machine spec
    RAM = more than 128Gbyte

input:   8bit.tif file (512pix x 512pix x 28000frames). Detail is as follows:
         After corrected for motion artifact using Suite2p, 
         16bit files were converted to 8bit tif file, which in turn smoothed with a Gaussian filter (σ = 2).
         
output:  32bit.tif file. Note, keep the file size less than 4Gbyte if you want to open the file on ImageJ. 
         When you open the file with 4Gbyte or more on imageJ, frame number would be something wrong (added 9 frames on ImageJ because of the header of tiff file). 


%}

function XX = PreProcess4two_photon()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%set parameter
hat = 50; % top-hat filtering across time for 5.08 Hz
downSampleRatio = 1; % not using downsampling when the vale is 1.  0.25 = 128pix x 128 pix.  0.125 = 64pix x 64 pix.
percentile10th_flag = 1; % default = 1. whether 10th percentile baseline is used (=1) or not (=0).
number_save_file = 10;  % Number of output files. Divid output files so as to the file sizes is less than 4 Gbyte, otherwise, you can not open the files on imageJ.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

XX = 1;
A=[];

%Open a movie (.tif)
[tif_file_name, tif_path, tif_index] = uigetfile({  '*.tif','TIF (*.tif)'}, 'Select a 8bit tif file of 2p imaging.');
if isequal(tif_file_name,0) | isequal(tif_path,0)
    disp('User pressed cancel')
    A = [];
    return
end

% tif load
disp('tif loading')
tic
A = imread_big([tif_path, tif_file_name]);
toc

movie_size = size(A);
movie_WbyH = movie_size(1)*movie_size(2);
downSample_WbyH = movie_WbyH*downSampleRatio*downSampleRatio;

try
    if isequal(downSampleRatio,1)
        % if ratio is "1", not down sampling
        sA = [];
    else
        sA = imresize(A, downSampleRatio, 'bilinear');
        if downSample_WbyH ~= round(downSample_WbyH)
            disp('DownSample parameter must be 1(2^n).')
        end
        sA = reshape(sA, downSample_WbyH, movie_size(3)); %reshape 3D array into space-time matrix 
    end
catch
        disp('DownSample parameter is something wrong!')
        sA =[];
end


A = reshape(A, movie_WbyH, movie_size(3)); %reshape 3D array into space-time matrix             

se = strel('line', hat, 0);  
disp('TopHat start')
tic
if isequal(downSampleRatio,1) 
    parfor p = 1:movie_WbyH
       A_Tophat(p, :) = imtophat(A(p, :), se); 
    end
else 
    parfor p = 1:downSample_WbyH
       A_Tophat(p, :) = imtophat(sA(p, :), se);
    end
    clear sA
    A_Tophat= reshape(A_Tophat, movie_size(1)*downSampleRatio,movie_size(2)*downSampleRatio,movie_size(3)); 
    A_Tophat = imresize(A_Tophat, 1/downSampleRatio, 'bilinear'); 
    A_Tophat = reshape(A_Tophat, movie_WbyH, movie_size(3));      
end
disp('TopHat end')
toc

% (before tophat) - (after tophat)
A = A - A_Tophat;

%mean_A represents Fo 
mean_A = mean(A, 2);  % output is double(64bit)
mean_A = single(mean_A); 
A_Tophat = single(A_Tophat);
A = [];

%A = zeros(movie_size(1),movie_size(2),movie_size(3));
A = A_Tophat ./ mean_A;  %A = dF/Fo
clear A_Tophat mean_A se


% 10th percentile baseline (option)
if percentile10th_flag
    disp('calculating percentile 10th.')
    tic
    percentile10th = prctile(A',10); 
    toc
    A = A-percentile10th'; % Subtract with 10th percentile value 
end
   
   
% tif save
A= reshape(A, movie_size(1),movie_size(2),movie_size(3));
disp('Tiff Saving')
options.big = false;
if number_save_file == 1
    saveastiff(A, 'preprocessed.tif', options);
elseif number_save_file == 0
    disp('number_save_file value should be changed')
else
    blocksz = movie_size(3)./number_save_file;
    first_frame = 0;
    last_frame = 0;
    for frames = 1:number_save_file    
        first_frame = 1+blocksz*(frames-1);
        last_frame = blocksz+blocksz*(frames-1);
        saveastiff(A(:,:,first_frame:last_frame), [tif_file_name, num2str(frames),'_preprocessed.tif'], options)
    end
end

end


