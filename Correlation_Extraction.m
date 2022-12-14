%{
  The code requires
  CSV_Extraction.m

 Input1: a CSV file generated by simple neurite tracer (SNT) ImageJ/plugin. The file has info for branch positions and branch types.
 Input2: CorrM.csv generated by SeedBasedCorrelationMap.m     The file has correlation coefficient vales of seed based correlation map.

%}

function A = Correlation_Extraction()
%parameters
without_corrM = 0; % if you want to get only data of branch positions and branch type. 
plot_size = 60;    % default = 60    size of dot for making figure 
plot_edge = 2.5;   %default = 2.5    bold of edge of dot plot
%%%%%%%%%%%%%%%%%%%%%%

% Extracting branch position data by CSV_EXtraction.m
% A     (n,6)matrix. [1 type, 2 x_position, 3 y_position, 4 end_x_position, 5 end_y_position, 6 PathLength]
A = CSV_Extraction();
if isequal(A,[])
    disp('Prepare one CSV file.')
    return
end

if without_corrM == 1
    hm_file_name = 'onlydynamics.csv';
else
    
% Slecting corrM.csv generated by SeedBasedCorrelationMap.m.
[hm_file_name, hm_path, hm_index] =uigetfile({  '*.csv','CSV (*.csv)'}, 'Select a CSV file of correlation map.');
    if isequal(hm_file_name, 0) | isequal(hm_path, 0)
    disp('User pressed cancel')
    A = [];
    return
    end
end

if without_corrM == 1
    HM = uint8(zeros(512,512));
    HM = array2table(HM);
    HM_length = length(HM{:,1});
else
    try
        HM = readtable([hm_path, hm_file_name]);
    catch
        disp('can not open')
        return
    end
    
    HM_length = length(HM{:,1});
     
    if HM_length > 2000
        disp('image size is too big') 
        A =[];
        return
    end
end 
    
    
    % CV    correlation coefficient vales   [n,3]matrix   [correlation coefficient vales at start point, correlation vale at end point, subtract(start - end)]
    CV =[];
        
    for branch = 1:length(A)
        if A(branch, 2) < HM_length & A(branch,3) < HM_length & A(branch,4) < HM_length & A(branch,5) < HM_length
            CV(branch, 1) = HM{A(branch, 3), A(branch,2)};   % at 0hr.  Because of matrix data, x and y are inverted.
            CV(branch, 2) = HM{A(branch, 5), A(branch,4)};   % at 2hr.  
            CV(branch,3) = CV(branch,2)-CV(branch,1);
        else
            disp('wrong pointing!')
            A = [];
            return
        end
    end
    
    CV = fillmissing(CV,'constant',0); % removing NaN 
    
    A = [A,CV];
    
    %save as matrix(SCV file)
    % (n,4)matrix  [type, x-position, y-position, correlation_value]
    writematrix(A,['Extraction_correlation_', hm_file_name]);
    

    % Show windows for the correlation map.
    MergePlotIm = HM{:,:};
    hmWindow = figure; 
    imshow(MergePlotIm);
    colormap jet; 
    hold on;
    
    %Sorted_A    Table "A" after sorting in order of stable>add>elimi>elong>retract
    Sorted_A = sortrows(A);
   
 
    %plot heat map
    for branch = 1:length(Sorted_A)
            switch Sorted_A(branch, 1)
                case 1 % stable
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','w',...   % inside  w = white / m = magenta
                        'LineWidth',plot_edge);  
                case 2 % Add
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','g',...   % inside   'g' = green(0,255,0)  
                        'LineWidth',plot_edge);  
                case 3 % Elimination
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor',[0 0.73 1],...   % inside   cyan [0 0.73 1]
                        'LineWidth',plot_edge);  
                case 4 % Elongation
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor',[0.7 0 0],...   % inside   deep_red[0.7 0 0]
                        'LineWidth',plot_edge);  
                case 5 % Retract
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','b',...   % inside   b = bule
                        'LineWidth',plot_edge);  
            end
    end
    
    
    
    % Show windows only for plotted data. 
    PlotIm = zeros(HM_length,HM_length);
    PlotIm = PlotIm + 0.5;  % set  background color default = 0.5
    plotWindow = figure; 
    imshow(PlotIm);
    hold on;
     
    %only plot
    for branch = 1:length(Sorted_A)
            switch Sorted_A(branch, 1)
                case 1 % stable
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','w',...   % inside  w = white / m = magenta
                        'LineWidth',plot_edge);  
               
                case 4 % Elongation
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor',[0 0.73 1],...   % inside   change:  Deep red [0.7 0 0] >> cyan  [0 0.73 1]
                        'LineWidth',plot_edge);  
                case 5 % Retract
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','b',...   % inside   b = bule
                        'LineWidth',plot_edge);  
            end
    end
    
    for branch = 1:length(Sorted_A)
            switch Sorted_A(branch, 1)  
                case 2 % Add
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','g',...   % inside   g = green  
                        'LineWidth',plot_edge);  
                case 3 % Elimination
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor',[0.7 0 0],...   % inside    change: cyan  [0 0.73 1] >> Deep red [0.7 0 0]
                        'LineWidth',plot_edge);  
            end
    end
    
    
    
    % Show windows only for stable, added and eliminated positions.
    PlotIm = zeros(HM_length,HM_length);
    PlotIm = PlotIm + 0.5;  % set  background color default = 0.5
    plotWindow_SAE = figure; 
    imshow(PlotIm);
    hold on;     
  
    for branch = 1:length(Sorted_A)
            switch Sorted_A(branch, 1) 
                 case 1 % stable
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','w',...   % inside  w = white / m = magenta
                        'LineWidth',plot_edge);  
               
                case 2 % Add
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor','g',...   % inside   g = green  
                        'LineWidth',plot_edge);  
                case 3 % Elimination
                    scatter(Sorted_A(branch, 2), Sorted_A(branch,3),....
                        plot_size,...  % size 
                        'MarkerEdgeColor','k',...   % outside  k = black
                        'MarkerFaceColor',[0.7 0 0],...   % inside,    change: cyan  [0 0.73 1] >> Deep red [0.7 0 0]
                        'LineWidth',plot_edge);  
            end
    end
    
    
    
    
    %% For output quantification file
    
    % temporary matrix for sorting branches by branch_type
    Temp_stable = [];
    num_stable = 0;
    Temp_add = [];
    num_add = 0;
    Temp_elim = [];
    num_elim = 0;
    Temp_elong =[];
    num_elong = 0;
    Temp_retract = [];
    num_retract = 0;
    
    % sorting branches by branch_type
     for branch = 1:length(A)
            switch A(branch, 1)
                case 1 % stable
                   num_stable = num_stable +1;
                   Temp_stable(num_stable,:) = A(branch,:);
                case 2 % Add
                   num_add = num_add +1;
                   Temp_add(num_add,:) = A(branch,:);
                case 3 % Elimination
                   num_elim = num_elim +1;
                   Temp_elim(num_elim,:) = A(branch,:);
                case 4 % Elongation
                   num_elong = num_elong +1;
                   Temp_elong(num_elong,:) = A(branch,:);
                case 5 % Retract
                   num_retract = num_retract +1;
                   Temp_retract(num_retract,:) = A(branch,:);
            end
     end
     
  
     ave_all = mean(A);
     
     %calculation for ave_dif_all which consist add, elimina, elong,
     %retract but not stable 
     sum_for_dif = sum(A);
     div_for_dif = num_add + num_elim + num_elong +num_retract;
     ave_dif_all = sum_for_dif(1,9)/div_for_dif;
     
     
     if num_stable == 0       % for just in case there is no branch
         ave_stable = zeros(1,10);
     else
         ave_stable = mean(Temp_stable,1);
     end
     
     if num_add == 0
         ave_add = zeros(1,10);
     else
         ave_add = mean(Temp_add,1);
     end
     
     if num_elim == 0
         ave_elim = zeros(1,10);
     else
         ave_elim = mean(Temp_elim,1);
     end
     
      if num_elong == 0
         ave_elong = zeros(1,10);
     else
         ave_elong = mean(Temp_elong,1);
      end
     
      if num_retract == 0
         ave_retract = zeros(1,10);
     else
         ave_retract = mean(Temp_retract,1);
      end
         
     
    % SS = Summary_Structure  
    SS = struct('file_name',hm_file_name,...
        'num_all',length(A),...                        % number of terminal branch
        'num_stable',num_stable,...
        'num_addition',num_add,...
        'num_elimination',num_elim,...
        'num_elongation',num_elong,...
        'num_retraction',num_retract,...        
        'ave_all',ave_all(1,7),...                        % average of correlation value
        'ave_stable',ave_stable(1,7),...
        'ave_addition',ave_add(1,7),...
        'ave_elimination',ave_elim(1,7),...
        'ave_elongation',ave_elong(1,7),...
        'ave_retraction',ave_retract(1,7),...
        'ave_dif_all', ave_dif_all,...
        'ave_dif_addition',ave_add(1,9),...               % average of subtraction of correlation value (start_point - end_point) 
        'ave_dif_elimination',ave_elim(1,9),...
        'ave_dif_elongation',ave_elong(1,9),...
        'ave_dif_retraction',ave_retract(1,9));
    
    
     
     % Save SS as CSV 
     T = struct2table(SS);
     writetable(T,['Quantification_CorrelationCoefficient_', hm_file_name]);

     
    A =1; %success
            
end

           
    
        
    
    
    