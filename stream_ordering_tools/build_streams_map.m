function streams_matrix = build_streams_map(dem_namefile) 

% declare global variables
% % -----------------------------------------------------------------------
global cell_size
global cell_area
global fdir_values
global sorting_type
global hierarchy_attribute
global min_drainage_area
global max_trib_order
global maxbase
global output_name
global dem_fill
global flowdir
global flowaccumulation
global flowdist
global strahler
global junctions_points
global internal_matrices
global id_river


mkdir('outputs');
mkdir('outputs\channel_network');
mkdir('outputs\csv');
addpath outputs/channel_network
addpath outputs/csv


% declare static variables, user must not change this!
% % -----------------------------------------------------------------------
max_trib_order                  = round(max_trib_order)+1; 
fdir_values                     = [2,1,128,4,100,64,8,16,32]; % directions of flowdir map
datetime                        = datestr(now,'dd_mmmm_yy_HH_MM_SS');
underscore                      = '_';
id_river                        = 0; 

% Schwanghart TopoTools 2 functions
% padding: adds two rows and columns to the DEM.Z matrix with NaN values
% % -----------------------------------------------------------------------

[~,ext]                         = strtok(dem_namefile,'.');
DEM                             = GRIDobj(dem_namefile); 
DEM.Z                           = [NaN(size(DEM.Z,1)+4,2) [NaN(2,size(DEM.Z,2)); DEM.Z ; NaN(2,size(DEM.Z,2))] NaN(size(DEM.Z,1)+4,2)];
DEM.size                        = [DEM.size(1)+4,DEM.size(2)+4];
DEMf                            = fillsinks(DEM);
DEMf.Z(DEMf.Z<=0)               = NaN; %replace 0 and arcmap nan values with NaN


FD                              = FLOWobj(DEMf, 'preprocess', 'fill');
FA                              = flowacc(FD); 
S                               = STREAMobj(FD,flowacc(FD)>1);

if strcmp(hierarchy_attribute ,'distance')
    DISTANCE                        = flowdistance(FD,S,'downstream');
    DISTANCE.Z(DISTANCE.Z<=0)       = NaN; %replace 0 and arcmap nan values with NaN
end

if strcmp(sorting_type,'horton')
    STRAHLER                        = streamorder(FD,flowacc(FD)>1,'strahler');
    stra                            = double(STRAHLER.Z);
    stra(stra<=0)                   = NaN; %replace 0 and arcmap nan values with NaN  
end

FDIR                            = FLOWobj2GRIDobj(FD);

disp 'internal matrices created';


% declare static variables user must not change
% % -----------------------------------------------------------------------
cell_size                       = DEM.cellsize;
cell_area                       = power(cell_size,2); % in square meters

% declare default values for optional parameters
% % -----------------------------------------------------------------------
if (isempty(min_drainage_area)         == 1)
    s=sign(DEM.Z); % signs DEM.Z
    ipositif=sum(s(:)==1);% computes positive elements
    min_drainage_area = ipositif * cell_area * 0.0001 ; % min area to be a stream
end

if (isempty(output_name) == 1)
    output_name                = strcat(DEM.name,underscore,sorting_type,underscore,hierarchy_attribute,underscore,num2str(max_trib_order-1),underscore,num2str(min_drainage_area),underscore, datetime);
end
% declare var matrices
% % -----------------------------------------------------------------------
dem_fill              = DEMf.Z; 
flowaccumulation      = FA.Z;
flowdir               = FDIR.Z;
if strcmp(hierarchy_attribute ,'distance')
    flowdist              = DISTANCE.Z;
elseif strcmp(hierarchy_attribute ,'accumulation')
    flowdist              = '';
end

if strcmp(sorting_type ,'horton')
    strahler              = stra;
elseif strcmp(sorting_type ,'hack')
    strahler              = '';
end

%  find outlets
% % -----------------------------------------------------------------------
if isempty(maxbase) == 0
    outlet                =S.IXgrid(S.distance==0);
    outlet_z              =outlet(DEM.Z(outlet)<maxbase);
else
    outlet_z              =S.IXgrid(S.distance==0);
end

clear S;
clear FD;


% generates NaN matrices same size of flowaccumulation matrix
% % -----------------------------------------------------------------------
streams_matrix      = NaN(size(flowaccumulation));
id_matrix           = NaN(size(flowaccumulation));
dist_matrix         = NaN(size(flowaccumulation));
outlet_matrix       = NaN(size(flowaccumulation));

for a = 1:numel(outlet_z)
    outlet_matrix(outlet_z(a)) = 1;
end

if strcmp(junctions_points,'yes')    
    junction_matrix     = NaN(size(flowaccumulation));
else
    junction_matrix     = [];
end

% loops through each outlet to extract and order each channel network
% % -----------------------------------------------------------------------
for item = 1:numel(outlet_z)    
    xy_junction_copy = outlet_z(item);    
    xy_area = flowaccumulation(xy_junction_copy)*cell_area;       
    if xy_area >= min_drainage_area    
        switch sorting_type
            case 'hack'
                order_junction_copy     = '';
            case 'horton'
                order_junction_copy     = strahler(xy_junction_copy);
        end

        % calls build_channelnetwork function
        % % -------------------------------------------------------------------
        [streams_matrix, id_matrix, dist_matrix, junction_matrix] = build_channel_network( xy_junction_copy, order_junction_copy, streams_matrix, id_matrix, dist_matrix, junction_matrix);

    end
end
% removes the padding 
% % -----------------------------------------------------------------------
streams_matrix      = streams_matrix(3:size(streams_matrix,1)-2,3:size(streams_matrix,2)-2); 
id_matrix           = id_matrix(3:size(id_matrix,1)-2,3:size(id_matrix,2)-2); 
dist_matrix         = dist_matrix(3:size(dist_matrix,1)-2,3:size(dist_matrix,2)-2); 
outlet_matrix       = outlet_matrix(3:size(outlet_matrix,1)-2,3:size(outlet_matrix,2)-2); 

if strcmp(junctions_points,'yes')    
    junction_matrix     = junction_matrix(3:size(junction_matrix,1)-2,3:size(junction_matrix,2)-2);
end

dem_fill            = dem_fill(3:size(dem_fill,1)-2,3:size(dem_fill,2)-2);
flowaccumulation    = flowaccumulation(3:size(flowaccumulation,1)-2,3:size(flowaccumulation,2)-2);
flowdir             = flowdir(3:size(flowdir,1)-2,3:size(flowdir,2)-2);
if strcmp(hierarchy_attribute ,'distance')
    flowdist        = flowdist(3:size(flowdist,1)-2,3:size(flowdist,2)-2);
end
if strcmp(sorting_type,'horton')
    strahler        = strahler(3:size(strahler,1)-2,3:size(strahler,2)-2);
end

% resize and turn matrices to GRIDobjs
% % -----------------------------------------------------------------------
DEMf.Z                          = dem_fill;
DEMf.size                       = [DEMf.size(1)-4,DEMf.size(2)-4];

FDIR.Z                          = flowdir;
FDIR.size                       = [FDIR.size(1)-4,FDIR.size(2)-4];

FA.Z                            = flowaccumulation;
FA.size                         = [FA.size(1)-4,FA.size(2)-4];

if strcmp(hierarchy_attribute ,'distance')
    DISTANCE.Z                  = flowdist;
    DISTANCE.size               = [DISTANCE.size(1)-4,DISTANCE.size(2)-4];
end

if strcmp(sorting_type,'horton')
    STRAHLER.Z                  = strahler;
    STRAHLER.size               = [STRAHLER.size(1)-4,STRAHLER.size(2)-4];
end

if strcmp(junctions_points,'yes')
    JUNCTIONS                   = FDIR;
    JUNCTIONS.Z                 = junction_matrix;
    JUNCTIONS.size              = FDIR.size;
end

STREAMS                         = FDIR;
STREAMS.Z                       = streams_matrix;
STREAMS.size                    = FDIR.size;

ID                              = FDIR;
ID.Z                            = id_matrix;
ID.size                         = FDIR.size;


% writes outputs to a ASCII 
% % -----------------------------------------------------------------------
GRIDobj2ascii(STREAMS,strcat('outputs/channel_network/',output_name,ext));
GRIDobj2ascii(ID,strcat('outputs/channel_network/',DEM.name,underscore,'id',underscore,datetime,ext));

if strcmp(internal_matrices ,'yes')
    mkdir('outputs\flow_related');
    addpath outputs/flow_related
    GRIDobj2ascii(FDIR,strcat('outputs/flow_related/',DEM.name,underscore,'flowdir',underscore,datetime,ext));
    GRIDobj2ascii(FA,strcat('outputs/flow_related/',DEM.name,underscore,'flowacc',underscore,datetime,ext));
    if strcmp(hierarchy_attribute ,'distance')
        GRIDobj2ascii(DISTANCE,strcat('outputs/flow_related/',DEM.name,underscore,'flowdist',underscore,datetime,ext));
    end
    if strcmp(sorting_type,'horton')
        GRIDobj2ascii(STRAHLER,strcat('outputs/flow_related/',DEM.name,underscore,'strahler',underscore,datetime,ext));
    end
end

if strcmp(junctions_points,'yes')
    mkdir('outputs\junctions');
    addpath outputs/junctions
    GRIDobj2ascii(JUNCTIONS,strcat('outputs/junctions/',DEM.name,underscore,'junctions',underscore,datetime,ext));
end

%clear variables
% % -----------------------------------------------------------------------
clear DEM;
clear FDIR;
clear FA;
clear ID;

% writes output to a .csv
% % -----------------------------------------------------------------------
xi = find(STREAMS.Z >0);
[x,y] = ind2coord(STREAMS,xi);

%  preallocating arrays
% % -----------------------------------------------------------------------
riv_value  = NaN(1,numel(xi));
z          = NaN(1,numel(xi));
acc_value  = NaN(1,numel(xi));
id_value   = NaN(1,numel(xi)); 
dis_value  = NaN(1,numel(xi));
out_value  = NaN(1,numel(xi));
jun_value  = NaN(1,numel(xi)); 


for i = 1:numel(xi)
    riv_value(i) = streams_matrix(xi(i));
    z(i)         = dem_fill(xi(i));
    acc_value(i) = flowaccumulation(xi(i));
    id_value(i)  = id_matrix(xi(i));
    dis_value(i) = dist_matrix(xi(i));
    out_value(i) = outlet_matrix(xi(i));
    if strcmp(junctions_points,'yes')
        jun_value(i) = junction_matrix(xi(i));
    end
end

area_value = acc_value.*cell_area;

%exports values to csv with no headers for arcmap
% % -----------------------------------------------------------------------
dlmwrite(strcat('outputs/csv/',output_name,'.csv'), [x y z' riv_value' acc_value' area_value' id_value' dis_value' jun_value' out_value'], 'precision', 8);



% %exports values to excel with headers 
% % -----------------------------------------------------------------------
% 
% filename = strcat('outputs/',DEM.name,'_map_',datetime,'.xls');
% A = {'x','y','z','value','accumulation','area','id','distance'};
% sheet = 1;
% xlRange = 'A1';
% xlswrite(filename,A,sheet,xlRange)
% 
% B = [x y z' riv_value' acc_value' area_value' id_value' dis_value'];
% sheet = 1;
% xlRange = 'A2';
% xlswrite(filename,B,sheet,xlRange)


% plots streams_matrix in MATLAB
% % -----------------------------------------------------------------------
figure('NumberTitle', 'off', 'Name', 'Stream-network');
imageschs(DEMf,streams_matrix, 'ticklabels','nice','colorbar',true,'exaggerate',10);

end