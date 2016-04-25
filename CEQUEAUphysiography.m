function [bassinVersant,CEgrid,CPgrid,routing_data,CPcount,CEgrid_warning]=CEQUEAUphysiography(CAT,FAC,R,fishnet,force4CPs,DEM,LC,waterShape,wetlandShape) %% master function that controls structure generation and calls other functions 
%CEQUEAU_PHYSIOGRAPHY Generates CEQUEAU bassinVersant physiography data.
%   Master function that controls sub functions to generate CEQUEAU
%   physiography data for bassinVersant structure.  Deals with inputs and
%   outputs from various sub-functions.
%
%   [bassinVersant,CEgrid,CPgrid,rtable,CPcount,CEgrid_warning]=CEQUEAU_physiography(CAT,FAC,R,fishnet,force4CPs,DEM,LC,waterShape,wetlandShape)
%
%   Input:  'CAT'           - Catchment grid from ArcHydro Tools.  Must be UTM projection.
%           'FAC'           - Flow accumulation grid from ArcHydro Tools. Must be UTM projection.
%           'R'             - Raster worldfile giving coordinate system of CAT/FAT/DEM rasters.  Loaded using worldfileread.m function of Matlab Mapping Toolbox
%           'fishnet'       - polygon shapefile generated using ArcGIS 'fishnet' function where each square of fishnet is a CEQUEAU whole square (carreau entier)
%           'force4CPs'     - flag to force a maximum of 4 partial squares (CP) per whole square (CE).  1 if 4 CPs per CE is to be enforced, 0 if not.
%           'DEM'           - Ditital Elevation Model of watershed.  Must have same dimensions/worldfile as CAT/FAC
%           'LC'            - Land cover data used to compute forest cover, bare soil.  Source is North American Land Change Monitoring System Land Cover 2010 database.  Download from here: http://www.cec.org/Page.asp?PageID=924&ContentID=2819&AA_SiteLanguageID=1. Must have same dimensions and UTM projection (if not same resolution) as CAT/FAC/DEM.
%           'waterShape'    - ESRI shapefile of waterbodies within watershed.  Used to compute waterbody/lake cover.  Must be in UTM projection, same zone as CAT/FAC/DEM
%           'wetlandShape'  - ESRI shapefile of wetlands within watershed.  Used to compute wetland cover.  Must be in UTM projection, same zone as CAT/FAC/DEM
%
%   Output: 'bassinVersant' - CEQUEAU bassinVersant sub-structure
%           'CEgrid'        - Raster grid of CEs, same projection/resolution etc as CAT/FAC/DEM
%           'CPgrid'        - Raster grid of CPs, same projection/resolution etc as CAT/FAC/DEM
%           'CEgridwarning' - Raster grid of CEs that MAY have circular flow routing problems created if force4CPs flag is used.  Same projection/resolution etc as CAT/FAC/DEM.
%           'routing_data'  - Routing table showing relationship between all CPs
%           'CPcount'       - Raster grid of no. of CPs per CE.
%
%   By Stephen Dugdale, 2015-09-04

%convert grids to uint16/int32 to save memory
CAT=uint32(CAT);
CPgrid=uint32(zeros(size(CAT)));
CEgrid=uint32(zeros(size(CAT)));
FAC=int32(FAC);

%remove areas of FAC outside the extent of CAT
minFAC=mode(FAC(FAC<0));
if isnan(minFAC) | minFAC==0;
    minFAC=-2147483648;
end
FAC(CAT==0)=minFAC;

%do routing and data extraction
CEgrid=createCEgrid(CEgrid,fishnet,R); %1. create raster CE grid from fishnet
CPgrid=createCPgrid(CEgrid,CPgrid,CAT); %2. create raster CP grid by intersecting CAT with CEgrid
CPgrid=removeCPsegments(CEgrid,CPgrid,FAC); %3. get rid of small CP segments < 1% of CE size
CPgrid=removeFACzeroCPs(CEgrid,CPgrid,FAC); %3. merge CPs with maximum FAC value of zero
if force4CPs==1
[CEgrid_warning,CPgrid]=do4CPs(CEgrid,CPgrid,FAC); %3.5 find CEs containing more than 4 CPs and merge smaller CPs into larger ones
end
routing=doCProuting(CPgrid,FAC); %4. get routing from each CP to the next based on FAC raster
rtable=doRoutingTable(routing); %5. renumber CPs based on routing and generate new routing table
downstreamCPs=getDownstreamCPs(rtable); %6. figure out which CPs are downstream of each other
allRoutes=outletRoutes(rtable,downstreamCPs); %7. get routes from each CP to basin outlet
[pctSurface,containingCE,sizeCE]=getCPareas(rtable,CPgrid,CEgrid); %8. get pctSurface area for each CP
[cumulPctSuperficieCPAmont,upstreamCPs]=getCumulCPareas(allRoutes,pctSurface); %9. get cumulPctSuperficieCPAmont for each CP
CPgrid=redoCPgrid(rtable,CPgrid); %10. renumber CP grid
[CEgrid,idCE]=redoCEgrid(CEgrid,rtable,containingCE); %11. renumber CE grid based on flow routing for CPgrid
[iCP,jCP,iCE,jCE,CElist]=doCEcoordinates(CEgrid,idCE); %12. get I,J coordinates for CEs and CPs

%13. count number of CPs per CE and throw warning dialogue if there are too many
for n=1:max(idCE);
CPcount(n,1)=numel(find(idCE==n));  
end

if max(CPcount(:))>4;
   h=warning('Some CEs contain more than 4 CPs');
   uiwait(h);
   CEgrid_error=CEgrid;
   for n=1:numel(CPcount);
   if CPcount(n)>4    
   CEgrid_error(CEgrid_error==n)=9999;
   end
   end
   CEgrid_error(CEgrid_error>0 & CEgrid_error<9999)=1;
end

%14. get altitude data (if DEM has been supplied)
if exist('DEM');
[CPalts CEalts]=getAltitudes(DEM,CPgrid,CEgrid,CElist);
else
CPalts(1:size(rtable,1),1)=NaN;
CEalts(1:numel(CElist),1)=NaN;
end

%15. get raster land cover data (if LC raster has been supplied)
if exist('LC');
[CPpctForet CPpctSolNu CEpctForet CEpctSolNu]=doRasterLandCover(LC, CPgrid, CEgrid, CElist); %14. get raster land cover data
else
CPpctForet(1:size(rtable,1),1)=NaN;
CPpctSolNu(1:size(rtable,1),1)=NaN;
CEpctForet(1:numel(CElist),1)=NaN;
CEpctSolNu(1:numel(CElist),1)=NaN;
end

%16. get water bodies land cover data (if vector shapefile supplied)
if exist('waterShape');
[CEpctLacRiviere,CPpctEau]=doVectorLandCover(CPgrid, CEgrid, CElist, R, waterShape); %15. get vector land cover data
else
CPpctEau(1:size(rtable,1),1)=NaN;      
CEpctLacRiviere(1:numel(CElist),1)=NaN;
end

%17. get wetlands land cover data (if vector shapefile supplied)
if exist('wetlandShape');
[CEpctMarais,CPpctMarais]=doVectorLandCover(CPgrid, CEgrid, CElist, R, wetlandShape); %15. get vector land cover data
else
CPpctMarais(1:size(rtable,1),1)=NaN;      
CEpctMarais(1:numel(CElist),1)=NaN;
end 

%18. calculate cumulative data if all Land Cover data has been prepared
if exist('LC') & exist('waterShape') & exist('wetlandShape')

%rescale land cover percentages so they always add up to 100 (this is necessary due to the differences in resolution between the raster and vector datasets)    
CEpctVector=CEpctLacRiviere+CEpctMarais; CPpctVector=CPpctEau+CPpctMarais; %get total for vector land cover
CEpctRaster=CEpctForet+CEpctSolNu; CPpctRaster=CPpctForet+CPpctSolNu; %get total for raster land cover
CEpctSolNu=(CEpctSolNu./CEpctRaster).*(100-CEpctVector); CEpctForet=(CEpctForet./CEpctRaster).*(100-CEpctVector); %rescale raster CE values
CPpctSolNu=(CPpctSolNu./CPpctRaster).*(100-CPpctVector); CPpctForet=(CPpctForet./CPpctRaster).*(100-CPpctVector); %rescale raster CP values
CEpctSolNu(isnan(CEpctSolNu))=0; CEpctForet(isnan(CEpctForet))=0; CPpctSolNu(isnan(CPpctSolNu))=0; CPpctForet(isnan(CPpctForet))=0; %get rid of NaNs caused by 'divide-by-zero' errors

%get cumulative land cover data    
cumulPctForetAmont=getCumulLandCover(allRoutes,pctSurface,CPpctForet);
cumulPctLacsAmont=getCumulLandCover(allRoutes,pctSurface,CPpctEau);
cumulPctMaraisAmont=getCumulLandCover(allRoutes,pctSurface,CPpctMarais);
cumulPctSolNuAmont=getCumulLandCover(allRoutes,pctSurface,CPpctSolNu);
else
cumulPctForetAmont(1:size(rtable,1),1)=NaN;
cumulPctLacsAmont(1:size(rtable,1),1)=NaN;
cumulPctMaraisAmont(1:size(rtable,1),1)=NaN;
cumulPctSolNuAmont(1:size(rtable,1),1)=NaN;
end

%19. append all data to carreauxPartiels & carreauxEntiers and prepare bassinVersant structure
[carreauxPartiels,carreauxEntiers]=populateStructs(idCE,iCP,jCP,rtable,pctSurface,downstreamCPs,cumulPctSuperficieCPAmont,iCE,jCE,CPalts,CEalts,CPpctEau,CPpctForet,CPpctMarais,CPpctSolNu,cumulPctForetAmont,cumulPctLacsAmont,cumulPctMaraisAmont,cumulPctSolNuAmont,CEpctForet,CEpctLacRiviere,CEpctMarais,CEpctSolNu);
bassinVersant.nbCpCheminLong=size(allRoutes,2); %get maximum CP route length
bassinVersant.superficieCE=str2num(sprintf('%0.2f',(sqrt(mean(sizeCE)).*abs(R(1,2))./1000)^2)); %get area of 1 CE in km2 (based on worldfile for CAT/FAC/DEM)
bassinVersant.barrage=[]; %leave barrages variable empty
bassinVersant.nomBassinVersant='myWatershed'; %give watershed a generic name
bassinVersant.carreauxEntiers=carreauxEntiers; %append CEs
bassinVersant.carreauxPartiels=carreauxPartiels; %append CPs

%NB. Re. CP flow routing, In Marco's code, the CPs are ordered based on upstream area.  However,
%looking at Sebs' structure etc, this doesn't need to be the case.

%clean up
routing_data.CPs=rtable(:,2);
routing_data.downstreamNeighbours=downstreamCPs;
routing_data.upstreamNeighbours=rtable(:,3:end);
routing_data.allUpstreamCPs=upstreamCPs;
routing_data.downstreamRoutes=allRoutes;

end