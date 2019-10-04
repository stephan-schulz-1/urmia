
%Created with R2019b

close all;
clear all;

%__________________________________________________________________________
%INPUT:

filepath_scenarios = 'table/Scenarios.xlsx';

filepath_bathimetry = 'raster/Bathimetry.tif';

start_level = 1270.489; %mean for season 2017/18:

n_years = 10;

font_size = 11;

%__________________________________________________________________________
%READ DATA:

scenarios = xlsread(filepath_scenarios);

bathimetry = imread(filepath_bathimetry);

%__________________________________________________________________________
%:VOLUME-AREA RELATIONSHIP:

level = transpose(1267.1:0.01:1277.9);

%calculate area:
ar = [];
for i = 1:length(level)   
    n_cells = sum(bathimetry<=level(i) & bathimetry>1000);
    n_cells = sum(n_cells);
    a = n_cells*900/1000000;
    ar = [ar ; a];        
end

%calculate volume:
volume = [];
for i = 1:length(level)    
    rel_cells = bathimetry(bathimetry<=level(i) & bathimetry>1000);
    mean_depth = level(i) - mean(rel_cells);
    v = mean_depth * ar(i);
    v = v/1000;
    volume = [volume ; v]; 
end

level_mat = [level ar volume];
level_mat(4,3) = 0.01;

%__________________________________________________________________________
%SCENARIO LOOP:

fig1 = figure(1);
set(fig1,'Position',[200 300 1100 500],'Color',[0.95 0.95 0.95],'InvertHardcopy','off');

for i = 1:6
    
	precip = scenarios(i,1);
    epot = scenarios(i,2);
    inflow = scenarios(i,3);

    new_level = start_level;
    scenario_mat = [];
    for j = 1:n_years+1
    
        %area:
        n_cells = sum(bathimetry<=new_level & bathimetry>1000);
        n_cells = sum(n_cells);
        ar = n_cells*900/1000000;
    
        %volume:
        rel_cells = bathimetry(bathimetry<=new_level & bathimetry>1000);
        mean_depth = new_level - mean(rel_cells);
        volume = mean_depth * ar;
        volume = volume/1000;
        
        %eact:
            %salinity model:
        salinity = volume.*(-0.6156)+37.1945;
        salinity(salinity>38) = 38;

            %evaporation model:
        alpha = 1.1264-salinity.*0.0124;
        eact = epot.*alpha;
 
        total_evap = ar.*eact./1000000;
    
        %precip:
        total_precip = ar.*precip./1000000;
             
        %balance:
        balance = inflow + total_precip - total_evap;
        
        %write scenario:
        scenario_mat = [scenario_mat ; j-1 volume inflow total_precip total_evap balance];
  
        %new volume:
        new_volume = volume + balance;
     
        %new level
        dist = abs(level_mat(:,3)-new_volume);
        position = find(dist == min(dist));
        new_level = level_mat(position,1);
    
    end
    
    %PLOT:
    
    if i == 1
        axesPosition = [100 250 300 200];
        bot_label = {'','','','','',''};
        left_label = {'0','5','10','15','20','25','30','35'};
        right_label = {'','','','','','','',''};
    elseif i == 2
        axesPosition = [425 250 300 200];
        bot_label = {'','','','','',''};
        left_label = {'','','','','','','',''};
        right_label = {'','','','','','','',''};
	elseif i == 3
        axesPosition = [750 250 300 200];
        bot_label = {'','','','','',''};
        left_label = {'','','','','','','',''};
        right_label = {'-10','-5','0','5','10','15','20','25'};
	elseif i == 4
        axesPosition = [100 25 300 200];
        bot_label = {'0 a','2 a','4 a','6 a','8 a','10 a'};
        left_label = {'0','5','10','15','20','25','30','35'};
        right_label = {'','','','','','','',''};
    elseif i == 5
        axesPosition = [425 25 300 200];
        bot_label = {'0 a','2 a','4 a','6 a','8 a','10 a'};
        left_label = {'','','','','','','',''};
        right_label = {'','','','','','','',''};
	elseif i == 6
        axesPosition = [750 25 300 200];
        bot_label = {'0 a','2 a','4 a','6 a','8 a','10 a'};
        left_label = {'','','','','','','',''};
        right_label = {'-10','-5','0','5','10','15','20','25'};
    end
        
    %lake volume
    ax1 = axes('Units','pixels','Position',axesPosition,...
    'Color','w','XColor',[0 0 0],'YColor',[0 0 0],'XLim',[0 10],'YLim',[0 30],...
    'YTick',[0 5 10 15 20 25 30],'YTickLabel',left_label,'XTick',[0 2 4 6 8 10],'XTickLabel',bot_label,...
    'FontSize',font_size,'NextPlot','add','Box','off');
    
    %balance components
    ax2 = axes('Units','pixels','Position',axesPosition,'YAxisLocation','right',...
        'Color','none','XColor',[0 0 0],'YColor',[0 0 0],...
        'XTick',[],'XLim',[0 10],'YLim',[-8 12],'YTick',[-10 -5 0 5 10],'YTickLabel',right_label,...
        'FontSize',font_size,'NextPlot','add','Box','off');
    
    %for box:
    ax3 = axes('Units','pixels','Position',axesPosition,'YAxisLocation','right','Color','none','XColor',[0 0 0],'YColor',[0 0 0],...
        'XTick',[],'XLim',[0 10],'YLim',[-8 12],'YTick',[],'FontSize',font_size,'NextPlot','add','Box','on');
       
    hold on

    p1 = area(ax1,scenario_mat(:,1),scenario_mat(:,2),0);
    set(p1,'EdgeColor','None','FaceColor',[0.3 0.5 1],'FaceAlpha',0.2);
    
    p9 = plot(ax1,scenario_mat(:,1),scenario_mat(:,2));
    set(p9,'LineStyle','--','LineWidth',1,'Marker','None','Color',[0 0.2 0.6]);
    
    %balance
    a1 = area(ax2,scenario_mat(:,1),scenario_mat(:,6),0);
    set(a1,'EdgeColor','None','FaceColor',[0 0 0],'FaceAlpha',0.5);

    %inflow
    p2 = plot(ax2,scenario_mat(:,1),scenario_mat(:,3));
    set(p2,'LineStyle','-','LineWidth',1,'Marker','o','MarkerSize',6,'Color',[1 0.5 0.3],'MarkerFaceColor','None');

    %total evaporation
    p3 = plot(ax2,scenario_mat(:,1),scenario_mat(:,5).*(-1));
    set(p3,'LineStyle','-','LineWidth',1,'Marker','o','MarkerSize',6,'Color',[0.2 0.8 0.2],'MarkerFaceColor','None');
    
    %total precipitation
    p4 = plot(ax2,scenario_mat(:,1),scenario_mat(:,4));
    set(p4,'LineStyle','-','LineWidth',1,'Marker','o','MarkerSize',6,'Color',[0.3 0.5 1],'MarkerFaceColor','None');
    
    %balance
    p5 = plot(ax2,scenario_mat(:,1),scenario_mat(:,6));
    set(p5,'LineStyle','-','LineWidth',1,'Marker','None','MarkerSize',6,'Color',[0 0 0],'MarkerFaceColor','None');

    %zero line
    p6 = plot(ax2,[0 10],[0 0]);
    set(p6,'LineStyle','-','LineWidth',0.5,'Color',[0 0 0]);
       
    if i == 1
        set(get(ax1,'ylabel'),'String','Lake volume [km^3]','Color',[0 0 0],'FontSize',font_size);   
        text(-2,-5,'Current extraction','clipping','off','Rotation',90,'FontSize',14,'FontWeight','bold');
        text(ax1,0.2,28,'a','FontSize',14,'FontWeight','bold');
        text(ax1,9.3,28,'a´','FontSize',14,'FontWeight','n');
    elseif i == 2
        text(ax1,0.2,28,'b','FontSize',14,'FontWeight','bold');
        text(ax1,9.3,28,'b´','FontSize',14,'FontWeight','n');
	elseif i == 3
        set(get(ax2,'ylabel'),'String','Balance components [km^3/a]','Color',[0 0 0],'FontSize',font_size);
        text(ax1,0.2,28,'c','FontSize',14,'FontWeight','bold');
        text(ax1,9.3,28,'c´','FontSize',14,'FontWeight','n');
    elseif i == 4
        set(get(ax1,'ylabel'),'String','Lake volume [km^3]','Color',[0 0 0],'FontSize',font_size);
        text(-2,-5,'Reduced extraction','clipping','off','Rotation',90,'FontSize',14,'FontWeight','bold');
        text(ax1,0.2,28,'d','FontSize',14,'FontWeight','bold');
        text(ax1,9.3,28,'d´','FontSize',14,'FontWeight','n');
    elseif i == 5
        text(ax1,0.2,28,'e','FontSize',14,'FontWeight','bold');
        text(ax1,9.3,28,'e´','FontSize',14,'FontWeight','n');
	elseif i == 6
        set(get(ax2,'ylabel'),'String','Balance components [km^3/a]','Color',[0 0 0],'FontSize',font_size);
        text(ax1,0.2,17,'f','FontSize',14,'FontWeight','bold');
        text(ax1,9.3,28,'f´','FontSize',14,'FontWeight','n');
    end
      
    axesPosition = axesPosition.*[1 1 0 0] + [225 95 70 100];

    ax4 = axes('Units','pixels','Position',axesPosition,...
        'Color','None','XColor',[0 0 0],'YColor',[0 0 0],'XLim',[0 3034],'YLim',[0 4620],'YDir','reverse',...
        'YTick',[],'XTick',[],'FontSize',font_size,'NextPlot','add','Box','on');


    extent = bathimetry;
    extent(extent<1000) = NaN;
    extent(extent>=new_level) = NaN;
    extent = extent.*0 + 1;

    cmap = [0.3 0.8 1 ; 0.3 0.8 1];
    
    imAlpha=ones(size(extent));
    imAlpha(isnan(extent))=0;
    i1 = imagesc(ax4,extent,'AlphaData',imAlpha);
    colormap(cmap);
    
    extent_recent = bathimetry;
    extent_recent(extent_recent<1000) = NaN;
    extent_recent(extent_recent>=1270) = NaN;
    extent_recent = extent_recent.*0 + 1;
    extent_recent(isnan(extent_recent)) = 0;
    
    c1 = contour(ax4,extent_recent,'Color',[0 0 0]);
        
    hold off
       
end

annotation('textbox',[0.19 0.95 0.01 0.01],'String','Best case','FontSize',14,'FontWeight','bold',...
	'FitBoxToText','on','Color',[0 0 0],'EdgeColor','None');
    
annotation('textbox',[0.48 0.95 0.01 0.01],'String','Status quo','FontSize',14,'FontWeight','bold',...
	'FitBoxToText','on','Color',[0 0 0],'EdgeColor','None');
    
annotation('textbox',[0.775 0.95 0.01 0.01],'String','Worst case','FontSize',14,'FontWeight','bold',...
	'FitBoxToText','on','Color',[0 0 0],'EdgeColor','None');
        
annotation('line',[0.374 0.374],[0.05 0.95],'Color',[0.5 0.5 0.5],'LineWidth',2);
annotation('line',[0.6695 0.6695],[0.05 0.95],'Color',[0.5 0.5 0.5],'LineWidth',2);
annotation('line',[0.03 0.98],[0.471 0.471],'Color',[0.5 0.5 0.5],'LineWidth',2);

%legend
leg_1 = legend(ax4,[p2 p3 p4 p5 p9],'Discharge','Evaporation from lake','Precipitation to lake',...
    'Simulated change of storage','Simulated lake volume','Location',[0.702 0.306 0.14 0.12]); 
set(leg_1,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');
uistack(leg_1,'top');

pl2 = area(ax1,-100,-100,-100,'EdgeColor','None','FaceColor',[0.3 0.8 1]);
cl1 = plot(ax1,[-100 -99],[-100 -99],'Color',[0 0 0]);

leg_3 = legend(ax1,[pl2 cl1],'Simulated lake extent','Recent lake extent (2018)','Location',[0.778 0.7 0.1 0.05]); 
set(leg_3,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');
uistack(leg_3,'top');



