%{
the cade requires following codes
    imread_big.m   (https://www.mathworks.com/matlabcentral/fileexchange/61376-imread_big-read-in-tiff-stacks-larger-than-4gb)
    Parallel Computing Toolbox (if you don't have, just change "parfor" >> "for")


Input 1:    Preprocessed movie. Note: need convert 32bit to 8 bit.
            Two-photon: 512x512x28000frames  
            One-photon: 512x500x9000frames
Input 2:    A CSV file for a seed.
            Two-photon: GCaMP6s signals in a central ROI calculated by Automated_ROI_EXtraction.m  were collected with Plot Z-Axis Profile function in ImageJ 
            One-phton:  GCaMP6s signals in ROIs of radius 20.5 um were collected with Plot Z-Axis Profile function in ImageJ
Output:     corrM.csv that is a correlation map

%}

function XX = SeedBasedCorrelationMap()
XX =1; % Just for checking error code.

%open a seed trace
[csv_file_name, csv_path, csv_index] = uigetfile({  '*.csv','CSV (*.csv)'}, 'Select a CSV file of seed trace.');
if isequal(csv_file_name,0) | isequal(csv_path,0)
    disp('User pressed cancel')
    XX = [];
    return
end

try
    T = readtable([csv_path, csv_file_name]);
catch
    disp('cant open CSV file!')
end
    
Trace = T{:,'Mean'};

%load a movie
[tif_file_name, tif_path, tif_index] = uigetfile({  '*.tif','TIF (*.tif)'}, 'Select a 8bit preprocessed movie.');
if isequal(tif_file_name,0) | isequal(tif_path,0)
    disp('User pressed cancel')
    A = [];
    return
end
disp('loading movie')
tic
A = imread_big([tif_path, tif_file_name]);
toc
A = double(A);
sz  = size(A);
sz_WbyH = sz(1)*sz(2);
imgall = reshape(A, sz_WbyH, sz(3));  % Transform movie into spacial-time matrix
clear A;
corrM = zeros(sz_WbyH,1);

if isequal(length(Trace), sz(3))
else
    disp('frame numbers between the movie and the seed trace were different!')
end

disp('generating correlation map')
tic
try
    for frame = 1:sz_WbyH
        corrM(frame,1) = corr(imgall(frame,:)',Trace);
    end
catch
    disp('calculation error!')
end
toc

corrM = reshape(corrM, sz(1),sz(2));

%Plot the new correlation matrix
hmWindow = figure; 
imshow(corrM);
colormap jet;

writematrix(corrM,'corrM.csv');
end
