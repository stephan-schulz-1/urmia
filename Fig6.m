
%Created with R2019b

clear all
close all

%__________________________________________________________________________
%INPUT:

filepath_ref = 'table/Evaporation_experiment.xlsx';

filepath_lake_level = 'table/Lake_level_monthly.xlsx';

filepath_bathimetry = 'raster/Bathimetry.tif';

time_steps = 7;

%Salhotra (1987), Dead Sea water:
alpha_s = [0 1 ; 5.4 1 ; 20 0.87 ; 23.3 0.79];

%Karbassi (2010):
salinity_k = [1273.8 28.0 ; 1276.1 22.8 ; 1276 23.0 ; 1277.8 16.6 ; 1273.6 29.2 ; 1273.7 29.0 ; 1272.1 34.0];

font_size = 11;

%__________________________________________________________________________
%PROCESS DATA:

bathimetry = imread(filepath_bathimetry);

lake_level = xlsread(filepath_lake_level);

data = xlsread(filepath_ref);

data(:,3:10) = data(:,3:10)-data(:,2);

salt = data(:,1).*data(:,3);

evap_mat = [];
for i = 1:time_steps
    
    conc = salt./((data(:,i+2)+data(:,i+3))./2);
    evap = data(:,i+2)-data(:,i+3);
    rel_evap = evap./evap(1);
    
    evap_mat = [evap_mat ; conc evap rel_evap];
   
end

%__________________________________________________________________________
%:VOLUME-AREA RELATIONSHIP:

min_level = min(lake_level(:,3));
max_level = max(lake_level(:,3));

all_level = [salinity_k(:,1) ; min_level ; max_level];

%calculate area:
ar = [];
for i = 1:length(all_level)   
    n_cells = sum(bathimetry<=all_level(i) & bathimetry>1000);
    n_cells = sum(n_cells);
    a = n_cells*900/1000000;
    ar = [ar ; a];        
end

%calculate volume:
volume = [];
for i = 1:length(all_level)    
    rel_cells = bathimetry(bathimetry<=all_level(i) & bathimetry>1000);
    mean_depth = all_level(i) - mean(rel_cells);
    v = mean_depth * ar(i);
    v = v/1000;
    volume = [volume ; v]; 
end

volume_salinity = [volume(1:end-2) salinity_k(:,2)];

min_volume = volume(end-1);
max_volume = volume(end);

%__________________________________________________________________________
%SALINITY MODEL:

[coeff_salinity,S_s] = polyfit(volume_salinity(:,1),volume_salinity(:,2),1);
model_salinity = [min_volume min_volume*coeff_salinity(1)+coeff_salinity(2) ; max_volume max_volume*coeff_salinity(1)+coeff_salinity(2)];

R2_S = 1 - (S_s.normr/norm(volume_salinity(:,2) - mean(volume_salinity(:,2))))^2;

%__________________________________________________________________________
%EVAPORATION MODEL:

model_part_1 = [0 1 ; 15 1];

evap_part_2 = evap_mat(evap_mat(:,1)>15 & evap_mat(:,1)<38,:);
[coeff_evap,S_e] = polyfit(evap_part_2(:,1),evap_part_2(:,3),1);
model_part_2 = [10 10*coeff_evap(1)+coeff_evap(2) ; 38 38*coeff_evap(1)+coeff_evap(2)];

model_relevant = [max_volume*coeff_salinity(1)+coeff_salinity(2) ...
    (max_volume*coeff_salinity(1)+coeff_salinity(2))*coeff_evap(1)+coeff_evap(2) ; 38 38*coeff_evap(1)+coeff_evap(2)];

R2_E = 1 - (S_e.normr/norm(evap_part_2(:,3) - mean(evap_part_2(:,3))))^2;

%__________________________________________________________________________
%PLOT:

fig1 = figure(1);
set(fig1,'Position',[100 300 1100 400],'Color',[0.95 0.95 0.95],'InvertHardcopy','off');

%left figure (salt conc lake):
axesPosition = [50 50 475 325];

ax1 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[0 40],'YLim',[10 40],'XTick',[min_volume 10 20 30 round(max_volume,1)],'XTickLabel',...
    [round(min_volume,1) 10 20 30 round(max_volume,1)],'YTick',[10 max_volume*coeff_salinity(1)+coeff_salinity(2) ...
    20 30 min_volume*coeff_salinity(1)+coeff_salinity(2) 40],'YTickLabel',[10 round(max_volume*coeff_salinity(1)+coeff_salinity(2),1) ...
    20 30 round(min_volume*coeff_salinity(1)+coeff_salinity(2),1) 40],'FontSize',font_size,'NextPlot','add','Box','on');

hold on

pa11 = patch(ax1,[min_volume min_volume max_volume max_volume],...
    [10 min_volume*coeff_salinity(1)+coeff_salinity(2) max_volume*coeff_salinity(1)+coeff_salinity(2) 10],[0 0 0]);
set(pa11,'EdgeColor','None');
set(pa11,'FaceAlpha',0.1)

pa12 = patch(ax1,[0 0 min_volume max_volume],[max_volume*coeff_salinity(1)+coeff_salinity(2) min_volume*coeff_salinity(1)+coeff_salinity(2) ...
    min_volume*coeff_salinity(1)+coeff_salinity(2) max_volume*coeff_salinity(1)+coeff_salinity(2)],[0 0 0]);
set(pa12,'EdgeColor','None');
set(pa12,'FaceAlpha',0.1)

p11 = plot(ax1,volume_salinity(:,1),volume_salinity(:,2));
set(p11,'LineStyle','None','Marker','o','MarkerEdgeColor',[0 0 0],'LineWidth',1,'MarkerFaceColor',[0.7 0.7 0.7],'MarkerSize',10);

p12 = plot(ax1,model_salinity(:,1),model_salinity(:,2));
set(p12,'LineStyle','--','Color',[1 0 0],'LineWidth',2);

hold off

%legend
leg_1 = legend([p11 p12],'Observed values (Karbassi et al., 2010)','Linear regression model',...
	'Location',[0.292 0.79 0.14 0.12]); 
set(leg_1,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');

%right figure (evap model):
axesPosition = [575 50 475 325];

ax2 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[0 55],'YLim',[0.6 1.2],'XTick',[0 10 max_volume*coeff_salinity(1)+coeff_salinity(2) 20 30 ...
    min_volume*coeff_salinity(1)+coeff_salinity(2) 38 50],'XTickLabel',{0 10 round(max_volume*coeff_salinity(1)+coeff_salinity(2),1) ...
    20 30 [num2str(round(min_volume*coeff_salinity(1)+coeff_salinity(2),1)),'   '] '   38' 50},'YTick',[0.6 0.7 0.8 0.9 1 1.1 1.2],...
    'FontSize',font_size,'NextPlot','add','Box','on');

hold on

pa1 = patch(ax2,[max_volume*coeff_salinity(1)+coeff_salinity(2) max_volume*coeff_salinity(1)+coeff_salinity(2) ...
    min_volume*coeff_salinity(1)+coeff_salinity(2) min_volume*coeff_salinity(1)+coeff_salinity(2)],...
    [0.6 1.2 1.2 0.6],[0 0 0]);
set(pa1,'EdgeColor','None');
set(pa1,'FaceAlpha',0.1);

p1 = plot(ax2,evap_mat(:,1),evap_mat(:,3));
set(p1,'LineStyle','None','Marker','o','MarkerEdgeColor',[0 0 0],'LineWidth',1,'MarkerFaceColor',[0.7 0.7 0.7],'MarkerSize',10);

p4 = plot(ax2,alpha_s(:,1),alpha_s(:,2));
set(p4,'LineStyle','None','Marker','o','MarkerEdgeColor',[0 0 0],'LineWidth',1,'MarkerFaceColor',[0.3 0.8 0.3],'MarkerSize',10);

p2 = plot(ax2,model_part_1(:,1),model_part_1(:,2));
set(p2,'LineStyle','-','Color',[0 0 0],'LineWidth',1);

p3 = plot(ax2,model_part_2(:,1),model_part_2(:,2));
set(p3,'LineStyle','-','Color',[0 0 0],'LineWidth',1);

p5 = plot(ax2,model_relevant(:,1),model_relevant(:,2));
set(p5,'LineStyle','--','Color',[1 0 0],'LineWidth',2);

p6 = plot(ax2,[38 38],[0.6 1.2]);
set(p6,'LineStyle','--','Color',[0 0 0],'LineWidth',1);

hold off

%legend
leg_2 = legend([p1 p4 p5],'Evaporation experiment (this study)','Observed values (Salhotra et al., 1987)','Linear regression model',...
	'Location',[0.565 0.76 0.14 0.15]); 
set(leg_2,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');

set(get(ax1,'ylabel'),'String','Salinity [%]','Color',[0 0 0],'FontSize',font_size);
set(get(ax1,'xlabel'),'String','Lake volume [km^3]','Color',[0 0 0],'FontSize',font_size);
set(get(ax2,'ylabel'),'String','\alpha','Color',[0 0 0],'FontSize',font_size,'FontWeight','bold');
set(get(ax2,'xlabel'),'String','Salinity [%]','Color',[0 0 0],'FontSize',font_size);

annotation('doublearrow',[0.061 0.44],[0.15 0.15],'Linewidth',1);
text(ax1,10.5,12.1,'Range of observed monthly lake volumes','FontSize',font_size);

annotation('doublearrow',[0.638 0.82],[0.15 0.15],'Linewidth',1);
text(ax2,17,0.64,'Range of expectable salinities','FontSize',font_size);

t1 = text(ax1,18,28,['Salinity [%] = ',sprintf('%.2f',coeff_salinity(1)),' \cdot Lake volume [km^3] + ',...
    sprintf('%.1f',coeff_salinity(2))]);
set(t1,'Color',[1 0 0],'FontSize',font_size);

t2 = text(ax1,32.9,26,['(R^2 = ',sprintf('%.2f',R2_S),')']);
set(t2,'Color',[1 0 0],'FontSize',font_size);

t3 = text(ax2,2,0.82,['\alpha = ',sprintf('%.3f',coeff_evap(1)),' \cdot Salinity [%] + ',...
    sprintf('%.2f',coeff_evap(2))]);
set(t3,'Color',[1 0 0],'FontSize',font_size);

t4 = text(ax2,13.5,0.785,['(R^2 = ',sprintf('%.2f',R2_E),')']);
set(t4,'Color',[1 0 0],'FontSize',font_size);

t5 = text(ax2,39,0.64,'Saturation');
set(t5,'Color',[0 0 0],'FontSize',font_size,'Rotation',90);

text(ax1,0.5,39,'a','FontSize',14,'FontWeight','bold');
text(ax2,53,1.175,'b','FontSize',14,'FontWeight','bold');




