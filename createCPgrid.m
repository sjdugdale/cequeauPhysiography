%% loop through grid, cut sub-basins into CPs and give random index
function CPgrid=createCPgrid(CEgrid,CPgrid,CAT)
%CREATECEPGRID Generates CEQUEAU CP grid
%   Generates CP grid raster from CEgrid and CAT, a catchment raster
%   generated from ArcHydro tools
%
%   CPgrid=createCPgrid(CEgrid,CPgrid,CAT)
%
%   Input:  'CEgrid'        - Raster grid of arbitrarily numbered CEs. Same dimensions as FAC/CAT/DEM rasters
%           'CPgrid'        - Raster of zeros with same dimensions as FAC/CAT/DEM rasters
%           'CAT'           - Catchment grid from ArcHydro Tools.
%
%   Output: 'CPgrid'        - Raster grid of arbitrarily numbered CPs. Same dimensions as FAC/CAT/DEM rasters
%
%   By Stephen Dugdale, 2015-04-01

rn=((max(CEgrid(:)))*8)+1; %numerator for CPs (basically, start at a point way higher than is possible for 4 CPs per CE). NB. I used to use a random number generator here, but a) it was slow and b) a bug in Matlab sometimes caused random numbers to appear twice which screwed up the CP routing

%get unique index for grid
idx=unique(CEgrid);
idx(idx==0)=[];

%loop through CE (whole squares)
h = waitbar(0,'Dividing CEs into CPs...');
for n=1:numel(idx);
    
%get nth CE
[row,col]=find(CEgrid==idx(n));

%get CAT inside CE (essentially, cut CAT using CE to make CP)
CE=CAT(min(row):max(row),min(col):max(col));

%get unique index for CP
idx2=unique(CE);
idx2(idx2==0)=[];

%loop through to determine unconnected components
% for m=1:numel(idx2);
% BW=bwlabel(CE==idx2(m));
% BW=BW.*rand;
% CE=CE+BW;
% end
% 
% %recompute unique index for CP
% idx2=unique(CE);
% idx2(idx2==0)=[];

%loop through CP within CE and randomly renumber
for m=1:numel(idx2);    
CE(CE==idx2(m))=rn; %assign current numerator value to CP within CE
rn=rn+1; %increase numerator by 1
end

%add CE to CP 
CPgrid(min(row):max(row),min(col):max(col))=CE; %stick CE chunk back into CP grid

%update waitbar
waitbar(n / numel(idx))
end
close(h)

end
