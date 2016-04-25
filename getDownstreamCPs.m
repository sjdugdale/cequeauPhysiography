%% calculate downstream CPs
function downstreamCPs=getDownstreamCPs(rtable)
%GETDOWNSTREAMCPS Renumbers CPs based on routing, generates new routing table
%   Uses the 'rtable' variable from doRoutingTable.m function to identify
%   the CP immediately downstream of each CP
%
%   downstream=getDownstreamCPs(rtable)
%
%   Input: 'rtable'        - Routing table comprising the old ID of each CP, its new ID and the IDs of all CPs immediately upstream
%   
%   Output:'downstreamCPs'    - Vector comprising the ID of each CP immediately downstream of Nth CP
%           
%   By Stephen Dugdale, 2015-04-01

for n=1:size(rtable,1)
[idx col]=find(rtable(:,3:end)==rtable(n,2)); %find index of CP into which current CP drains using the upsteam routing grid 
if isempty(idx)
downstreamCPs(n,1)=0; %if current CP doesn't exist in upstream routing grid, it must therefore be the outlet.  set its value to zero   
else
downstreamCPs(n,1)=rtable(idx,2); %else, append the CP into which current CP drains as the downstream CP
end
end

end