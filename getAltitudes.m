%% get DEM altitudes
function [CPalts CEalts]=getAltitudes(DEM,CPgrid,CEgrid,CElist)
%GETALTITUDES Extracts altitude data for all CEs and CPs
%   Uses the DEM to extract altitude data for the CEs and CPs (bottom left 
%   corner of CE for CEs and mean altitude for CPs.
%
%   [CPalts CEalts]=getAltitudes(DEM,CPgrid,CEgrid,CElist)
%
%   Input:  'DEM'           - Ditital Elevation Model of watershed.  Must have same dimensions/worldfile as CAT/FAC
%           'CPgrid'        - CPgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'CEgrid'        - CEgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'CElist'        - Vector of CEs sorted by (i,j) coordinate (sorted first based on i and then based on j)
%          
%   Output: 'CPalts'       - Vector of altitudes of bottom left coordinate of each CE
%           'CEalts'       - Vector of mean altitudes for each CP
%           
%   By Stephen Dugdale, 2015-04-01

%get CP altitudes
CPlist=unique(CPgrid(CPgrid>0)); %get list of CPs

h = waitbar(0,'Getting CE corner altitudes...');
for n=1:numel(CElist); %loop through CEs
    [row col]=find(CEgrid==CElist(n)); %find extent of Nth CP
    CEalts(n,1)=DEM(max(row),min(col)); %get value of DEM pixel in bottom left corner of CE (remember that in Matlab, pixel Y directions are flipped)
    waitbar(n / numel(CElist));%update waitbar
end
close(h);

%vectorise rasters for increased speed
DEM=DEM(:);
CPgrid=CPgrid(:);
CEgrid=CEgrid(:);

h = waitbar(0,'Getting average CP altitudes...');
for n=1:numel(CPlist);
    idx=find(CPgrid==CPlist(n)); %find vector location of Nth CP
    CPalts(n,1)=mean(DEM(idx)); %get mean altitudes at locations
    waitbar(n / numel(CPlist));%update waitbar
end
close(h);

end