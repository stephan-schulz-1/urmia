
%Created with R2019b

close all;
clear all;

%__________________________________________________________________________
%INPUT:

filepath_lake_level = 'table/Lake_level_monthly.xlsx';
filepath_lake_level_extra = 'table/Lake_level_annual.xlsx';

filepath_inflow = 'table/Inflow_monthly.xlsx';
filepath_inflow_extra = 'table/Inflow_annual.xlsx';

filepath_epot_Tabriz = 'table/Epot_monthly_Tabriz.xlsx';

filepath_precip_Tabriz = 'table/Rainfall_monthly_Tabriz.xlsx';
filepath_precip_Urmia = 'table/Rainfall_monthly_Urmia.xlsx';
filepath_precip_Sahand = 'table/Rainfall_monthly_Sahand.xlsx';
filepath_precip_Mahabad = 'table/Rainfall_monthly_Mahabad.xlsx';
filepath_precip_Miandoab = 'table/Rainfall_monthly_Miandoab.xlsx';

filepath_bathimetry = 'raster/Bathimetry.tif';

font_size = 11;

%__________________________________________________________________________
%READ DATA:

epot = xlsread(filepath_epot_Tabriz);
precip_Tabriz = xlsread(filepath_precip_Tabriz);
precip_Urmia = xlsread(filepath_precip_Urmia);
precip_Sahand = xlsread(filepath_precip_Sahand);
precip_Mahabad = xlsread(filepath_precip_Mahabad);
precip_Miandoab = xlsread(filepath_precip_Miandoab);

inflow = xlsread(filepath_inflow);
inflow_extra = xlsread(filepath_inflow_extra);

lake_level = xlsread(filepath_lake_level);
lake_level_extra = xlsread(filepath_lake_level_extra);

bathimetry = imread(filepath_bathimetry);

%create all time vector:
time_v = [];
for year = 1931:2018
    months = [10 ; 11 ; 12 ; 1 ; 2 ; 3 ; 4 ; 5 ; 6 ; 7 ; 8 ; 9];
    years = [ones(3,1).*(year-1) ; ones(9,1).*year];
    time_v = [time_v ; years months years+(months-1)./12];
end

%__________________________________________________________________________
%PRE-PROCESSING WEATHER DATA:

%interpolate precip value for Nov 1977:
precip_Tabriz(27,12) = mean(precip_Tabriz(27,11:13),'omitnan');
precip_Urmia(27,12) = mean(precip_Urmia(27,11:13),'omitnan');

%fill gap in Urmia dataset (Jan-Jun 1963) with Tabriz data:
precip_Urmia(13,2:7) = precip_Tabriz(13,2:7);

%fill gap in Miandoab dataset (Jan 2002) with Mahabad data:
precip_Miandoab(1,2) = precip_Mahabad(18,2);

%change precip format:
precip_tab = [];
for i = 1:size(precip_Tabriz,1)
    precip_tab = [precip_tab ; ones(12,1).*precip_Tabriz(i,1) transpose(1:12) transpose(precip_Tabriz(i,2:13))];
end
precip_urm = [];
for i = 1:size(precip_Urmia,1)
    precip_urm = [precip_urm ; ones(12,1).*precip_Urmia(i,1) transpose(1:12) transpose(precip_Urmia(i,2:13))];
end
precip_sah = [];
for i = 1:size(precip_Sahand,1)
    precip_sah = [precip_sah ; ones(12,1).*precip_Sahand(i,1) transpose(1:12) transpose(precip_Sahand(i,2:13))];
end
precip_mah = [];
for i = 1:size(precip_Mahabad,1)
    precip_mah = [precip_mah ; ones(12,1).*precip_Mahabad(i,1) transpose(1:12) transpose(precip_Mahabad(i,2:13))];
end
precip_mia = [];
for i = 1:size(precip_Miandoab,1)
    precip_mia = [precip_mia ; ones(12,1).*precip_Miandoab(i,1) transpose(1:12) transpose(precip_Miandoab(i,2:13))];
end

%calculate area weighted mean discharge:
tab = precip_tab(precip_tab(:,1)<1985,3).*28155;
urm = precip_urm(precip_urm(:,1)<1985,3).*23609;
mean_precip_85 = [(tab+urm)./51764];

tab = precip_tab(precip_tab(:,1)>=1985 & precip_tab(:,1)<1996,3).*16332;
urm = precip_urm(precip_urm(:,1)>=1985 & precip_urm(:,1)<1996,3).*13631;
mah = precip_mah(precip_mah(:,1)>=1985 & precip_mah(:,1)<1996,3).*21801;
mean_precip_96 = [(tab+urm+mah)./51764];

sah = precip_sah(precip_sah(:,1)>=1996 & precip_sah(:,1)<2002,3).*12102;
tab = precip_tab(precip_tab(:,1)>=1996 & precip_tab(:,1)<2002,3).*13065;
urm = precip_urm(precip_urm(:,1)>=1996 & precip_urm(:,1)<2002,3).*13173;
mah = precip_mah(precip_mah(:,1)>=1996 & precip_mah(:,1)<2002,3).*13423;
mean_precip_02 = [(sah+tab+urm+mah)./51764];

mia = precip_mia(precip_mia(:,1)>=2002 & precip_mia(:,1)<2018,3).*11911;
sah = precip_sah(precip_sah(:,1)>=2002 & precip_sah(:,1)<2018,3).*5919;
tab = precip_tab(precip_tab(:,1)>=2002 & precip_tab(:,1)<2018,3).*13065;
urm = precip_urm(precip_urm(:,1)>=2002 & precip_urm(:,1)<2018,3).*13173;
mah = precip_mah(precip_mah(:,1)>=2002 & precip_mah(:,1)<2018,3).*7696;
mean_precip_18 = [(mia+sah+tab+urm+mah)./51764];

all_mean_precip = [mean_precip_85 ; mean_precip_96 ; mean_precip_02 ; mean_precip_18];
all_mean_precip = [precip_tab(:,1:2) precip_tab(:,1)+(precip_tab(:,2)-1)./12 all_mean_precip];

%format:
precip_m = [time_v(:,3) zeros(size(time_v(:,3)))];
index = ismember(time_v(:,3),all_mean_precip(:,3));
precip_m(index,2) = all_mean_precip(:,4);
precip_m(not(index),2) = NaN;

%epot:
epot = [epot(:,1:2) epot(:,1)+(epot(:,2)-1)./12 epot(:,3)];

%format:
epot_m = [time_v(:,3) zeros(size(time_v(:,3)))];
index = ismember(time_v(:,3),epot(:,3));
epot_m(index,2) = epot(:,4);
epot_m(not(index),2) = NaN;

%__________________________________________________________________________
%PRE-PROCESSING DISCHARGE DATA:

inflow = [inflow(:,1:2) inflow(:,1)+(inflow(:,2))./12 inflow(:,3)];

inflow(:,4) = inflow(:,4)./1000;

%format:
inflow_m = [time_v(:,3) zeros(size(time_v(:,3)))];
index = ismember(time_v(:,3),inflow(:,3));
inflow_m(index,2) = inflow(:,4);
inflow_m(not(index),2) = NaN;

%__________________________________________________________________________
%PRE-PROCESSING LEVEL DATA:

lake_level = [lake_level(:,1:2) lake_level(:,1)+(lake_level(:,2)-1)./12 lake_level(:,3)];

%format:
level_m = [time_v(:,3) zeros(size(time_v(:,3)))];
index = ismember(time_v(:,3),lake_level(:,3));
level_m(index,2) = lake_level(:,4);
level_m(not(index),2) = NaN;


%__________________________________________________________________________
%SEASONAL VALUES:

seasons = [];
level_a = [];
inflow_a = [];
precip_a = [];
epot_a = [];
for i = 1:88
    
    seasons = [seasons ; 1930+i];
    level_a = [level_a ; mean(level_m((i-1)*12+1:i*12,2))];
    inflow_a = [inflow_a ; sum(inflow_m((i-1)*12+1:i*12,2))];
    precip_a = [precip_a ; sum(precip_m((i-1)*12+1:i*12,2))];
    epot_a = [epot_a ; sum(epot_m((i-1)*12+1:i*12,2))];

end

%add extra values:
level_a(1:35) = lake_level_extra(1:35,2);
inflow_extra(:,2) = inflow_extra(:,2)./1000;
inflow_a(23:35) = inflow_extra(1:13,2);
inflow_a(87) = inflow_extra(65,2);

%calculate area:
area_a = [];
for i = 1:length(seasons)   
    n_cells = sum(bathimetry<=level_a(i) & bathimetry>1000);
    n_cells = sum(n_cells);
    a = n_cells*900/1000000;
    area_a = [area_a ; a];        
end

%calculate volume:
volume_a = [];
for i = 1:length(seasons)    
    rel_cells = bathimetry(bathimetry<=level_a(i) & bathimetry>1000);
    mean_depth = level_a(i) - mean(rel_cells);
    v = mean_depth * area_a(i);
    v = v/1000;
    volume_a = [volume_a ; v]; 
end


%salinity model:
salinity = volume_a.*(0.6156)+37.1945;
salinity(salinity>38) = 38;

%evaporation model:
alpha = 1.1264-salinity.*0.0124;
eact_a = epot_a.*alpha;

%total evaporation from lake:
total_evap_a = area_a.*eact_a./1000000;

%total precipitation to lake:
total_precip_a = area_a.*precip_a./1000000;

%balance:
balance_a = inflow_a+total_precip_a-total_evap_a;

%__________________________________________________________________________
%PRINT SCENARIO VALUES:

disp('SCENARIO INFO');
disp(' ');


%start:
disp('Start');
disp(['Level: ',num2str(level_a(88))]);
disp(' ');

%status quo (mean of period 6):
disp('Status quo');
disp(['Inflow: ',num2str(mean(inflow_a(83:86)))]);
disp(['Precip: ',num2str(mean(precip_a(83:86)))]);
disp(['Epot: ',num2str(mean(epot_a(83:86)))]);
disp(' ');

%worst case (mean of 99/00 to 00/01):
disp('Worst case');
disp(['Inflow: ',num2str(mean(inflow_a(70:71)))]);
disp(['Precip: ',num2str(mean(precip_a(70:71)))]);
disp(['Epot: ',num2str(mean(epot_a(70:71)))]);
disp(' ');

%best case (mean of period 3):
disp('Best case');
disp(['Inflow: ',num2str(mean(inflow_a(61:64)))]);
disp(['Precip: ',num2str(mean(precip_a(61:64)))]);
disp(['Epot: ',num2str(mean(epot_a(61:64)))]);
disp(' ');


%__________________________________________________________________________
%PLOT:

fig1 = figure(1);
set(fig1,'Position',[200 300 1100 400],'Color',[0.95 0.95 0.95],'InvertHardcopy','off');


%defining axes:
axesPosition = [45 50 1005 300];  
xLimit = [1931 2018];                  

%lake volume
ax1 = axes('Units','pixels','Position',axesPosition,...
    'Color','w','XColor',[0 0 0],'YColor',[0 0 0],'XLim',xLimit,'YLim',[0 35],...
    'YTick',[0 5 10 15 20 25 30 35],'XTick',[1931 1966 1970 1991 1995 2002 2013 2017],...
    'XTickLabels',{'30/31','65/66','69/70','90/91','94/95','01/02','12/13','16/17'},'FontSize',...
    font_size,'NextPlot','add','Box','off');

%balance components
ax2 = axes('Units','pixels','Position',axesPosition,'YAxisLocation','right',...
	'Color','none','XColor',[0 0 0],'YColor',[0 0 0],...
	'XTick',[],'XLim',xLimit,'YLim',[-10 20],'YTick',[-10 -5 0 5 10 15 20 25],'FontSize',font_size,'NextPlot','add');

%extra
ax3 = axes('Units','pixels','Position',axesPosition,...
	'Color','none','XColor',[0 0 0],'YColor',[0 0 0],...
	'XLim',xLimit,'XTick',[],'YLim',[-5 35],'YTick',[],'FontSize',font_size,'NextPlot','add','Box','on');

hold on

%lake volume
p1 = area(ax1,seasons,volume_a,0);
set(p1,'EdgeColor','None','FaceColor',[0.3 0.5 1],'FaceAlpha',0.2);

%balance
a1 = area(ax2,seasons,balance_a,0);
set(a1,'EdgeColor','None','FaceColor',[0 0 0],'FaceAlpha',0.5);

%discharge
p2 = plot(ax2,seasons,inflow_a);
set(p2,'LineStyle','-','LineWidth',1,'Marker','o','MarkerSize',6,'Color',[1 0.5 0.3],'MarkerFaceColor','None');

%total evaporation
p3 = plot(ax2,seasons,total_evap_a.*(-1));
set(p3,'LineStyle','-','LineWidth',1,'Marker','o','MarkerSize',6,'Color',[0.2 0.8 0.2],'MarkerFaceColor','None');

%total precipitation
p4 = plot(ax2,seasons,total_precip_a);
set(p4,'LineStyle','-','LineWidth',1,'Marker','o','MarkerSize',6,'Color',[0.3 0.5 1],'MarkerFaceColor','None');

%balance
p5 = plot(ax2,seasons,balance_a);
set(p5,'LineStyle','-','LineWidth',1,'Marker','None','MarkerSize',6,'Color',[0 0 0],'MarkerFaceColor','None');

%zero line
p6 = plot(ax2,xLimit,[0 0]);
set(p6,'LineStyle','-','LineWidth',1,'Color',[0 0 0]);

%observed balance
p10 = plot(ax2,seasons(2:end),volume_a(2:end)-volume_a(1:end-1));
set(p10,'LineStyle','-','LineWidth',1.5,'Color',[0.7 0.7 0.7]);


%x-grid
p7 = plot(ax3,[1969.5 1969.5 NaN 1990.5 1990.5 NaN 1994.5 1994.5 NaN 2001.5 2001.5 NaN 2012.5 2012.5],...
    [-5 35 NaN -5 35 NaN -5 35 NaN -5 35 NaN -5 35]);
set(p7,'LineStyle',':','LineWidth',2,'Color',[0 0 0]);

p8 = plot(ax3,[1965.5 1965.5],[-5 35]);
set(p8,'LineStyle','-','LineWidth',2,'Color',[0 0 0]);
p8.Color(4) = 0.5;

p9 = plot(ax3,[2016.5 2016.5],[-5 35]);
set(p9,'LineStyle','-','LineWidth',2,'Color',[0 0 0]);
p9.Color(4) = 0.5;


%legend
leg_1 = legend([p1 p2 p3 p4 p5 p10],'Lake volume [km^3]','Inflow [km^3/a]',...
    'Evaporation from lake [km^3/a]','Precipitation to lake [km^3/a]','Calculated change of storage [km^3/a]',...
    'Observed change of storage [km^3/a]','Location',[0.078 0.65 0.14 0.15]); 
set(leg_1,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');

set(get(ax1,'ylabel'),'String','Lake volume [km^3]','Color',[0 0 0],'FontSize',font_size);
set(get(ax2,'ylabel'),'String','Balance components [km^3/a]','Color',[0 0 0],'FontSize',font_size);

%annotations
t2 = text(1967.5,28,'period 1','FontSize',font_size,'Rotation',90);
t2 = text(1977.5,33,'period 2','FontSize',font_size);
t3 = text(1992.5,28,'period 3','FontSize',font_size,'Rotation',90);
t4 = text(1996,33,'period 4','FontSize',font_size);
t5 = text(2005,33,'period 5','FontSize',font_size);
t6 = text(2014.5,28,'period 6','FontSize',font_size,'Rotation',90);


hold off




