
%Created with R2019b

close all;
clear all;

%__________________________________________________________________________
%INPUT:

filepath_profile = 'table/Cross_section.xlsx';

filepath_bathimetry = 'raster/Bathimetry.tif';

level = [1270.0 1271.1 1278.4];

ABC = [0 41.15 170];

clipper = [10 180];

kernel_size = 50;

font_size = 11;

%__________________________________________________________________________

%read files
profile_data = xlsread(filepath_profile);
profile_data(:,1) = profile_data(:,1).*30./1000;

bathimetry = imread(filepath_bathimetry);

%replace NaN
x = isnan(profile_data(:,3));
profile_data(x,3) = profile_data(x,2);

%clip data
profile_data = profile_data(profile_data(:,1)>=clipper(1) & profile_data(:,1)<=clipper(2),:);
profile_data(:,1) = transpose([0:0.03:(clipper(2)-clipper(1))]);

%moving average filter:
    %add values at the beginning to avoid initial zero value:
profile_data_add = [ones(kernel_size,1).*profile_data(1,3) ; profile_data(:,3)];

profile_data_add_f1 = filter((1/kernel_size)*ones(1,kernel_size),1,profile_data_add);

    %kick out added values:
profile_data_f1 = profile_data_add_f1(kernel_size+1:end);

%clip data according to level:
profile_data_f1_level1 = profile_data_f1;
profile_data_f1_level1(profile_data_f1_level1>level(1)) = level(1);

profile_data_f1_level2 = profile_data_f1;
profile_data_f1_level2(profile_data_f1_level2>level(2)) = level(2);
profile_data_f1_level2(profile_data_f1_level2<level(1)) = level(1);

profile_data_f1_level3 = profile_data_f1;
profile_data_f1_level3(profile_data_f1_level3>level(3)) = level(3);
profile_data_f1_level3(profile_data_f1_level3<level(2)) = level(2);

%__________________________________________________________________________
%:VOLUME-AREA RELATIONSHIP:

lev = transpose(1267.1:0.01:1277.9);

%calculate area:
ar = [];
for i = 1:length(lev)   
    n_cells = sum(bathimetry<=lev(i) & bathimetry>1000);
    n_cells = sum(n_cells);
    a = n_cells*900/1000000;
    ar = [ar ; a];        
end

%calculate volume:
vol = [];
for i = 1:length(lev)    
    rel_cells = bathimetry(bathimetry<=lev(i) & bathimetry>1000);
    mean_depth = lev(i) - mean(rel_cells);
    v = mean_depth * ar(i);
    v = v/1000;
    vol = [vol ; v]; 
end

lav = [lev ar vol];
lav(4,3) = 0.01;

%__________________________________________________________________________
%plot:

fig1 = figure(1);
set(fig1,'Position',[200 300 1100 400],'Color',[0.95 0.95 0.95],'InvertHardcopy','off');

%first graph:
%defining axes:
x_limits = [-5 175];
x_limits = [0 170];
axesPosition1 = [60 20 1000 199.44];  
axesPosition2 = [60 219.44 1000 107];  

VE1 = ((axesPosition1(4) / (level(3) - 1267.1)) / (axesPosition1(3) / (x_limits(2)-x_limits(1))))*1000;
VE2 = ((axesPosition2(4) / (1400 - level(3))) / (axesPosition2(3) / (x_limits(2)-x_limits(1))))*1000;

ax(1) = axes('Units','pixels','Position',axesPosition1,...
    'Color','w','XColor',[0 0 0],'YColor',[0 0 0],'XLim',x_limits,'YLim',[1267.1 level(3)],...
    'YTick',[1267.1 1270.0 level(2) level(3)],'YTickLabel',{'1267.1' ; '1270.0' ; '1271.1' ; '1278.4'},'XTick',...
    [0 20 40 60 80 100 120 140 160],'XTickLabel',...
    {'0 km'; '20 km'; '40 km'; '60 km'; '80 km' ; '100 km' ; '120 km' ; '140 km' ; '160 km'},...
    'FontSize',font_size,'NextPlot','add','Box','on');

ax(2) = axes('Units','pixels','Position',axesPosition1,...
    'Color','None','XColor',[0 0 0],'YColor',[0 0 0],'XLim',x_limits,'YLim',[1267.1 level(3)],...
    'YTick',[],'XTick',[],'FontSize',font_size,'NextPlot','add','Box','on');

ax(3) = axes('Units','pixels','Position',axesPosition1,...
    'Color','None','XColor',[0 0 0],'YColor',[0 0 0],'XLim',x_limits,'YLim',[1267.1 level(3)],...
    'YTick',[],'XTick',[],'FontSize',font_size,'NextPlot','add','Box','on');

ax(4) = axes('Units','pixels','Position',axesPosition1,...
    'Color','None','XColor',[0 0 0],'YColor',[0 0 0],'XLim',x_limits,'YLim',[1267.1 level(3)],...
    'YTick',[],'XTick',[],'FontSize',font_size,'NextPlot','add','Box','on');

ax2 = axes('Units','pixels','Position',axesPosition2,...
    'Color','w','XColor','None','YColor',[0 0 0],'XLim',x_limits,'YLim',[level(3) 1400],...
    'YTick',[1300 1350 1400],'XTick',[],'FontSize',font_size,'NextPlot','add','Box','on');

set(get(ax(1),'ylabel'),'String','                                  Elevation [m a.s.l.]','Color',[0 0 0],'FontSize',font_size);

hold on;

%lower graph
a3 = area(ax(1),profile_data(:,1),profile_data_f1_level3,level(3));
set(a3,'EdgeColor','none','FaceColor',[186/255 210/255 253/255],'FaceAlpha',1,'ShowBaseline','off');

a2 = area(ax(2),profile_data(:,1),profile_data_f1_level2,level(2));
set(a2,'EdgeColor','none','FaceColor',[103/255 178/255 251/255],'FaceAlpha',1,'ShowBaseline','off');

a1 = area(ax(3),profile_data(:,1),profile_data_f1_level1,level(1));
set(a1,'EdgeColor','none','FaceColor',[0 90/255 226/255],'FaceAlpha',1,'ShowBaseline','off');

a4 = area(ax(4),profile_data(:,1),profile_data_f1,1267.1);
set(a4,'EdgeColor','none','FaceColor',[0 0 0],'FaceAlpha',0.5,'ShowBaseline','off');

p1 = plot(ax(3),profile_data(:,1),profile_data_f1);
set(p1,'LineStyle','-','LineWidth',1,'Marker','None','Color',[0.3 0.3 0.3]);

p5 = plot(ax(4),[ABC(1) ABC(1) NaN ABC(2) ABC(2) NaN ABC(3) ABC(3)],[1267.1 level(3) NaN 1267.1 level(3) NaN 1267.1 level(3)]);
set(p5,'LineStyle','-','LineWidth',1,'Marker','None','Color',[0 0 0]);

p6 = plot(ax(4),x_limits,[1269.8 1269.8]);
set(p6,'LineStyle','--','LineWidth',1,'Marker','None','Color',[1 0 0]);


%upper graph
a5 = area(ax2,profile_data(:,1),profile_data_f1,1267.1);
set(a5,'EdgeColor','none','FaceColor',[0 0 0],'FaceAlpha',0.5,'ShowBaseline','off');

p2 = plot(ax2,profile_data(:,1),profile_data_f1);
set(p2,'LineStyle','-','LineWidth',1,'Marker','None','Color',[0.3 0.3 0.3]);

p3 = plot(ax2,x_limits,[level(3) level(3)]);
set(p3,'LineStyle',':','LineWidth',1.5,'Marker','None','Color',[0 0 0]);

p4 = plot(ax2,[ABC(1) ABC(1) NaN ABC(2) ABC(2) NaN ABC(3) ABC(3)],[level(3) 1360 NaN level(3) 1360 NaN level(3) 1360]);
set(p4,'LineStyle','-','LineWidth',1,'Marker','None','Color',[0 0 0]);

p7 = plot(ax2,x_limits,[1400 1400]);
set(p7,'LineStyle','-','LineWidth',0.5,'Marker','None','Color',[0 0 0]);

%annotations
t1 = text(10,1292,['VE = ',num2str(round(VE2))],'FontSize',font_size);
t2 = text(10,1265,['VE = ',num2str(round(VE1))],'FontSize',font_size);

t2 = text(ABC(1)+0.5,1380,'A','FontSize',16);
t2 = text(ABC(2)-1,1380,'B','FontSize',16);
t2 = text(ABC(3)-2.5,1380,'C','FontSize',16);

t10 = text(1.5,1073,'a','FontSize',16,'Color',[0 0 0],'FontWeight','bold',...
    'BackgroundColor',[1 1 1],'EdgeColor','None','Margin',3);

t11 = text(15,1120,'Tipping point (1269.8 m a.s.l.)','FontSize',font_size,'Color',[1 0 0]);

patch1 = patch(ax(4),[115.5 115.5 158 158],[1275 1280 1280 1275],[1 1 1]);
set(patch1,'FaceAlpha',0.5,'EdgeColor','None');


%second graph:
%defining axes:
axesPosition = [760 195 210 160];  %# Axes position, in pixels

%lake volume vs area
ax11 = axes('Units','pixels','Position',axesPosition,...
    'Color','w','XColor',[0 0 0],'YColor',[0 0 0],'XLim',[0 10],'YLim',[0 4000],...
    'YTick',[0 1000 2000 3000 4000],'XTick',[0 2 4 6 8 10],'FontSize',font_size,'NextPlot','add','Box','on');

a11 = area(lav(lav(:,3)>=1.47 & lav(:,3)<=3.73,3),lav(lav(:,3)>=1.47 & lav(:,3)<=3.73,2),0);
set(a11,'EdgeColor','none','FaceColor',[103/255 178/255 251/255],'FaceAlpha',1,'ShowBaseline','off');

p11 = plot(ax11,lav(:,3),lav(:,2));
set(p11,'LineStyle','-','LineWidth',1,'Marker','None','Color',[0 0 0]);

p12 = plot(ax11,[1.29 1.29],[0 1000]);
set(p12,'LineStyle','--','LineWidth',1,'Marker','None','Color',[1 0 0]);

p13 = plot(ax11,[1.29],[1000]);
set(p13,'LineStyle','None','Marker','.','MarkerSize',15,'Color',[1 0 0]);

p14 = plot(ax11,[1.475],[1299.03]);
set(p14,'LineStyle','None','Marker','.','MarkerSize',15,'Color',[0 0 0]);

p15 = plot(ax11,[3.727],[2678.03]);
set(p15,'LineStyle','None','Marker','.','MarkerSize',15,'Color',[0 0 0]);

set(get(ax11,'ylabel'),'String','Lake area [km^2]     ','Color',[0 0 0],'FontSize',font_size);
set(get(ax11,'xlabel'),'String','Lake volume [km^3]','Color',[0 0 0],'FontSize',font_size);

t11 = text(1.6,1000,'Tipping point (1269.8 m a.s.l.)','FontSize',font_size,'FontWeight','normal','Color',[1 0 0]);
t12 = text(0.35,3650,'b','FontSize',16,'FontWeight','bold');

t13 = text(1.8,1400,'1270.0 m a.s.l.','FontSize',font_size,'FontWeight','normal','Color',[0 0 0]);
t14 = text(4,2600,'1271.1 m a.s.l.','FontSize',font_size,'FontWeight','normal','Color',[0 0 0]);



