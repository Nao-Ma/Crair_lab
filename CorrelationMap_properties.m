%{
Required files are as following
    Image Processing Toolbox 
    Statistics and Machine Learning Toolbox

input:   corrM.csv files generated by SeedBasedCorrelationMap.m
output:  A csv file

%}


function A = CorrelationMap_properties()
% parameters you need to change
z_value = 4;        % z score (default is 4sd).  z = 4 for one-photon imaing, z=2 for 2p imaging
CorrM_width = 500;  % 512x500 for one-photon imaging, 512x512 for 2p imaging
CorrM_height = 512;
line_size = 2;
Draw_ellipse = 0;   % Flag. Put 1 if you want to show its ellipse on the correlation map.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for cur_num = 1:num_opened_file
        A = [];
         try
            HM = readtable([cv_path, cv_file_name{cur_num}]);
         catch
             disp('cant open CSV file!')
             A = [];
             return
         end
         
         HM_length = length(HM{:,1});
       
         if HM_length > 1000
             disp('image size is too big')
             A =[];
             return
         end
        
         A = HM{:,:};
         A = fillmissing(A,'constant',0); % For NaN 
 
         % Showing a window for the correlation map.   
         hmWindow = figure;   
         imshow(A);   
         colormap jet;    
         hold on;
   

         ttt = figure;   %temporary data for drawing the contour
         figure(ttt);
         A = reshape(A, 1, CorrM_width * CorrM_height);
         A = zscore(A);
         A = reshape(A, CorrM_height, CorrM_width);
         v = [z_value,z_value];
         
         
         [M,c] = contour(A,v);
         c.LineWidth = 1; 
         c.LineColor = 'b';  
   
         figure(hmWindow);
 
   %Search the biggest ROI and Create its Mask
   poly_num = 0;
   max_poly_num = 0;
   max_poly_ROI = [];
   
   for edge = 1:length(M)
       if poly_num == 0
          poly_num = M( 2 , edge);        
          if max_poly_num < poly_num
              max_poly_num = poly_num;
              for count = 1:poly_num
                  max_poly_ROI(1, count) = M(1, edge+count);
                  max_poly_ROI(2, count) = M(2, edge+count);
              end
          end
       else
           poly_num = poly_num - 1;
       end     
   end
   
   bw = poly2mask(max_poly_ROI(1,:),max_poly_ROI(2,:),CorrM_height, CorrM_width);
   s = regionprops(bw,A,{'area',...
       'MajorAxisLength',...    % ellipse major axis
       'MinorAxisLength',...    % ellipse minor axis
       'Centroid',...
       'Circularity',...
       'Orientation'} );         % ellipse angle
   
   %drawing boundary of the biggest ROI
   plot(max_poly_ROI(1,:),max_poly_ROI(2,:),'w','LineWidth',line_size);
   
    %For contour width and height  
   c_width_max = max(max_poly_ROI(1,:));
   c_width_min = min(max_poly_ROI(1,:));
   cROI_width = c_width_max - c_width_min;
   c_height_max = max(max_poly_ROI(2,:));
   c_height_min = min(max_poly_ROI(2,:));
   cROI_height = c_height_max - c_height_min;
   cRatio_width2Height = cROI_width / cROI_height;
   
   
   %Ellipse drawing
   t = linspace(0,2*pi,50);
   a = s.MajorAxisLength/2;
   b = s.MinorAxisLength/2;
   Xc = s.Centroid(1);
   Yc = s.Centroid(2);
   phi = deg2rad(-s.Orientation);
   x = Xc + a*cos(t)*cos(phi) - b*sin(t)*sin(phi);
   y = Yc + a*cos(t)*sin(phi) + b*sin(t)*cos(phi);
   if Draw_ellipse == 1
       plot(x,y,'r','Linewidth',line_size);
   end
    
   %For ellipse width and height  
   ellip_width_max = max(x);
   ellip_width_min = min(x);
   eROI_width = ellip_width_max - ellip_width_min;
   ellip_height_max = max(y);
   ellip_height_min = min(y);
   eROI_height = ellip_height_max - ellip_height_min;
   eRatio_width2Height = eROI_width / eROI_height;
   
   eRatio_ellipseMajor2Minor = s.MajorAxisLength / s.MinorAxisLength;

   % SS = Summary_Structure 
   if cur_num == 1
  
       SS = struct('File_Name', cv_file_name{cur_num},...
       'ROI_area',s.Area,...
       'ellipse_angle',abs(s.Orientation),...
       'contour_Width',cROI_width,...
       'contour_Height',cROI_height,...
       'Ratio_contourWidth2Height',cRatio_width2Height,...
       'major_ellipse',s.MajorAxisLength,...
       'ellipse_width',eROI_width,...
       'minor_ellipse', s.MinorAxisLength,...
       'ellipse_height',eROI_height,...
       'Ratio_ellipseMajor2Minor', eRatio_ellipseMajor2Minor,...
       'Ratio_ellipsewidth2Height',eRatio_width2Height);
   else
       SS(cur_num).File_Name = cv_file_name{cur_num};
       SS(cur_num).ROI_area = s.Area;
       SS(cur_num).ellipse_angle = abs(s.Orientation);
       SS(cur_num).contour_Width = cROI_width;
       SS(cur_num).contour_Height = cROI_height;
       SS(cur_num).Ratio_contourWidth2Height = cRatio_width2Height;
       SS(cur_num).major_ellipse = s.MajorAxisLength;
       SS(cur_num).ellipse_width = eROI_width;  
       SS(cur_num).minor_ellipse = s.MinorAxisLength; 
       SS(cur_num).ellipse_height = eROI_height; 
       SS(cur_num).Ratio_ellipseMajor2Minor = eRatio_ellipseMajor2Minor;
       SS(cur_num).Ratio_ellipsewidth2Height = eRatio_width2Height;
   end
end
    
   T = struct2table(SS);
   writetable(T,'Summary_correlationMap_properties.csv'); 
   
   
   A=1;
    
end