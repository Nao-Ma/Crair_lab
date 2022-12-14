%{
This code requires following codes
        CSV_Extraction.m
        saveastiff.m (https://www.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack)
        imread_big.m   (https://www.mathworks.com/matlabcentral/fileexchange/61376-imread_big-read-in-tiff-stacks-larger-than-4gb)
        Image Processing Toolbox

input #1: A CSV file generated by Simple Neurite Tracer (SNT) ImageJ/plugin. The file has data for branch terminal positions of single RGC axon.
input #2: Preprocessed movie (512x512, 8bit, tif file). 

output #1: Tif files of ROI mask.
output #2: csv files of calcium signals at the ROIs.

%}


function A = Automated_ROI_Extraction()
%%%%%%%%%%%%%%%%%%%%%%%
% parameters
%%%%%%%%%%%%%%%%%%%%%%%

center_percentile_value = 5; % 5th percentile or less are central regions
distal_percentile_value = 95; % 95th percentil or more are distal regions

ROI_radius = 10;     % size of ROI radius [pix]  def=10  0.79um/pix for zoom x2.

%% open branch terminal data file

% Extracting branch position data by CSV_EXtraction.m
% A     (n,6)matrix. [1 type, 2 x_position, 3 y_position, 4 end_x_position, 5 end_y_position, 6 PathLength]
A = CSV_Extraction();
if isequal(A,[])
    disp('Can not open the file')
    return
end

x = A(:,2);
y = A(:,3);
data = [x,y];
% Plot the original data
I = uint8(zeros(512,512));
imshow(I)
hold on
plot(data(:,1), data(:,2), '.');
hold on
axis equal

%% Calculation of distances from the center
xMean = mean(A(:,2));
yMean = mean(A(:,3));

cx = x - xMean;
cy = y - yMean;

distance = hypot(cy,cx);
percentile_center = prctile(distance,center_percentile_value);
percentile_distal = prctile(distance,distal_percentile_value);

%data = cat(2,data,distance);
data_c =[];
data_d =[];
num_c = 0;
num_d = 0;

for branch = 1:length(distance)
    if distance(branch) < percentile_center
        num_c = num_c +1;         
        data_c(num_c,:) = data(branch,:);
    elseif distance(branch) > percentile_distal
        num_d = num_d +1;         
        data_d(num_d,:) = data(branch,:);
    end
end


%% central ROI

plotROIWindow = figure;  
figure(plotROIWindow);
I = uint8(zeros(512,512));
radius = [];
radius(1:[length(data_c)],1) = ROI_radius;
data_c = cat(2,data_c,radius);
RGB = insertShape(I,'FilledCircle',data_c,'Color', 'white');
cBW = imbinarize(RGB(:,:,3)); % default threthold is "Otsu method".
imshow(cBW)
axis equal


%% distal ROI

plotROIWindow = figure;  
figure(plotROIWindow);
I = uint8(zeros(512,512));
radius = [];
radius(1:[length(data_d)],1) = ROI_radius;
data_d = cat(2,data_d,radius);
RGB = insertShape(I,'FilledCircle',data_d,'Color', 'white');
dBW = imbinarize(RGB(:,:,3)); % default threthold is "Otsu".
imshow(dBW)
axis equal


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  %Open a movie (.tif)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[tif_file_name, tif_path, tif_index] = uigetfile({  '*.tif','TIF (*.tif)'}, 'Select one tif file of 2p imaging.');
if isequal(tif_file_name,0) | isequal(tif_path,0)
    disp('User pressed cancel')
    A = [];
    return
end

disp('tif loading')
tic
A = imread_big([tif_path, tif_file_name]);
toc

movie_size = size(A);
movie_WbyH = movie_size(1)*movie_size(2);

if ~(size(I) == movie_size(1:2))
    disp('mismatch between movie size and plot ROI. Please check the width and height of the movie')
    retun
end

A = reshape(A, movie_WbyH, movie_size(3)); %reshape 3D array into space-time matrix             


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create Mask for central regions
%%%%%%%%%%%%%%%%%%%%%%%%%%

mask = cBW;
%mask_id = (n, 1) double  
mask_id = find(mask > 0);
A_filtered = A(mask_id, :); 
A_filtered = uint8(A_filtered);

% trace
traceWindow = figure; 
traceWindow.Name = 'Center trace';
figure(traceWindow);

Trace_center = mean(A_filtered);


plot(1:movie_size(3), Trace_center)
writematrix(Trace_center',[tif_file_name(1:end-4),'_center_trace.csv']);

mask = im2uint8(mask);
options.big = false;
saveastiff(mask,[tif_file_name(1:end-4),'_center_mask.tif'] , options);


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create Mask for distal regions
%%%%%%%%%%%%%%%%%%%%%%%%%%

mask = dBW;
%mask_id = (n, 1) double   
mask_id = find(mask > 0);
A_filtered = A(mask_id, :); 
A_filtered = uint8(A_filtered);


% trace
traceWindow = figure; 
traceWindow.Name = 'distal trace';
figure(traceWindow);

Trace_distal = mean(A_filtered);

plot(1:movie_size(3), Trace_distal)
writematrix(Trace_distal',[tif_file_name(1:end-4),'_distal_trace.csv']);

mask = im2uint8(mask);
options.big = false;
saveastiff(mask,[tif_file_name(1:end-4),'_distal_mask.tif'] , options);



A = 1; % success
end
