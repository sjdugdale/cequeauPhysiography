%% create raster CE grid from fishnet
function CEgrid=createCEgrid(CEgrid,fishnet,R)
%CREATECEGRID Generates CEQUEAU CE grid
%   Generates CE grid raster from fishnet shapefile produced using
%   'fishnet' function in ArcGIS.  
%
%   CEgrid=createCEgrid(CEgrid,fishnet,R)
%
%   Input:  'CEgrid'        - Raster of zeros with same dimensions as FAC/CAT/DEM rasters
%           'fishnet'       - Polygon shapefile generated using ArcGIS 'fishnet' function where each square of fishnet is a CEQUEAU whole square (carreau entier).  Must be UTM, same zone as FAC/CAT/DEM rasters
%           'R'             - Raster worldfile giving coordinate system of CAT/FAT/DEM rasters.  Loaded using worldfileread.m function of Matlab Mapping Toolbox
%
%   Output: 'CEgrid'        - Raster grid of arbitrarily numbered CEs. Same dimensions as FAC/CAT/DEM rasters
%
%   By Stephen Dugdale, 2015-04-01


h = waitbar(0,'Dividing basin into CEs...');
for n=1:size(fishnet,1);
    
%get CE squares and convert to pix coords    
[row,col] = map2pix(R,fishnet(n).X,fishnet(n).Y);

%resize squares that exceed raster size
col(col>size(CEgrid,2))=size(CEgrid,2); col(col<1)=1;
row(row>size(CEgrid,1))=size(CEgrid,1); row(row<1)=1;

%round down grid squares
row=floor(row);
col=floor(col);

%multiply each grid square by a random amount
CEgrid(min(row):max(row)-1,min(col):max(col)-1)=(CEgrid(min(row):max(row)-1,min(col):max(col)-1))+n;
waitbar(n / size(fishnet,1))
end
close(h)

end