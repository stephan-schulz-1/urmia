
%Created with R2019b
%Requires Mapping Toolbox

close all;
clear all;

%__________________________________________________________________________
%INPUT:

filepath_discharge = 'table/Discharge_monthly.xlsx';
filepath_runoff_info = 'table/Runoff_info.xlsx';

filepath_rivers = 'vector/Rivers.shp';
filepath_dams = 'vector/Reservoirs.shp';
filepath_bathimetry_1278 = 'vector/extent_1278m.shp';
filepath_bathimetry_1274 = 'vector/extent_1274m.shp';
filepath_bathimetry_1270 = 'vector/extent_1270m.shp';
filepath_catchment = 'vector/Catchment.shp';
filepath_causeway = 'vector/Causeway.shp';
filepath_cross_section = 'vector/Cross_section.shp';
filepath_scale = 'vector/Scale.shp';
filepath_weather = 'vector/Weather_stations.shp';
filepath_irrigation = 'vector/Irrigation.shp';
filepath_Iran = 'vector/Iran.shp';
filepath_World = 'vector/World.shp';


font_size = 11;

%__________________________________________________________________________

%read files:
[discharge_num,discharge_txt,discharge_raw] = xlsread(filepath_discharge);
runoff_info = xlsread(filepath_runoff_info);
rivers = shaperead(filepath_rivers);
dams = shaperead(filepath_dams);
bathimetry_1278 = shaperead(filepath_bathimetry_1278);
bathimetry_1274 = shaperead(filepath_bathimetry_1274);
bathimetry_1270 = shaperead(filepath_bathimetry_1270);
catchment = shaperead(filepath_catchment);
causeway = shaperead(filepath_causeway);
cross_section = shaperead(filepath_cross_section);
scale = shaperead(filepath_scale);
weather = shaperead(filepath_weather);
irrigation = shaperead(filepath_irrigation);
Iran = shaperead(filepath_Iran);
World = shaperead(filepath_World);

%calculate discharge data availability:
years = unique(discharge_num(:,5),'rows');
n_discharge = [];
for year = min(years):max(years)
    
    n_stations = length(find(discharge_num(:,5) == year));

	years = [ones(3,1).*year ; ones(9,1).*(year+1)];
	months = [10 ; 11 ; 12 ; 1 ; 2 ; 3 ; 4 ; 5 ; 6 ; 7 ; 8 ; 9];
    time = years + (months-1)./12;      
        
	n_discharge = [n_discharge ; years months time ones(12,1).*n_stations];
          
end

%__________________________________________________________________________
%PLOT

fig1 = figure(1);
set(fig1,'Position',[100 200 1100 705],'Color',[0.95 0.95 0.95],'InvertHardcopy','off');

%main map:
axesPosition = [50 25 650 655];

ax1 = axes('Units','pixels','Position',axesPosition,'YAxisLocation','Left','Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[44.2 47.9],'YLim',[35.6 38.6],'XTick',[44 45 46 47],'XTickLabel',{'44°' '45°' '46°' '47°'},'YTick',[36 37 38],...
    'YTickLabel',{'36°' '37°' '38°'},'FontSize',font_size,'NextPlot','add','Box','on');


ax11 = axes('Units','pixels','Position',axesPosition,'XAxisLocation','Top','YAxisLocation','Left','Color','None','XColor',[0 0 0],...
    'YColor','None','XLim',[44.2 47.9],'YLim',[35.6 38.6],'XTick',[44 45 46 47],'XTickLabel',{'44°' '45°' '46°' '47°'},'YTick',[36 37 38],...
    'YTickLabel',{'36°' '37°' '38°'},'FontSize',font_size,'NextPlot','add','Box','on');

hold on

m8 = mapshow(ax1,catchment,'FaceColor',[0.95 0.95 0.95],'EdgeColor','None');
m8 = mapshow(ax1,irrigation,'FaceColor',[0.5 0.8 0.5],'EdgeColor','None');

for i =1:length(rivers)
    m2 = plot(ax1,rivers(i).X(1:end-1),rivers(i).Y(1:end-1));
    set(m2,'LineStyle','-','LineWidth',0.5,'Color',[0 0.4 0.8]);    
end

for i =1:length(dams)
    m3 = patch(ax1,dams(i).X(1:end-2),dams(i).Y(1:end-2),[0 0 0]);
    set(m3,'FaceColor',[1 0 1],'EdgeColor',[1 0 1],'LineWidth',2);    
end

m3 = mapshow(ax1,bathimetry_1278,'FaceColor',[0.8 0.9 1],'EdgeColor','None');
m4 = mapshow(ax1,bathimetry_1274,'FaceColor',[0.6 0.7 1],'EdgeColor','None');
m5 = mapshow(ax1,bathimetry_1270,'FaceColor',[0.4 0.5 1],'EdgeColor','None');

m6 = plot(ax1,causeway.X(1:end-1),causeway.Y(1:end-1));
set(m6,'LineStyle','-','LineWidth',4,'Color',[0.4 0.4 0.4]);

m7 = plot(ax1,cross_section.X(1:end-1),cross_section.Y(1:end-1));
set(m7,'LineStyle','--','LineWidth',1,'Color',[0 0 0]);

text(ax1,cross_section.X(1),cross_section.Y(1)+0.05,'A','FontSize',14,'FontWeight','n')
text(ax1,cross_section.X(2)-0.07,cross_section.Y(2),'B','FontSize',14,'FontWeight','n')
text(ax1,cross_section.X(3),cross_section.Y(3),'C','FontSize',14,'FontWeight','n')

for i = 1:length(weather)
    p3 = plot(ax1,weather(i).X+0.02,weather(i).Y);
    set(p3,'LineStyle','None','Marker','^','MarkerEdgeColor',[0 0 0],'LineWidth',0.3,'MarkerFaceColor',[1 1 0],'MarkerSize',18);
end

p1 = plot(ax1,runoff_info(:,3),runoff_info(:,4));
set(p1,'LineStyle','None','Marker','o','MarkerEdgeColor',[0 0 0],'LineWidth',0.5,'MarkerFaceColor',[1 1 1],'MarkerSize',9);

text(ax1,46.33,36.36,'1970','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,46.2,36.82,'1967','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,45.47,36.78,'1970','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,45.4,37.1,'2000','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,44.95,37.46,'2004','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,44.45,38.13,'2010','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,46.5,38.27,'1996','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,46.9,38.13,'2001','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,47.52,37.93,'1980','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')
text(ax1,47.12,36.48,'1980','Color',[1 0 1],'FontSize',font_size,'FontWeight','n')

text(ax1,46.2,36.95,'2002','Color',[1 1 0],'FontSize',font_size,'FontWeight','n','BackgroundColor',[0.6 0.6 0.6],'EdgeColor','None','Margin',0.5);
text(ax1,46.13,37.27,'1985','Color',[1 1 0],'FontSize',font_size,'FontWeight','n','BackgroundColor',[0.6 0.6 0.6],'EdgeColor','None','Margin',0.5);
text(ax1,46.33,38.19,'1951','Color',[1 1 0],'FontSize',font_size,'FontWeight','n','BackgroundColor',[0.6 0.6 0.6],'EdgeColor','None','Margin',0.5);
text(ax1,44.95,37.59,'1951','Color',[1 1 0],'FontSize',font_size,'FontWeight','n','BackgroundColor',[0.6 0.6 0.6],'EdgeColor','None','Margin',0.5);
text(ax1,45.79,36.8,'1985','Color',[1 1 0],'FontSize',font_size,'FontWeight','n','BackgroundColor',[0.6 0.6 0.6],'EdgeColor','None','Margin',0.5);

p2 = plot(ax1,scale.X(1:2),[35.75 35.75]);
set(p2,'LineStyle','-','LineWidth',8,'Color',[0 0 0]);

text(ax1,mean(scale.X(1:2))-0.08,35.8,'50 km','FontSize',font_size);

text(ax1,46.2,38.02,'Tabriz','FontSize',14,'FontWeight','b');
text(ax1,44.8,37.75,'Urmia','FontSize',14,'FontWeight','b');
text(ax1,46,37.06,'Miandoab','FontSize',14,'FontWeight','b');

l7 = plot(ax1,0,0,'LineStyle','-','Marker','None','Color',[0 0.4 0.8],'LineWidth',0.5);
l8 = plot(ax1,0,0,'LineStyle','None','Marker','s','MarkerEdgeColor',[1 0 1],'LineWidth',1,'MarkerFaceColor',[1 0 1],'MarkerSize',10);
l9 = plot(ax1,0,0,'LineStyle','None','Marker','s','MarkerEdgeColor',[0.8 0.9 1],'LineWidth',1,'MarkerFaceColor',[0.8 0.9 1],'MarkerSize',10);
l10 = plot(ax1,0,0,'LineStyle','None','Marker','s','MarkerEdgeColor',[0.6 0.7 1],'LineWidth',1,'MarkerFaceColor',[0.6 0.7 1],'MarkerSize',10);
l11 = plot(ax1,0,0,'LineStyle','None','Marker','s','MarkerEdgeColor',[0.4 0.5 1],'LineWidth',1,'MarkerFaceColor',[0.4 0.5 1],'MarkerSize',10);
l12 = plot(ax1,0,0,'LineStyle','None','Marker','None');
l13 = plot(ax1,0,0,'LineStyle','None','Marker','None');
l14 = plot(ax1,0,0,'LineStyle','None','Marker','^','MarkerEdgeColor',[0 0 0],'LineWidth',0.3,'MarkerFaceColor',[1 1 0],'MarkerSize',10);
l15 = plot(ax1,0,0,'LineStyle','None','Marker','None');
l16 = plot(ax1,0,0,'LineStyle','None','Marker','s','MarkerEdgeColor',[0.5 0.8 0.5],'LineWidth',1,'MarkerFaceColor',[0.5 0.8 0.5],'MarkerSize',10);

leg2 = legend([l7 m6 m7 p1 l16 l14 l15 l8 l12 l13 l9 l10 l11],'River / canal','Causeway','Cross section','Discharge station',...
    'Irrigation agriculture (2016)','Weather station','Start of record','Reservoir (oversized)','Construction date',...
    '\bf Lake level','1278 m a.s.l. (1995)','1274 m a.s.l.','1270 m a.s.l. (2018)','Position',[0.681818 0.3191489 0.29545454 0.148936]);
set(leg2,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n','NumColumns',2,'NumColumnsMode','manual');

annotation('textbox',[0.844 0.447 0.001 0.001],'String','1970','FontSize',font_size,'FitBoxToText','on','Color',[1 0 1],'EdgeColor','None');
annotation('textbox',[0.702 0.332 0.00001 0.00001],'String','1951','FontSize',font_size,'FitBoxToText','on','Color',[1 1 0],'EdgeColor','None',...
    'BackgroundColor',[0.6 0.6 0.6],'Margin',0.5,'HorizontalAlignment','center','VerticalAlignment','middle');

hold off

text(44.28,38.52,'a','FontSize',16,'FontWeight','b');

%overview map:

axesPosition = [750 355 325 325];

ax2 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[43 64],'YLim',[24 40.875],'XTick',[50 60],'YTick',[30 40],'YAxisLocation','Right','XAxisLocation','Top',...
    'XTickLabel',{'50°' '60°'},'YTickLabel',{'30°' '40°'},'FontSize',font_size,'NextPlot','add','Box','on');

m21 = mapshow(ax2,World,'FaceColor',[0.95 0.95 0.95],'EdgeColor',[0 0 0]);

m22 = mapshow(ax2,Iran,'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0 0 0]);

m8 = mapshow(ax2,catchment,'FaceColor',[0.6 0.6 0.6],'EdgeColor',[0 0 0]);

m3 = mapshow(ax2,bathimetry_1278,'FaceColor',[0.8 0.9 1],'EdgeColor','None');

text(ax2,51.2,38.5,['Caspian',newline,'Sea'],'FontSize',14,'FontWeight','n','HorizontalAlignment','Center');
text(ax2,53,33,'Iran','FontSize',14,'FontWeight','b');
text(ax2,49.8,28.8,'Persian Gulf','FontSize',14,'FontWeight','n','Rotation',-52);

text(ax2,43.7,24.8,'b','FontSize',16,'FontWeight','b');

%number of hydrometric stations plot:
axesPosition = [750 25 325 175];

ax3 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[1948 2017],'YLim',[0 100],'XTick',[1948 1960 1970 1980 1990 2000 2010 2017],'YTick',[0 20 40 60 80 100],...
    'FontSize',font_size,'NextPlot','add','Box','on');

hold on

p31 = plot(ax3,n_discharge(:,3),n_discharge(:,4));
set(p31,'LineStyle','-','Color',[0 0 0],'LineWidth',1);

ylabel('Number of hydrometric stations','FontSize',font_size);

text(ax3,1950,90,'c','FontSize',16,'FontWeight','b');

hold off




