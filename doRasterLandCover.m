%% get raster cover data
function [CPpctForet CPpctSolNu CEpctForet CEpctSolNu]=doRasterLandCover(LC, CPgrid, CEgrid, CElist)
%DORASTERLANDCOVER Extracts land cover data for CEs and CPs
%   Uses the CPgrid/CEgrid and land cover map to assemble land cover data
%   for the watershed.  %'LC' is landcover map from the North American Land
%   Change Monitoring System Land Cover 2010 database.  Download from 
%   http://www.cec.org/Page.asp?PageID=924&ContentID=2819&AA_SiteLanguageID=1
%
%   Map MUST be in UTM with EXACTLY the same zone and spatial extent as the 
%   DEM/FAC/CAT rasters.  Use the 'maintain clipping value' checkbox in 
%   ArcGIS when clipping the raster to ensure this.  However, pixel size 
%   can be different and will be resampled to match other rasters.
%
%   CEs don't have to add up to 100% land cover because they don't include 
%   bare soil (solNu).  However, CPs must add up to 100%.
%
%   [CPpctForet CPpctSolNu CEpctForet CEpctSolNu]=doRasterLandCover(LC, CPgrid, CEgrid, CElist)
%
%   Input:  'LC'            - Land cover data used to compute forest cover, bare soil.  Source is North American Land Change Monitoring System Land Cover 2010 database.
%           'CPgrid'        - CPgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'CEgrid'        - CEgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'CElist'        - Vector of CEs sorted by (i,j) coordinate (sorted first based on i and then based on j)
%          
%   Output: 'CPpctForet'    - Vector of percentage forest in CP
%           'CPpctSolNu'    - Vector of percentage bare soil in CP
%           'CEpctForet'    - Vector of percentage forest in CE
%           'CEpctSolNu'    - Vector of percentage base soil in CE
%           
%   By Stephen Dugdale, 2015-04-01

%resample LC raster to match resolution of CP/CE rasters
LC=imresize(LC,size(CPgrid),'nearest'); %use nearest-neighbour interpolation to ensure that land cover classes don't become non-integer

%get raster land use data
h = waitbar(0,'Getting raster land use data...');
CPpctForet=[]; %create empty vectors for CPpctForet, CPpctSolNu and CPlist
CPpctSolNu=[];
CPlist=[];
for n=1:numel(CElist);
    
    %Chop out Nth CE
    [row col]=find(CEgrid==CElist(n)); %find location of CE in CE grid
    CE=CEgrid(min(row):max(row),min(col):max(col)); %chop out Nth CE
    CE_CP=CPgrid(min(row):max(row),min(col):max(col)); %chop out CPs inside Nth CE
    CE_LC=LC(min(row):max(row),min(col):max(col)); %chop out LandCover == Nth CE
    
    %get land cover data
    CEpctForet(n,1)=(numel(CE_LC(CE_LC>=1 & CE_LC<=6))./numel(CE))*100; %get % forest in CE
    CEpctSolNu(n,1)=(numel(CE_LC((CE_LC>=7 & CE_LC<=13) | (CE_LC>=15 & CE_LC<=17)))./numel(CE))*100; %get percent sol nu inside CE
    
    %get CP vector land use data
    idx=unique(CE_CP(CE_CP>0));
    for m=1:numel(idx); %loop through CPs inside Nth CE
        
        %get LC inside CP
        CP_LC=CE_LC(CE_CP==idx(m)); %get Mth CP
        
        %calculate percentage area
        pctF=(numel(CP_LC(CP_LC>=1 & CP_LC<=6))./numel(CE_CP(CE_CP==idx(m))))*100; %get % forest in CP
        pctSN=(numel(CP_LC((CP_LC>=7 & CP_LC<=13) | (CP_LC>=15 & CP_LC<=17)))./numel(CE_CP(CE_CP==idx(m))))*100; %get % sol nu inside CP 
        
        %append data to vectors 
        CPpctForet=[CPpctForet;pctF];
        CPpctSolNu=[CPpctSolNu;pctSN];
        CPlist=[CPlist;idx(m)];
            
    end
    
    waitbar(n / numel(CElist));%update waitbar
end

%sort CPpctForet, CPpctSolNu vectors based on CPlist
temp=sortrows([double(CPlist) CPpctForet CPpctSolNu],1);
CPpctForet=temp(:,2);
CPpctSolNu=temp(:,3);

close(h);
end