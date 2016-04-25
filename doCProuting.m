%% loop through CPs, find outlet of each CP and find index of next CP into which CP drains
function routing=doCProuting(CPgrid,FAC)
%DOCEPROUTING Computes flow routing from each CP into the next
%   Uses the Arc Hydro flow accumulation raster to determine which CP flows
%   into which by identifying the outlet of each CP and the next CP into
%   which it drains
%
%   routing=doCProuting(CPgrid,FAC)
%
%   Input:  'CPgrid'        - Raster grid of arbitrarily numbered CPs. Same dimensions as FAC/CAT/DEM rasters
%           'FAC'           - Flow accumulation grid from ArcHydro Tools. Must be UTM projection.  Must be UTM, same zone as FAC/CAT/DEM rasters
%
%   Output: 'routing'       - Routing table comprising the ID of each CP, the id of it's downstream neighbour and the coordinates of the outlet and inlet for the upstream and downstream CPs
%
%   By Stephen Dugdale, 2015-04-22


%get unique index for grid
idx=unique(CPgrid);
idx(idx==0)=[];

%create empty routing table
routing=zeros(numel(idx),2);
routing(:,1)=idx;

%pad CPgrid and FAC to ensure that no CPs touch edge of raster
CPgrid=padarray(CPgrid,[1 1]);
FAC=padarray(FAC,[1 1]);

%figure out routings based on FAC
h = waitbar(0,'Computing routing table...');
for n=1:length(idx);
    [row,col]=find(CPgrid==idx(n));
    CP=CPgrid(min(row)-1:max(row)+1,min(col)-1:max(col)+1); %extract bounding box around Nth CP (with 1 pixel border)
    subFAC=FAC(min(row)-1:max(row)+1,min(col)-1:max(col)+1); %get bounding box around FAC in Nth CP (with 1 pixel border)
    subFAC_CP=subFAC.*int32(CP==idx(n)); %get FAC values ONLY in Nth CP (not in borders)
    [ex_row,ex_col]=find(subFAC_CP==max(subFAC_CP(:))); %get location of outlet of CP from FAC
    if numel(ex_row)>1
        for mm=1:numel(ex_row);
            mult_fac_val(mm)=subFAC_CP(ex_row(mm),ex_col(mm));
        end
        warning(['CP has multiple exits (mean flow accumulation of ',num2str(mean(mult_fac_val)),').  This occasionally occurs for extremely small CPs but should not cause problems.']);
        ex_row=ex_row(1);
        ex_col=ex_col(1);
    end
    mask=zeros(size(subFAC)); mask(ex_row-1:ex_row+1,ex_col-1:ex_col+1)=1; subFAC=subFAC.*int32(mask); %mask out 3x3 window around outlet
    [in_row,in_col]=find(subFAC==max(subFAC(:))); %find location of next pixel into which outlet flows
    if numel(in_row)>1
       in_row=in_row(1);
       in_col=in_col(1);
    end    
    routing(n,2)=CP(in_row,in_col); %use (ex_row,ex_col) to find idx of downstream CP and append to routing table
    routing(n,3:6)=[ex_row-1,ex_col-1,in_row-1,in_col-1]; %append coordinates of outlet and inlet to routing table
    waitbar(n / numel(idx)); %update waitbar
end
close(h)

end