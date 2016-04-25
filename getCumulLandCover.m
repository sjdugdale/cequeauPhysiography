%% calculate cumulative percentage surface area for each CP
function cumulPctLandCover=getCumulLandCover(allRoutes,pctSurface,pctLandCover)
%GETCUMULLANDCOVER Computes cumulative percentage land cover stats for each CP
%   Calculates upstream percentage area of for a given land cover class
%   using 'pctSurface' variable from getCParea.m function and 'allRoutes' 
%   variable from outletRoutes.m function which details all CPs downstream 
%   of Nth CP.
%
%   [pctSurface,containingCE,sizeCE]=getCPareas(rtable,CPgrid,CEgrid)
%
%   Input:  'allRoutes'     - Table showing the downstream route (CP by CP) from the Nth CP to the basin outlet.  First column shows the starting CP, subsequent columns show the downstream route
%           'pctSurface'    - Vector of percentage surface areas that each CP contributes to its containing CE
%           'pctLandCover'  - Vector of percentage surface areas that given land cover class contributes to its containing CP
%
%   Output: 'cumulPctLandCover'    - Vector of cumulative upstream percentage surface areas that given land cover class contributes to its containing CPs
%           
%   By Stephen Dugdale, 2015-04-01

for n=1:size(allRoutes,1);
    tempRoutes=allRoutes; %create temporary version of 'allRoutes'
    [row col]=find(tempRoutes==n); %find rows in tempRoutes containing Nth CP
    tempRoutes=tempRoutes(row,:);
    tempRoutes(tempRoutes<n)=[]; %eliminate downstream CPs
    tempRoutes=unique(tempRoutes); %get unique CPs 
    CPareas=pctSurface(tempRoutes); %get areas of CPs
    LCareas=pctLandCover(tempRoutes);
    cumulPctLandCover(n,1)=sum(CPareas.*LCareas); %append area to list
end

end
