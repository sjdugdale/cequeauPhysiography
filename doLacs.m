%% get vector land cover data
function lac=doLacs(CPgrid, R, shape)
%DOLACS Creates binary vector of big lake presence or absence
%   Creates a 'lac' vector for use in CEQUEAU inputStruct.parametres.lac
%   containing binary 1s where a large lake (defined as a lake that
%   extends over more than one CP) is present and 0 when there are no lakes
%
%   Input variable 'shape' is an ArcGIS shapefile structure containing 
%   polygons pertaining lakes (or other land cover 
%   types if necessary).  'shape' is loaded into Matlab using the Mapping 
%   Toolbox function shaperead.m).  
%
%   'shape' must be  in UTM, same zone as DEM/FAC/CAT from ArcHydro.  It
%   must also be of type 'polygon', NOT polygonZ or polygon ZM

%   Processing speed for this function is dramatically increased if the
%   polygons in shapefile do not have more than 500 vertices.  Use 'DICE' 
%   in ArcGIS to reduce number of vertices per polygon.
%
%   lac=doLacs(CPgrid, R, shape)
%
%   Input:  'CPgrid' - CPgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'R'      - Raster worldfile giving coordinate system of CAT/FAT/DEM rasters.  Loaded using worldfileread.m function of Matlab Mapping Toolbox
%           'shape'  - ESRI shapefile of large lakes within watershed (eg. water bodies, wetlands).  Must be in UTM projection, same zone as CAT/FAC/DEM
%          
%   Output: 'lac'    - Vector of binary presence/absence of lakes per CP
%           
%   By Stephen Dugdale, 2015-05-07

%create CPlist
CPlist=unique(CPgrid);
CPlist(CPlist==0)=[];
lac=zeros(1,numel(CPlist));

%loop through lakes in shapefile
h = waitbar(0,'Creating large lake binary vector...');

for n=1:numel(shape);
     
    %chop out X and Y vectors for Nth shape
    shapeX=[shape(n).X]';
    shapeY=[shape(n).Y]';
    
    %convert shape coordinates to pixel space
    [shapeY,shapeX] = map2pix(R,shapeX,shapeY);

    %split polygon based on NaNs
    [shapeX shapeY] = polysplit(shapeX,shapeY); %split multipart polygons separated by NaNs
    cw=ispolycw(shapeY,shapeX); %reverse shapeY and shapeX for the ispolycw operation because they've been converted to pixel space
    poly_nonhole=find(cw==1); %find non-hole objects;
    poly_hole=find(cw==0); %find hole objects;
    
    %loop through non-hole polygon parts and convert to mask
    mask_nonhole=zeros(size(CPgrid)); %create empty mask
    for nn = 1:numel(poly_nonhole)
    tempX=shapeX{poly_nonhole(nn)}; %get x and y vectors for first polygon segment
    tempY=shapeY{poly_nonhole(nn)};
    mask_nonhole=mask_nonhole|poly2mask(tempX,tempY,size(CPgrid,1),size(CPgrid,2)); %add segment to mask
    end
    
    %loop through holes and convert to mask
    mask_hole=zeros(size(CPgrid)); %create empty mask
    for nn = 1:numel(poly_hole)
    tempX=shapeX{poly_hole(nn)}; %get x and y vectors for first polygon segment
    tempY=shapeY{poly_hole(nn)};
    mask_hole=mask_hole|poly2mask(tempX,tempY,size(CPgrid,1),size(CPgrid,2)); %add segment to mask
    end

    mask=mask_nonhole~=mask_hole; %combine masks to get a raster representation of vector lake with islands
    CPs=CPgrid(mask);
    CPs(CPs==0)=[];
    lac(unique(CPs))=1;
    
    waitbar(n / numel(shape));%update waitbar
    
end

close(h);


% set 'lac' value for CP1 = 0 (CEQUEAU bugs if not)
lac(1)=0;

end