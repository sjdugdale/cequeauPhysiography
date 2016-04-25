%% get percentage surface area for each CP
function [pctSurface,containingCE,sizeCE]=getCPareas(rtable,CPgrid,CEgrid)
%GETCPAREAS Computes percentage surface area stats for each CP
%   Loops through CPs and calculates size of each CP.  Then calculates this
%   as a percentage of its containing CE.  Also creates a vector describing
%   the CE which contains each CP.
%
%   [pctSurface,containingCE,sizeCE]=getCPareas(rtable,CPgrid,CEgrid)
%
%   Input:  'rtable'        - Routing table comprising the old ID of each CP, its new ID and the IDs of all CPs immediately upstream
%           'CPgrid'        - Raster grid of arbitrarily numbered CPs. Same dimensions as FAC/CAT/DEM rasters
%           'CEgrid'        - Raster grid of arbitrarily numbered CEs. Same dimensions as FAC/CAT/DEM rasters

%   Output: 'pctSurface'    - Vector of percentage surface areas that each CP contributes to its containing CE
%           'containingCE'  - Vector showing the CE that contains each CP
%           'sizeCE'        - Vector of CE sizes (in pixels)
%           
%   By Stephen Dugdale, 2015-04-01

containingCE=zeros(size(rtable,1),1);
sizeCP=zeros(size(rtable,1),1);
sizeCE=zeros(size(rtable,1),1);

h = waitbar(0,'Getting CP sizes...');
%tic;
for n=1:size(rtable,1);
    idx=find(CPgrid==rtable(n,1)); sizeCP(n,1)=numel(idx); %get index of Nth CP and calculate size
    containingCE(n,1)=mode(CEgrid(idx)); %get index of CE that contains it
    idx=find(CEgrid==containingCE(n,1)); sizeCE(n,1)=numel(idx); %calculate size of containing CE
    %toc
    waitbar(n / size(rtable,1));%update waitbar
end
close(h);

sizeCE(sizeCE<0.95.*max(sizeCE))=max(sizeCE);
pctSurface=(sizeCP./sizeCE)*100;

%for cumulPctSuperficieCPAmont, value is simply the sum of pctSurface for
%all upstream CPs + current CP

%for cumulPctSuperficieForetAmont etc, value is sum(pctSurface.*pctForet) for all
%upstream CPs + current CP

end