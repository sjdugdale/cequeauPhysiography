%% renumber CPs based on routing and generate new routing table
function rtable=doRoutingTable(routing)
%DOROUTINGTABLE Renumbers CPs based on routing, generates new routing table
%   Uses the 'routing' variable from doCProuting.m function to generate a
%   new routing table.  CPs are renumbered based on their position upstream
%   (ie. the downstream-most CP is CP1).  All CPs immediately upstream of 
%   Nth CP are then entered into the routing table.
%
%   rtable=doRoutingTable(routing)
%
%   Input: 'routing'       - Routing table comprising the ID of each CP, the id of it's downstream neighbour and the coordinates of the outlet and inlet for the upstream and downstream CPs
%   
%   Output:'rtable'        - New routing table comprising the old ID of each CP, its new ID and the IDs of all CPs immediately upstream
%           
%   By Stephen Dugdale, 2015-04-01

%find index of exitoire in routing table
if any(routing(:,2)==0)
idx=find(routing(:,2)==0); %if outlet discharges into a zero cell (essentially, the remnant of a tiny CP that has been removed), set this as outlet
else    
idx=find((routing(:,1)-routing(:,2))==0); %else outlet is the only cell that discharges into itself
end

%create routing table and append outlet position to new table
rtable(1,1)=routing(idx,1); %append to new table
rtable(1,2)=1; %set new CP ID as one
routing(idx,2)=0; %set already traced CP ID in routing table to zero

for n=1:size(routing,1);    
idx=find(routing(:,2)==rtable(n,1)); %find CPs upstream of nth CP in rtable
routing(idx,2)=0; %set already traced CPs ID in routing table to zero

if ~(isempty(idx))
newtable(:,1)=routing(idx,1); %find CP ID of idx
newtable(:,2)=size(rtable,1)+1:size(rtable,1)+size(newtable,1); %renumber them based on length of rtable and number of upstream CPs

rtable(n,3:2+size(idx,1))=newtable(:,2)'; %append upstream CPs to rtable
rtable(size(rtable,1)+1:size(rtable,1)+size(newtable,1),1:2)=newtable; %append newtable to rtable
end

clear newtable
end

end