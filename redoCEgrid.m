%% re-number CE grid based on CP routing
function [CEgrid idCE]=redoCEgrid(CEgrid,rtable,containingCE)
%REDOCEGRID Renumbers CEgrid based on routing table (rtable)
%   Uses the 'rtable' variable from doRoutingTable.m function and 
%   'containingCE' from getCPareas.m function to renumber the CEgrid 
%   raster.
%
%   [CEgrid idCE]=redoCEgrid(CEgrid,rtable,containingCE)
%
%   Input:  'CEgrid'        - CEgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'rtable'        - New routing table comprising the old ID of each CP, its new ID and the IDs of all CPs immediately upstream
%           'containingCE'  - Vector showing the CE that contains each CP
%          
%   Output: 'CEgrid'        - Renumbered CEgrid raster. Same dimensions as FAC/CAT/DEM rasters. CEs are renumbered based on the position upstream of the CPs contained within them (ie. the CE containing CP1 is CE1).
%           'idCE'          - The ID of the CE in which each CP is contained (essentially a new version of 'containingCE' variable)
%           
%   By Stephen Dugdale, 2015-09-04


%add 2x maximum size to CEgrid so that the selective numbering doesn't
%screw up
mCE=double(max(CEgrid(:)));
CEgrid=CEgrid+(2.*mCE);
CEgrid(CEgrid==min(CEgrid(:)))=0;
containingCE=containingCE+(2.*mCE);

%create empty list of already changed CEs
donelist=[];

%create increment
m=1;

h = waitbar(0,'Renumbering CEs based on CP routing...');
for n=1:size(rtable,1);
    if any(donelist==containingCE(n))  %if CE has already been renumbered...  
    idCE(n,1)=mode(idCE(donelist==containingCE(n))); %...find the relevant new number in idCE and append
    else %if it hasn't yet been renumbered...
    idCE(n,1)=m; %...set its number as the current increment
    donelist(n,1)=containingCE(n); %append this CE to the list of CEs that have already been renumbered
    CEgrid(CEgrid==containingCE(n))=m;
    m=m+1; %increase the increment by 1
    end
    waitbar(n / size(rtable,1));%update waitbar
end
close(h);

CEgrid(CEgrid>max(idCE(:)))=0;

end