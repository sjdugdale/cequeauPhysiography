%% calculate cumulative percentage surface area for each CP
function [cumulPctSuperficieCPAmont upstreamCPs]=getCumulCPareas(allRoutes,pctSurface)
%GETCUMULCPAREA Computes cumulative percentage surface area stats for each CP
%   Calculates upstream percentage area of each CP using 'pctSurface'
%   variable from getCParea.m function and 'allRoutes' variable from
%   outletRoutes.m function which details all CPs downstream of Nth CP.
%
%   [cumulPctSuperficieCPAmont upstreamCPs]=getCumulCPareas(allRoutes,pctSurface)
%
%   Input:  'allRoutes'     - Table showing the downstream route (CP by CP) from the Nth CP to the basin outlet.  First column shows the starting CP, subsequent columns show the downstream route
%           'pctSurface'    - Vector of percentage surface areas that each CP contributes to its containing CE
%
%
%   Output: 'cumulPctSuperficieCPAmont'    - Vector of cumulative upstream percentage surface areas that CPs contributes to their containing CEs
%           'upstreamCPs'  - Matrix describing ALL CPs upstream of Nth CP (not just the immediately upstream ones)
%           
%   By Stephen Dugdale, 2015-04-01

for n=1:size(allRoutes,1);
    tempRoutes=allRoutes; %create temporary version of 'allRoutes'
    [row col]=find(tempRoutes==n); %find rows in tempRoutes containing Nth CP
    tempRoutes=tempRoutes(row,:);
    tempRoutes(tempRoutes<n)=[]; %eliminate downstream CPs
    tempRoutes=unique(tempRoutes); %get unique CPs
    upstreamCPs(n,1:numel(tempRoutes))=tempRoutes;
    CPareas=pctSurface(tempRoutes); %get areas of CPs
    cumulPctSuperficieCPAmont(n,1)=sum(CPareas); %append area to list
end

end
