%% get raster cover data
function tri_s=doImpermeableSurface(LC, CEgrid, CElist)
%DORASTERLANDCOVER Extracts impermeable surface fraction for CEs
%   Uses the CEgrid and land cover map to determine the fraction of each CE
%   that is impermeable. 'LC' is landcover map from the North American Land
%   Change Monitoring System Land Cover 2010 database.  Download from 
%   http://www.cec.org/Page.asp?PageID=924&ContentID=2819&AA_SiteLanguageID=1
%
%   Map MUST be in UTM with EXACTLY the same zone and spatial extent as the 
%   DEM/FAC/CAT rasters.  Use the 'maintain clipping value' checkbox in 
%   ArcGIS when clipping the raster to ensure this.  However, pixel size 
%   can be different and will be resampled to match other rasters.
%
%   tri_s=doImpermeableSurface(LC, CEgrid, CElist)
%
%   Input:  'LC'            - Land cover data used to compute forest cover, bare soil.  Source is North American Land Change Monitoring System Land Cover 2010 database.
%           'CEgrid'        - CEgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'CElist'        - Vector of CEs sorted by (i,j) coordinate (sorted first based on i and then based on j)
%          
%   Output: 'tri_s'         - Vector of impermeable surface fraction for each CE
%
%   By Stephen Dugdale, 2015-04-01

%resample LC raster to match resolution of CP/CE rasters
LC=imresize(LC,size(CEgrid),'nearest'); %use nearest-neighbour interpolation to ensure that land cover classes don't become non-integer

%get raster land use data
h = waitbar(0,'Getting impermeable surface data...');
tri_s=[]; %create empty vectors for tri_s

for n=1:numel(CElist);
    
    %Chop out Nth CE
    [row col]=find(CEgrid==CElist(n)); %find location of CE in CE grid
    CE=CEgrid(min(row):max(row),min(col):max(col)); %chop out Nth CE
    CE_LC=LC(min(row):max(row),min(col):max(col)); %chop out LandCover == Nth CE
    
    %get land cover data
    tri_s(n)=numel(CE_LC(CE_LC==17))./numel(CE);
      
    waitbar(n / numel(CElist));%update waitbar
end

close(h);
end