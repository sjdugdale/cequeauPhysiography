%% re-number CPgrid
function CPgrid=redoCPgrid(rtable,CPgrid)
%REDOCPGRID Renumbers CPgrid based on routing table (rtable)
%   Uses the 'rtable' variable from doRoutingTable.m function to renumber 
%   the CPgrid raster.  CPs are renumbered based on their position upstream
%   (ie. the downstream-most CP is CP1).
%
%   CPgrid=redoCPgrid(rtable,CPgrid)
%
%   Input: 'rtable'         - New routing table comprising the old ID of each CP, its new ID and the IDs of all CPs immediately upstream
%          'CPgrid'         - CPgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%   
%   Output:'CPgrid'         - Renumbered CPgrid raster. Same dimensions as FAC/CAT/DEM rasters. CPs are renumbered based on their position upstream (ie. the downstream-most CP is CP1).
%           
%   By Stephen Dugdale, 2015-04-01

h = waitbar(0,'Re-numbering CPs...');
for n=1:size(rtable,1);
    [row,col]=find(CPgrid==rtable(n,1)); %find CP in CPgrid
    CP=CPgrid(min(row):max(row),min(col):max(col)); %extract CP from CPgrid
    CP(CP==rtable(n,1))=rtable(n,2); %renumber CP
    CPgrid(min(row):max(row),min(col):max(col))=CP; %insert back into CPgrid
    waitbar(n / size(rtable,1)); %update waitbar
end
close(h);

end