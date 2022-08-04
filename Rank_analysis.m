%{
  This script requires 
    Statistics and Machine Learning Toolbox


Input: Csv files (Extraction.csv) generated by Correlation_Extraction.m
       Each file have info of coodinates, branch types, correlation coefficient values of each branches of a single RGC axon

%}


function A = Rank_analysis()

% open multiple files
[cv_file_name, cv_path, cv_index] = uigetfile({  '*.csv','csv image (*.csv)'}, 'Select one or several CSV files (using +CTRL or +SHIFT)','MultiSelect', 'on');
    if isequal(cv_file_name,0) | isequal(cv_path,0)
    disp('User pressed cancel')
    A = [];
    return
    end
    
    % num_opened_file      number of opened file
    if iscell(cv_file_name) 
        num_opened_file = length(cv_file_name);
    else
         disp('Select multiple files')
         A = [];
         return
    end
    
    All_Da =[]; % compilation of All Data 
    All_St =[]; % compilation of All Stable 
    All_Ad =[]; % compilation of All Added 
    All_El =[]; % compilation of All Eliminate 
    All_Ex =[]; % compilation of All Extend 
    All_Rt =[]; % compilation of All Retract 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for cur_num = 1:num_opened_file
        A = [];
         try
            T = readtable([cv_path, cv_file_name{cur_num}]);
         catch
             disp('cant open CSV file!')
             A = [];
             return
         end
         A = T{:,:};
       
          
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

    
    % C (Center)   C= [1 type, 2 x_position, 3 y_position, 4 distance from the center, 5 rank for distance(normalized and inverted),...
    %                  6, corelation coefficient 7, rank for correlation coefficient(normalized)] 
    C =A(:,1);
    
    %xMean, yMean       Center of a single axon arbor
    xMean = mean(A(:,2));
    yMean = mean(A(:,3));
    
    %Shift to center
    for nBranch = 1:length(A)
        C(nBranch,2) = A(nBranch,2) - xMean;
        C(nBranch,3) = A(nBranch,3) - yMean;
        C(nBranch,4) = hypot( C(nBranch,3), C(nBranch,2) );   % calculation of its distance from the center     
    end
    
    rank_Distance =[];  % temporal data 
    rank_Distance = C(:,4);
    rank_Distance = tiedrank(rank_Distance');
    rank_Distance = rank_Distance/length(A);  % normalize
    rank_Distance = 1 - rank_Distance; 
    rank_Distance = rank_Distance';
    C(:,5)= rank_Distance;
    
    C(:,6) = A(:,7);  % A(:,7) = correlation coefficient value
    rank_Correlation = []; % temporal data 
    rank_Correlation = A(:,7); 
    rank_Correlation = tiedrank(rank_Correlation');
    rank_Correlation = rank_Correlation/length(A); % normalize
    rank_Correlation = rank_Correlation';
    C(:,7) = rank_Correlation'; 
    
    %Sort by each branch types
    % t = theta from Table C
    tStable = [];
    tAdd = [];
    tElimination = [];
    tElongation = [];
    tRetraction = [];
   
    % counter
    cStable = 0;
    cAdd = 0;
    cElimination = 0;
    cElongation = 0;
    cRetraction = 0;

    %Sort for theta
    for nBranch = 1:length(C)
            switch C(nBranch, 1)
                case 1 % stable
                    cStable=cStable+1;
                    tStable(cStable,:) = C(nBranch,:);
                  
                case 2 % Add
                    cAdd=cAdd+1;
                    tAdd(cAdd,:) = C(nBranch,:);  
                   
                case 3 % Elimination
                    cElimination=cElimination+1;
                    tElimination(cElimination,:) = C(nBranch,:); 
                    
                case 4 % Elongation
                    cElongation=cElongation+1;
                    tElongation(cElongation,:) = C(nBranch,:);
                    
                case 5 % Retract
                    cRetraction=cRetraction+1;
                    tRetraction(cRetraction,:) = C(nBranch,:); 
            end
    end

     %  Compilation of data
     All_Da = vertcat(All_Da,C); % compilation of All Data 
     All_St =vertcat(All_St,tStable); % compilation of All Stable 
     All_Ad =vertcat(All_Ad,tAdd); % compilation of All Added 
     All_El =vertcat(All_El,tElimination); % compilation of All Eliminate 
     All_Ex =vertcat(All_Ex,tElongation); % compilation of All Extend 
     All_Rt =vertcat(All_Rt,tRetraction); % compilation of All Retract 
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Rank_Distance_Stable = mean(tStable(:,5));
    Rank_Correlation_Stable = mean(tStable(:,7));
    
    Rank_Distance_Add = mean(tAdd(:,5));
    Rank_Correlation_Add = mean(tAdd(:,7));
    
    Rank_Distance_Elimination = mean(tElimination(:,5));
    Rank_Correlation_Elimination = mean(tElimination(:,7));
    
    Rank_Distance_Elongation = mean(tElongation(:,5));
    Rank_Correlation_Elongation = mean(tElongation(:,7));
    
    Rank_Distance_Retraction = mean(tRetraction(:,5));
    Rank_Correlation_Retraction = mean(tRetraction(:,7));
    
   
    % SS = Summary_Structure 
    if cur_num == 1
    SS = struct( 'File_Name', cv_file_name{cur_num},...
        'Rank_Distance_Stable',Rank_Distance_Stable,...
        'Rank_Correlation_Stable',Rank_Correlation_Stable,...
        'Rank_Distance_Add',Rank_Distance_Add,...
        'Rank_Correlation_Add',Rank_Correlation_Add,...
        'Rank_Distance_Elimination',Rank_Distance_Elimination,...
        'Rank_Correlation_Elimination',Rank_Correlation_Elimination,...
        'Rank_Distance_Elongation',Rank_Distance_Elongation,...
        'Rank_Correlation_Elongation',Rank_Correlation_Elongation,...
        'Rank_Distance_Retraction',Rank_Distance_Retraction,...
        'Rank_Correlation_Retraction',Rank_Correlation_Retraction);
    else
        SS(cur_num).File_Name = cv_file_name{cur_num};
        SS(cur_num).Rank_Distance_Stable = Rank_Distance_Stable;
        SS(cur_num).Rank_Correlation_Stable = Rank_Correlation_Stable;
        SS(cur_num).Rank_Distance_Add = Rank_Distance_Add;
        SS(cur_num).Rank_Correlation_Add = Rank_Correlation_Add;
        SS(cur_num).Rank_Distance_Elimination = Rank_Distance_Elimination;
        SS(cur_num).Rank_Correlation_Elimination = Rank_Correlation_Elimination;
        SS(cur_num).Rank_Distance_Elongation = Rank_Distance_Elongation;
        SS(cur_num).Rank_Correlation_Elongation = Rank_Correlation_Elongation;
        SS(cur_num).Rank_Distance_Retraction = Rank_Distance_Retraction;
        SS(cur_num).Rank_Correlation_Retraction = Rank_Correlation_Retraction;
    end    
end

     % Save SS as CSV 
     T = struct2table(SS);
     writetable(T,'Summary_Average_for_rank.csv');
     writematrix(All_Da,'Compilation_All_data_4rank.csv'); 
     writematrix(All_St,'Compilation_Stable_data_4rank.csv');   
     writematrix(All_Ad,'Compilation_Added_data_4rank.csv');   
     writematrix(All_El,'Compilation_Eliminated_data_4rank.csv');   
     writematrix(All_Ex,'Compilation_Extended_data_4rank.csv');
     writematrix(All_Rt,'Compilation_Retracted_data_4rank.csv');   
              
end

    