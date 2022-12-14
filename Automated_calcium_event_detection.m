%{
This cade requires following codes
        saveastiff.m (https://www.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack)
        Image Processing Toolbox

Input:  Two CSV files that are generated by Automated_ROI_Extraction.m
Output:  Csv files including frequenceis, # of calcium event, fractions of synchronization between two traces, # of asynchronized events.

%}

function A = Automated_calcium_event_detection()
% parameter
lim_frame = 9144;  % limitation of frames.     5.08Hz x 9144frames = 30min;  5.08Hz x 13716frames = 45min
fs = 5.08;         % Sampling rate of calcium imaging. 0.197sec/frame.
fpass = 1/(fs/2);  % Frequency of lowpass filter.  Components with 0.5sec or less are artifact. Note:Duration of jRGECO1a by an action potential is 0.5sec. 
lowpass_flag =1;   % if the vale is 1, this code use lowpass filter
artifact_weight = 2; % default is 2. For calculating threshold[Artifact_weight * abs(F0 - 0.1th_percentile)]. 0.1th_percentile vale represents animal motion artifact.
artifact_percentile = 0.1; % default is 0.1 (0.1th percentile). For calculating threshold. 
Upper_cross = 3;   % default is 3 (Std = 3). The second threshold. This is a threshold for the upper state of binary data
lower_cross = (Upper_cross/0.8)*0.2; % Lower state is defined as less than "lower_cross". The threshold of lower state is relatively calculated from the threshold of upper state. 
total_time = lim_frame / (fs * 60); %  total_time [min]
duration_frame = fs/2;    % When the step size is less than 0.39sec, this code ignores the step as an artifact. Durations of jRGECO1a and GCaMP6s are 0.5sec and 1 sec, respectively. 
artifact_frame = 30;    % In the SC, calcium events never happen in a low within 4sec. When frame number between 2 steps is less than "artifact_frame", these steps are originated from a single calcium event (single event is detected as two or more events by animal motion artifact).  
overlap_frame = duration_frame;  %  A spike of trace_1 is synchronized with a spike of trace_2 when overlapped frame number is more than "overlap_frame".

plot_size = 100;    
plot_edge = 1.5;   

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1st trace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%open 1st trace 
[csv_file_name, csv_path, csv_index] = uigetfile({  '*.csv','CSV (*.csv)'}, 'Select one CSV file of single axon firing.');
if isequal(csv_file_name,0) | isequal(csv_path,0)
    disp('User pressed cancel')
    A = [];
    return
end

try
    T = readtable([csv_path, csv_file_name],'ReadVariableNames',false);
catch
    disp('cant open CSV file!')
end
    
Trace_1 = T{1:lim_frame,1}';

if size(Trace_1) < lim_frame
    disp('frame number is too small!')
    return 
end

if lowpass_flag == true
    Trace_1 = lowpass(Trace_1,fpass,fs);
end

%remove artifacts
artifact_size = prctile(Trace_1,artifact_percentile);
artifact_size = artifact_weight * abs(mean(Trace_1) - artifact_size);
meant =  mean(Trace_1);

for cc = 1:length(Trace_1)
    if Trace_1(1,cc) < (meant + artifact_size)
        Trace_1(1,cc) =meant;
    elseif Trace_1(1,cc) > (meant + artifact_size)
        Trace_1(1,cc) =Trace_1(1,cc) - artifact_size;
    end
end
        
Trace_1 = zscore(Trace_1);
Logical_Trace_1 = Trace_1 > Upper_cross;

%detecting calcium events
time_stamp_1 = [];    
step_num_1 =0;      
step_Length =  artifact_frame;  
step = false;  
for counter = 1:lim_frame
    if Logical_Trace_1(1,counter) == true & step == false
        if step_Length < artifact_frame  
            step = true;
            if step_num_1 > 0
                step_Length = step_Length + (counter - time_stamp_1(1,step_num_1) )*2;
            end
            if step_Length < 200
                Logical_Trace_1((counter-step_Length):counter) = true;
                if step_num_1 > 0
                    step_num_1 = step_num_1 - 1;
                end
                step_Length = step_Length + 1;
            else
                step_Length = step_Length - (counter - time_stamp_1(1,step_num_1) )*2;
                Logical_Trace_1((counter-step_Length):counter) = true;
                step_Length = step_Length + 1;
            end
        else
            step = true;
            step_Length = 1;
        end
    elseif Logical_Trace_1(1,counter) == true & step == true
        step_Length = step_Length + 1;
    elseif Logical_Trace_1(1,counter) == false & step == true & Trace_1(1,counter) > lower_cross  % not lower state yet
        Logical_Trace_1(1,counter) = true;
        step_Length = step_Length + 1;
    elseif Logical_Trace_1(1,counter) == false & step == true & Trace_1(1,counter) < lower_cross  % lower state
        
        if step_Length > duration_frame
            step_num_1 = step_num_1 + 1;
            time_stamp_1(1,step_num_1) = round(counter - step_Length/2); 
            time_stamp_1(2,step_num_1) = max(Trace_1((counter-step_Length):counter));
            step_Length = 1;
            step = false;        
        else
            Logical_Trace_1((counter-step_Length):counter) = false;
            step_Length = duration_frame;
            step = false;
        end

    else
        step_Length = step_Length + 1;    
    end
end
          
   

% draw trace
traceWindow_1 = figure; 
traceWindow_1.Name = csv_file_name(1:end-4);
figure(traceWindow_1);

plot(1:lim_frame, Trace_1,'g','LineWidth',0.5);
hold on
plot(1:lim_frame, Logical_Trace_1,'k','LineWidth',2);
hold on
if length(time_stamp_1) > 0
    scatter(time_stamp_1(1,:),time_stamp_1(2,:)+0.2,plot_size,'*',...
        'MarkerEdgeColor', 'k'); 
end



%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2nd trace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%open the 2nd trace
[csv_file_name2, csv_path, csv_index] = uigetfile({  '*.csv','CSV (*.csv)'}, 'Select one CSV file of single axon firing.');
if isequal(csv_file_name2,0) | isequal(csv_path,0)
    disp('User pressed cancel')
    A = [];
    return
end

try
    T = readtable([csv_path, csv_file_name2],'ReadVariableNames',false);
catch
    disp('cant open CSV file!')
end
    
Trace_2 = T{1:lim_frame,1}';

if size(Trace_2) < lim_frame
    disp('frame number is too small!')
    return 
end

if lowpass_flag == true
    Trace_2 = lowpass(Trace_2,fpass,fs);
end

artifact_size = prctile(Trace_2,artifact_percentile);
artifact_size = artifact_weight * abs(mean(Trace_2) - artifact_size);
meant =  mean(Trace_2);
for cc = 1:length(Trace_2)
    if Trace_2(1,cc) < (meant + artifact_size)
        Trace_2(1,cc) =meant;
    elseif Trace_2(1,cc) > (meant + artifact_size)
        Trace_2(1,cc) =Trace_2(1,cc) - artifact_size;
    end
end
        
Trace_2 = zscore(Trace_2);
Logical_Trace_2 = Trace_2 > Upper_cross;

time_stamp_2 = []; 
step_num_2 =0;       
step_Length =  artifact_frame;  
step = false;  
for counter = 1:lim_frame
    if Logical_Trace_2(1,counter) == true & step == false
        if step_Length < artifact_frame  
            step = true;
            if step_num_2 > 0
                step_Length = step_Length + (counter - time_stamp_2(1,step_num_2) )*2;
            end
            if step_Length < 200
                Logical_Trace_2((counter-step_Length):counter) = true;
                if step_num_2 > 0
                    step_num_2 = step_num_2 - 1;
                end
                step_Length = step_Length + 1;
            else
                step_Length = step_Length - (counter - time_stamp_2(1,step_num_2) )*2;
                Logical_Trace_2((counter-step_Length):counter) = true;
                step_Length = step_Length + 1;
            end
        else
            step = true;
            step_Length = 1;
        end
    elseif Logical_Trace_2(1,counter) == true & step == true
        step_Length = step_Length + 1;
    elseif Logical_Trace_2(1,counter) == false & step == true & Trace_2(1,counter) > lower_cross  % not lower state yet
        Logical_Trace_2(1,counter) = true;
        step_Length = step_Length + 1;
    elseif Logical_Trace_2(1,counter) == false & step == true & Trace_2(1,counter) < lower_cross  % lower state
        if step_Length > duration_frame
            step_num_2 = step_num_2 + 1;
            time_stamp_2(1,step_num_2) = round(counter - step_Length/2); 
            time_stamp_2(2,step_num_2) = max(Trace_2((counter-step_Length):counter));
            step_Length = 1;
            step = false;
        else
            Logical_Trace_2((counter-step_Length):counter) = false;
            step_Length = duration_frame;
            step = false;
        end

    else
        step_Length = step_Length + 1;    
    end
end

  
% draw trace
traceWindow_2 = figure; 
traceWindow_2.Name = csv_file_name2(1:end-4);
figure(traceWindow_2);

plot(1:lim_frame, Trace_2,'m','LineWidth',0.5);
hold on
plot(1:lim_frame, Logical_Trace_2,'k','LineWidth',2);
hold on

if length(time_stamp_2) > 0
    scatter(time_stamp_2(1,:),time_stamp_2(2,:)+0.2,plot_size,'*',...
        'MarkerEdgeColor', 'k'); 
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comparison between trace1 and trace2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Logical_Trace_3 = Logical_Trace_1 & Logical_Trace_2;

time_stamp_3 = [];  
step_num_3 =0;       
step_Length = 0;  
step = false;  
for counter = 1:lim_frame
    if Logical_Trace_3(1,counter) == true & step == false
        step = true;
        step_Length = step_Length + 1;
    elseif Logical_Trace_3(1,counter) == true & step == true
        step_Length = step_Length + 1;
    elseif Logical_Trace_3(1,counter) == false & step == true
        if step_Length > overlap_frame
            step_num_3 = step_num_3 + 1;
            time_stamp_3(1,step_num_3) = round(counter - step_Length/2);
            time_stamp_3(2,step_num_3) = max(Trace_1((counter-step_Length):counter));
            if time_stamp_3(2,step_num_3) < max(Trace_2((counter-step_Length):counter))
                time_stamp_3(2,step_num_3) = max(Trace_2((counter-step_Length):counter));
            end
        end
        step_Length = 0;
        step = false; 
    end
end


% draw trace 
traceWindow_3 = figure; 
traceWindow_3.Name = 'Synchronized firing';
figure(traceWindow_3);

plot(1:lim_frame, Trace_1,'g','LineWidth',0.5);
hold on
plot(1:lim_frame, Trace_2,'m','LineWidth',0.5);
hold on

plot(1:lim_frame, Logical_Trace_3,'k','LineWidth',2);
hold on

if length(time_stamp_3) > 0
    scatter(time_stamp_3(1,:),time_stamp_3(2,:)+0.2,plot_size,'*',...
        'MarkerEdgeColor', 'k'); 
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SS = Summary_Structure  
SS = struct('file_name',csv_file_name,...
    'Number_of_firing',step_num_1,...                     
    'Frequency_per_min',step_num_1/total_time,...
    'Number_of_asynchronized_firing', step_num_1 - step_num_3,...
    'Synchronized_ratio',step_num_3/step_num_1,...
    'ASynchronized_ratio', (step_num_1 - step_num_3)/step_num_1 );

SS(2).file_name = csv_file_name2;
SS(2).Number_of_firing = step_num_2;
SS(2).Frequency_per_min = step_num_2/total_time;
SS(2).Number_of_asynchronized_firing = step_num_2 - step_num_3;
SS(2).Synchronized_ratio = step_num_3/step_num_2;
SS(2).ASynchronized_ratio = (step_num_2 - step_num_3)/step_num_2;

SS(3).file_name = 'synchronized firing';
SS(3).Number_of_firing = step_num_1 + step_num_2 - step_num_3;
SS(3).Frequency_per_min = (step_num_1 + step_num_2 - step_num_3)/total_time;
SS(3).Number_of_asynchronized_firing = step_num_1 + step_num_2 - (2 * step_num_3);
SS(3).Synchronized_ratio = step_num_3/(step_num_1 + step_num_2 - step_num_3);
SS(3).ASynchronized_ratio = step_num_1 + step_num_2 - (2 * step_num_3)/(step_num_1 + step_num_2 - step_num_3);

T = struct2table(SS);
writetable(T,['Firing_',csv_file_name(1:end-4),'_AND_',csv_file_name2(1:end-4),'.csv']);
     
saveas(traceWindow_1,[csv_file_name(1:end-4),'.png']);
saveas(traceWindow_2,[csv_file_name2(1:end-4),'.png']);
saveas(traceWindow_3,['1_',csv_file_name(1:end-4),'_AND_2_',csv_file_name2(1:end-4),'.png']);

A = 1; % success
end