
%Created with R2019b
%Requires Statistics and Machine Learning Toolbox
%Requires ktaub function (available at: https://www.mathworks.com/matlabcentral/fileexchange/11190-mann-kendall-tau-b-with-sen-s-method-enhanced)
%Requires sktt function (available at: https://de.mathworks.com/matlabcentral/fileexchange/22389-seasonal-kendall-test-with-slope-for-serial-dependent-data)
%Requires s_index function (based on: https://de.mathworks.com/matlabcentral/fileexchange/51081-standardized-drought-analysis-toolbox-sdat)

clear all
close all

%__________________________________________________________________________
%INPUT:

filepath_epot_Tabriz = 'table/Epot_monthly_Tabriz.xlsx';

filepath_precip_Tabriz = 'table/Rainfall_monthly_Tabriz.xlsx';
filepath_precip_Urmia = 'table/Rainfall_monthly_Urmia.xlsx';
filepath_precip_Sahand = 'table/Rainfall_monthly_Sahand.xlsx';
filepath_precip_Mahabad = 'table/Rainfall_monthly_Mahabad.xlsx';
filepath_precip_Miandoab = 'table/Rainfall_monthly_Miandoab.xlsx';

filepath_discharge = 'table/Discharge_monthly.xlsx';

filepath_runoff_info = 'table/Runoff_info.xlsx';

filepath_dams = 'vector/Reservoirs.shp';

filepath_irrigation = 'table/Irrigation_extraction.xlsx';

irrigation_area = [1984 2855 ; 1990 2637 ; 2000 4308 ; 2006 4043 ; 2011 5525 ; 2013 5406 ; 2014 4641 ; 2016 4545];

periods = [1965.75 1969.75 1990.75 1994.75 2001.75 2012.75 2016.75];

color_periods = jet(6).*0.8;

%Standardized indices:
scale=12;

%Mann-Kendall test and Sen's slope:
alpha = 0.01;
wantplot = 0;
StartSeason = 10;

font_size = 11;

%__________________________________________________________________________
%READ DATA:

epot = xlsread(filepath_epot_Tabriz);
precip_Tabriz = xlsread(filepath_precip_Tabriz);
precip_Urmia = xlsread(filepath_precip_Urmia);
precip_Sahand = xlsread(filepath_precip_Sahand);
precip_Mahabad = xlsread(filepath_precip_Mahabad);
precip_Miandoab = xlsread(filepath_precip_Miandoab);
discharge_num = xlsread(filepath_discharge);
runoff_info = xlsread(filepath_runoff_info);
dams = shaperead(filepath_dams);
irrigation = xlsread(filepath_irrigation);

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

epot = [epot(:,1:2) epot(:,1)+(epot(:,2)-1)./12 epot(:,3)];

%__________________________________________________________________________
%PRE-PROCESSING DISCHARGE DATA:

stations = unique(discharge_num(:,3:4),'rows');

for i = 1:length(stations)
    
    positions = find(discharge_num(:,3) == stations(i,1) & discharge_num(:,4) == stations(i,2));
    
    %create relevant data matrix:
    relevant_data = [];
    for j = 1:length(positions)
        relevant_data = [relevant_data ; discharge_num(positions(j),3:18)];     
    end
    
    %check for continuity:
    delta_year = relevant_data(2:end,3)-relevant_data(1:end-1,3);
    
    if sum(delta_year) == length(delta_year)
        continuity = 1;
        filled_data = relevant_data;
    else
        continuity = 0;
         %close gaps:
         filled_data = relevant_data(1,:);
         for j = 1:length(delta_year)
             if delta_year(j) == 1
                 filled_data = [filled_data ; relevant_data(j+1,1:16)]; 
             else
                 coordinates = ones(delta_year(j),2).*relevant_data(1,1:2);
                 years = transpose([1:delta_year(j) ; 1:delta_year(j)]) + filled_data(end,3:4);
                 filler = ones(delta_year(j),12).*NaN;
                 filled_data = [filled_data ; coordinates years filler];               
             end
         end            
    end
    
    %converting data into a more useful form:
    formated_data = [];
    for j = 1:size(filled_data,1) 
        monthly_data = transpose(filled_data(j,5:16));
        months = [10 ; 11 ; 12 ; 1 ; 2 ; 3 ; 4 ; 5 ; 6 ; 7 ; 8 ; 9];
        years = [ones(3,1).*filled_data(j,3) ; ones(9,1).*filled_data(j,4)];
        formated_data = [formated_data ; years months monthly_data];
    end
    all_filled_data{i} = formated_data;
          
end

%__________________________________________________________________________
%PRE-PROCESSING OTHER DATA:

%dam capacity new:
dams_cell = struct2cell(dams);
dams_mat = transpose(cell2mat(dams_cell(9:10,:)));

capacity_v = [];
capacity = 0;
for year = min(dams_mat(:,1)):max(dams_mat(:,1)) 
    capacity = capacity + sum(dams_mat(dams_mat(:,1)==year,2));
    capacity_v = [capacity_v ; year capacity];
end

%irrigation:
irrigation_years = unique(irrigation(:,1));
irrigation_a = [];
for i = 1:length(irrigation_years)
    
    irrigation_a = [irrigation_a ; irrigation_years(i) sum(irrigation(irrigation(:,1)==irrigation_years(i),3))];
    
end

%create all time vector:
time_v = [precip_tab(:,1:2) precip_tab(:,1)+(precip_tab(:,2)-1)./12];

%__________________________________________________________________________
%STANDARDIZED INDICES:

all_data = [];
all_data_mouth = [];
all_season_data = [];
all_season_data_mouth = [];
for i = 1:length(all_filled_data)
    
    %select most suitable weather station
    if min(all_filled_data{i}(:,1)) >= 2002
        station_id = runoff_info(i,9);
    elseif min(all_filled_data{i}(:,1)) >= 1996 && min(all_filled_data{i}(:,1)) < 2002
        station_id = runoff_info(i,8);
	elseif min(all_filled_data{i}(:,1)) >= 1985 && min(all_filled_data{i}(:,1)) < 1996
        station_id = runoff_info(i,7);
	elseif min(all_filled_data{i}(:,1)) < 1985
        station_id = runoff_info(i,6);          
    end
    
    if station_id == 1
        precip = precip_mia;
    elseif station_id == 2
        precip = precip_sah;
	elseif station_id == 3
        precip = precip_tab;
	elseif station_id == 4
        precip = precip_urm;
	elseif station_id == 5
        precip = precip_mah;
    end
    
    precip = [precip(:,1:2) precip(:,1)+(precip(:,2)-1)./12 precip(:,3)];
    
    %data = [year month time discharge precip epot]
	data = all_filled_data{i}; 
	data = [data(:,1:2) data(:,1)+(data(:,2)-1)./12 data(:,3)];
    data(data(:,3)<1953.7,:) = [];
	data = [data precip(precip(:,3) >= min(data(:,3)) & precip(:,3) <= max(data(:,3)),4)];
	data = [data epot(epot(:,3) >= min(data(:,3)) & epot(:,3) <= max(data(:,3)),4)];
    
	%delete rows with NaN
	data(any(isnan(data),2),:) = [];
          
	SI(i).Id = i;
	SI(i).time = data(:,3);
	SI(i).discharge = data(:,4);
	SI(i).precip = data(:,5);
	SI(i).epot = data(:,6);
	SI(i).SDI = s_index(data(:,4),scale);
	SI(i).SPEI = s_index(1000+data(:,5)-data(:,6),scale); 
    SI(i).weight = ones(size(SI(i).time(:,1))).*mean(SI(i).discharge);
    
    all_data = [all_data ; SI(i).time SI(i).SPEI SI(i).SDI SI(i).weight];

    %mean SI for season (October to September):
	n_seasons = size(data,1)/12;
    season_data = [];
    for j = 1:n_seasons
        season_data = [season_data ;floor(SI(i).time((j-1)*12+5)) mean(SI(i).SPEI((j-1)*12+1:j*12)) mean(SI(i).SDI((j-1)*12+1:j*12)) mean(SI(i).weight((j-1)*12+1:j*12))]; 
    end    
    all_season_data = [all_season_data ; season_data];
    
    %select stations at (or close to) river mouth:
    if runoff_info(i,5) == 1     
        all_data_mouth = [all_data_mouth ; SI(i).time SI(i).SPEI SI(i).SDI SI(i).weight];
        all_season_data_mouth = [all_season_data_mouth ; season_data];
    end
              
end

all_data(any(isnan(all_data),2),:) = [];
all_season_data(any(isnan(all_season_data),2),:) = [];
all_season_data_mouth(any(isnan(all_season_data_mouth),2),:) = [];

%__________________________________________________________________________
%STATISTICS:

%calculate discharge weighted means for each month:
diff = [all_data(:,1) (all_data(:,3)-all_data(:,2))];

mean_mat = [];
for i = 1:size(time_v,1)
    
    weighted_mean_SPEI = sum(all_data(all_data(:,1) == time_v(i,3),2).*all_data(all_data(:,1) == time_v(i,3),4))./...
        sum(all_data(all_data(:,1) == time_v(i,3),4));
    
    weighted_mean_SDI = sum(all_data(all_data(:,1) == time_v(i,3),3).*all_data(all_data(:,1) == time_v(i,3),4))./...
        sum(all_data(all_data(:,1) == time_v(i,3),4));
    
    weighted_mean_ratio = sum(diff(diff(:,1) == time_v(i,3),2).*all_data(all_data(:,1) == time_v(i,3),4))./...
        sum(all_data(all_data(:,1) == time_v(i,3),4));
    
    number = sum(ismember(all_data(:,1),time_v(i,3)));

    mean_mat = [mean_mat ; time_v(i,3) weighted_mean_SPEI weighted_mean_SDI weighted_mean_ratio number];

end

mean_mat(any(isnan(mean_mat),2),:) = [];

%calculate discharge weighted means for each month (only stations close to river mouth):
diff = [all_data_mouth(:,1) (all_data_mouth(:,3)-all_data_mouth(:,2))]; 

mean_mat_mouth = [];
for i = 1:size(time_v,1)
    
    weighted_mean_SPEI = sum(all_data_mouth(all_data_mouth(:,1) == time_v(i,3),2).*all_data_mouth(all_data_mouth(:,1) == time_v(i,3),4))./...
        sum(all_data_mouth(all_data_mouth(:,1) == time_v(i,3),4));
    
    weighted_mean_SDI = sum(all_data_mouth(all_data_mouth(:,1) == time_v(i,3),3).*all_data_mouth(all_data_mouth(:,1) == time_v(i,3),4))./...
        sum(all_data_mouth(all_data_mouth(:,1) == time_v(i,3),4));
    
    weighted_mean_ratio = sum(diff(diff(:,1) == time_v(i,3),2).*all_data_mouth(all_data_mouth(:,1) == time_v(i,3),4))./...
        sum(all_data_mouth(all_data_mouth(:,1) == time_v(i,3),4));
    
    number = sum(ismember(all_data_mouth(:,1),time_v(i,3)));

    mean_mat_mouth = [mean_mat_mouth ; time_v(i,3) weighted_mean_SPEI weighted_mean_SDI weighted_mean_ratio number];

end

mean_mat_mouth(any(isnan(mean_mat_mouth),2),:) = [];

%Mann-Kendall test and Sen's slope:
%split by periods:
MKS_SPEI_mat = [];
MKS_SDI_mat = [];
for i = 1:length(periods)-1
    
    %SPEI
    [taubsea tausea Sens h sig sigAdj Zs Zmod Ss Sigmas CIlower CIupper] = ...
        sktt([time_v(time_v(:,3) >= periods(i) & time_v(:,3) < periods(i+1),1:2) ...
        mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),2)],alpha,wantplot,StartSeason);
    
    MKS_SPEI_mat = [MKS_SPEI_mat ; h Sens];
    
    %SDI
    [taubsea tausea Sens h sig sigAdj Zs Zmod Ss Sigmas CIlower CIupper] = ...
        sktt([time_v(time_v(:,3) >= periods(i) & time_v(:,3) < periods(i+1),1:2) ...
        mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),3)],alpha,wantplot,StartSeason);
    
    MKS_SDI_mat = [MKS_SDI_mat ; h Sens];
    
end

%Bootstrapping of linear correlation slope of STANDARDIZED INDICES:
%split by periods:
all_bootstat = [];
all_xi = [];
all_f = [];
all_bootstat_mouth = [];
all_xi_mouth = [];
all_f_mouth = [];
for i = 1:length(periods)-1
    
    %all
    bootstat = bootstrp(1000,@polyfit,mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),2),...
        mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),3),1);
    
    [f,xi] = ksdensity(bootstat(:,1)); 
    
    all_bootstat = [all_bootstat bootstat(:,1)];
    all_xi = [all_xi transpose(xi)];
    all_f = [all_f transpose(f)];
    
    %only mouth
    bootstat = bootstrp(1000,@polyfit,mean_mat_mouth(mean_mat_mouth(:,1) >= periods(i) & mean_mat_mouth(:,1) < periods(i+1),2),...
        mean_mat_mouth(mean_mat_mouth(:,1) >= periods(i) & mean_mat_mouth(:,1) < periods(i+1),3),1);
    
    [f,xi] = ksdensity(bootstat(:,1)); 
    
    all_bootstat_mouth = [all_bootstat_mouth bootstat(:,1)];
    all_xi_mouth = [all_xi_mouth transpose(xi)];
    all_f_mouth = [all_f_mouth transpose(f)];
        
end



%__________________________________________________________________________
%PLOT:

fig1 = figure(1);
set(fig1,'Position',[100 300 1100 540],'Color',[0.95 0.95 0.95],'InvertHardcopy','off');

%_______________

%top:
axesPosition = [50 280 1000 250];

ax1 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[1954.75 2016.75],'YLim',[-3 2.1],'XTick',periods,...
    'XTickLabels',{'Oct 65','Oct 69','Oct 90','Oct 94','Oct 01','Oct 12','Oct 16'},'YTick',[-1 0 1 2],...
    'FontSize',font_size,'NextPlot','add','Box','on');

hold on

a11 = area(ax1,mean_mat(:,1),movmean(mean_mat(:,2),12),0);
set(a11,'EdgeColor','none','FaceColor',[0 0 0],'FaceAlpha',0.5);

p11 = plot(ax1,mean_mat(:,1),movmean(mean_mat(:,3),12));
set(p11,'LineStyle','-','LineWidth',1.5,'Color',[1 0.3 0]);

p12 = plot(ax1,mean_mat_mouth(:,1),movmean(mean_mat_mouth(:,3),12));
set(p12,'LineStyle',':','LineWidth',1.5,'Color',[1 0.3 0]);

    %x-grid:
p13 = plot(ax1,[1965.75 1965.75 NaN 1969.75 1969.75 NaN 1990.75 1990.75 NaN 1994.75 1994.75 NaN ...
    2001.75 2001.75 NaN 2012.75 2012.75],[-0.6 3 NaN -0.6 3 NaN -3 3 NaN -3 3 NaN -3 3 NaN -3 3]);
set(p13,'LineStyle',':','LineWidth',1,'Color',[0 0 0]);

    %color line:   
patch(ax1,[periods(1) periods(2) periods(2) periods(1)],[-1.4 -1.4 -1 -1],color_periods(1,:),...
	'EdgeColor',[0 0 0],'FaceAlpha',0.3);
    
patch(ax1,[periods(2) 1973.75 1973.75 periods(2)],[-1.4 -1.4 -1 -1],color_periods(2,:),...
	'EdgeColor',[0 0 0],'FaceAlpha',0.3);

patch(ax1,[1973.75 1974 1974 1973.75],[-2.6 -2.6 -1 -1],color_periods(2,:),...
	'EdgeColor',[0 0 0],'FaceAlpha',0.3);

patch(ax1,[1973.75 periods(4) periods(4) 1973.75],[-3 -3 -2.6 -2.6],color_periods(2,:),...
	'EdgeColor',[0 0 0],'FaceAlpha',0.3);
    
for i = 3:length(periods)-1
    patch(ax1,[periods(i) periods(i+1) periods(i+1) periods(i)],[-3 -3 -2.6 -2.6],color_periods(i,:),...
        'EdgeColor',[0 0 0],'FaceAlpha',0.3);
end

x_postions = [1966.5 1977.9 1991.4 1996.6 2006.4 2013.5];

text(x_postions(1),-1.2,['Period 1'],'FontSize',font_size,'Color',[0 0 0]);

for i = 1:length(x_postions)
    text(x_postions(i),-2.8,['Period ',num2str(i)],'FontSize',font_size,'Color',[0 0 0]);
end 

    %frame
plot([1954.75 1973.75],[-1.4 -1.4],'Color',[0 0 0],'LineWidth',0.5);
plot([1973.75 1973.75],[-3 -1.4],'Color',[0 0 0],'LineWidth',0.5);

    %tick label
text(1964.55,-0.8,'Oct 65','FontSize',font_size,'Color',[0 0 0])
text(1968.55,-0.8,'Oct 69','FontSize',font_size,'Color',[0 0 0])



    %MKS text:
i = 1;
plot(x_postions(i)+0.2,1.95,'^','MarkerSize',10,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,1.95,sprintf('%0.2f',MKS_SPEI_mat(i,2)),'FontSize',font_size,'Color',[0 0 0])
plot(x_postions(i)+0.2,1.65,'^','MarkerSize',10,'MarkerFaceColor',[1 0.3 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,1.65,sprintf('%0.2f',MKS_SDI_mat(i,2)),'FontSize',font_size,'Color',[1 0.3 0]);

i = 2;
plot(x_postions(i)+0.2,-1.5,'o','MarkerSize',8,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.5,sprintf('%0.2f',MKS_SPEI_mat(i,2)),'FontSize',font_size,'Color',[0 0 0])
plot(x_postions(i)+0.2,-1.8,'o','MarkerSize',8,'MarkerFaceColor',[1 0.3 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.8,sprintf('%0.2f',MKS_SDI_mat(i,2)),'FontSize',font_size,'Color',[1 0.3 0]);

i = 3;
plot(x_postions(i)+0.2,-1.5,'^','MarkerSize',10,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.5,sprintf('%0.2f',MKS_SPEI_mat(i,2)),'FontSize',font_size,'Color',[0 0 0])
plot(x_postions(i)+0.2,-1.8,'^','MarkerSize',10,'MarkerFaceColor',[1 0.3 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.8,sprintf('%0.2f',MKS_SDI_mat(i,2)),'FontSize',font_size,'Color',[1 0.3 0]);

i = 4;
plot(x_postions(i)+0.2,-1.5,'v','MarkerSize',10,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.5,sprintf('%0.2f',MKS_SPEI_mat(i,2)),'FontSize',font_size,'Color',[0 0 0])
plot(x_postions(i)+0.2,-1.8,'v','MarkerSize',10,'MarkerFaceColor',[1 0.3 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.8,sprintf('%0.2f',MKS_SDI_mat(i,2)),'FontSize',font_size,'Color',[1 0.3 0]);

i = 5;
plot(x_postions(i)+0.2,-1.5,'o','MarkerSize',8,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.5,sprintf('%0.2f',MKS_SPEI_mat(i,2)),'FontSize',font_size,'Color',[0 0 0])
plot(x_postions(i)+0.2,-1.8,'v','MarkerSize',10,'MarkerFaceColor',[1 0.3 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.8,sprintf('%0.2f',MKS_SDI_mat(i,2)),'FontSize',font_size,'Color',[1 0.3 0]);

i = 6;
plot(x_postions(i)+0.2,-1.5,'o','MarkerSize',8,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.5,sprintf('%0.2f',MKS_SPEI_mat(i,2)),'FontSize',font_size,'Color',[0 0 0])
plot(x_postions(i)+0.2,-1.8,'o','MarkerSize',8,'MarkerFaceColor',[1 0.3 0],'MarkerEdgeColor','None');
text(x_postions(i)+1.1,-1.8,sprintf('%0.2f',MKS_SDI_mat(i,2)),'FontSize',font_size,'Color',[1 0.3 0]);

ylabel(ax1,'              Standardized Indices (SDI, SPEI)','FontSize',font_size,'FontWeight','n');

text(ax1,1955.1,1.86,'a','FontSize',16,'FontWeight','b');

hold off

leg1 = legend(ax1,[p11 p12 a11],'Standardized Discharge Index (SDI)','SDI (only stations close to river mouth)',...
    'Standardized Precipitation Evapotranspiration Index (SPEI)','Location',[0.774 0.904 0.05 0.05]);
set(leg1,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');

%_______________

%lower left:
axesPosition = [50 50 300 300];

ax2 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[-2.2 2.2],'YLim',[-2.2 2.2],'XTick',[-2 -1 0 1 2],'YTick',[-2 -1 0 1 2],...
    'FontSize',font_size,'NextPlot','add','Box','on');

hold on

for i = 1:length(periods)-1
    
    s21(i) = scatter(ax2,mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),2),...
        mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),3),20,'filled');
    set(s21(i),'MarkerFaceColor',color_periods(i,:));
 
end

for i = 1:length(periods)-1
    
    x = mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),2);
    y = mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),3);
    
    e21 = errorbar(mean(x),mean(y),mean(y)-min(y),max(y)-mean(y),mean(x)-min(x),max(x)-mean(x));
    set(e21,'LineWidth',1,'Color',color_periods(i,:));
  
end

p23 = plot([-2.5 2.5],[-2.5 2.5]);
set(p23,'LineWidth',1,'LineStyle','--','Color',[0 0 0]);

for i = 1:length(periods)-1
    
    p24 = plot(ax2,mean(mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),2)),...
        mean(mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),3)));
    set(p24,'LineStyle','None','Marker','o','MarkerEdgeColor',[0 0 0],'LineWidth',1,'MarkerFaceColor',[1 1 1],'MarkerSize',15);
    
    t21 = text(ax2,mean(mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),2))-0.035,...
        mean(mean_mat(mean_mat(:,1) >= periods(i) & mean_mat(:,1) < periods(i+1),3)),num2str(i));

end

xlabel(ax2,'SPEI','FontSize',font_size,'FontWeight','n');
ylabel(ax2,'SDI','FontSize',font_size,'FontWeight','n');

text(ax2,-2.13,2,'b','FontSize',16,'FontWeight','b');

text(ax2,1.68,2,'1:1','FontSize',font_size,'FontWeight','n');

    %plot for legend:    
pl21 = scatter(ax2,-100,-100,20,'filled');
set(pl21,'MarkerFaceColor',[0.5 0.5 0.5]); 
pl23 = plot(ax2,-100,-100);
set(pl23,'LineStyle','None','Marker','o','MarkerEdgeColor',[0 0 0],'LineWidth',1,'MarkerFaceColor',[1 1 1],'MarkerSize',13);

hold off

leg2 = legend(ax2,[pl21 pl23],['Discharge weighted',newline,'monthly means'],'Mean of periods','Location',[0.225 0.115 0.05 0.05]);
set(leg2,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');

%_______________

%lower middle:
axesPosition = [400 50 300 180];

ax3 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[0 1],'YLim',[0 14],'XTick',[-0.2 0 0.2 0.4 0.6 0.8 1],'YTick',[0 5 10],...
    'FontSize',font_size,'NextPlot','add','Box','on');

hold on

for i = 1:length(periods)-1
    
    p31 = plot(ax3,all_xi(:,i),all_f(:,i));
    set(p31,'Color',color_periods(i,:),'LineStyle','-','LineWidth',1.5);
    
    p32 = plot(ax3,all_xi_mouth(:,i),all_f_mouth(:,i));
    set(p32,'Color',color_periods(i,:),'LineStyle',':','LineWidth',2);
    
end

text(0.02,12,'c','FontSize',16,'FontWeight','b');

xlabel(ax3,'Slope of linear regression','FontSize',font_size,'FontWeight','n');
ylabel(ax3,'Probability density','FontSize',font_size,'FontWeight','n');

pl31 = plot(ax3,[-100 -90],[-100 -100],'Color',[0 0 0],'LineStyle','-','LineWidth',1.5);
pl32 = plot(ax3,[-100 -90],[-100 -100],'Color',[0 0 0],'LineStyle',':','LineWidth',2);

hold off

leg2 = legend(ax3,[pl31 pl32],'All discharge stations',['Only stations close',newline,'to river mouth'],'Location',[0.384 0.41 0.1 0.06]);
set(leg2,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');

%_______________

%lower right:
axesPosition = [750 50 300 180];

ax4 = axes('Units','pixels','Position',axesPosition,'Color',[1 1 1],'XColor',[0 0 0],'YColor',[0 0 0],...
    'XLim',[periods(1) periods(end)],'YLim',[0 6],'XTick',[1965.75 1990.75 2001.75 2016.75],'XTickLabel',...
    {'Oct 65','Oct 90','Oct 01','Oct 16'},'YTick',[0 1 2 3 4 5 6],'FontSize',font_size,'NextPlot','add','Box','on');

hold on

    %color line:
for i = 1:length(periods)-1
    patch(ax4,[periods(i) periods(i+1) periods(i+1) periods(i)],[0 0 0.3 0.3],color_periods(i,:),...
        'EdgeColor',[0 0 0],'FaceAlpha',0.3)
end

p41 = plot(ax4,capacity_v(:,1)+0.5,capacity_v(:,2)./1000);
set(p41,'Color',[0 0 0],'LineStyle','-','LineWidth',1.5);

p42 = plot(ax4,irrigation_a(:,1)+0.5,irrigation_a(:,2));
set(p42,'Color',[0.3 0.5 0.8],'LineStyle','-','LineWidth',1.5);

p43 = plot(ax4,irrigation_area(:,1)+0.5,irrigation_area(:,2)./1000);
set(p43,'Color',[0.3 0.8 0.3],'LineStyle','-','LineWidth',1.5);

    %x-grid:
p12 = plot(ax4,[1969.75 1969.75 NaN 1990.75 1990.75 NaN 1994.75 1994.75 NaN 2001.75 2001.75 NaN ...
    2012.75 2012.75],[0 6 NaN 0 6 NaN 0 6 NaN 0 6 NaN 0 6]);
set(p12,'LineStyle',':','LineWidth',1,'Color',[0 0 0]);

text(1967,4.2,'d','FontSize',16,'FontWeight','b');
    
hold off

leg4 = legend(ax4,[p41 p43 p42],'Dam capacity [km^3]','Irrigated area [10^3 km^2]',...
    ['Annual surface water consumption',newline,'for irrigation [km^3]'],'Location',[0.733 0.36 0.1 0.1]);
set(leg4,'EdgeColor',[0 0 0],'Color',[0.98 0.98 0.98],'FontSize',font_size,'FontWeight','n');



