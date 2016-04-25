%% remove small CP segments (merge with larger bits)
function CPgrid=removeFACzeroCPs(CEgrid,CPgrid,FAC)
%REMOTEFACZEROCPS Merges any CPs with zero flow accumulation with other nearby CPs
%   This function merges CPs containing zero FAC values with neighbouring
%   CPs to ensure that no 'plateau' CPs exist.
%
%
%   CPgrid=do4CPs(CEgrid,CPgrid,FAC)
%
%   Input:  'CEgrid'        - Raster grid of arbitrarily numbered CEs. Same dimensions as FAC/CAT/DEM rasters
%           'CPgrid'        - Raster grid of arbitrarily numbered CPs. Same dimensions as FAC/CAT/DEM rasters
%           'FAC'           - Flow accumulation grid from ArcHydro Tools. Must be UTM projection.  Must be UTM, same zone as FAC/CAT/DEM rasters
%
%   Output: 'CPgrid'        - New CPgrid raster zero FAC CPs merged into adjacent CPs. Same dimensions as FAC/CAT/DEM rasters
%          

%
%   By Stephen Dugdale, 2015-09-04

idx=unique(CEgrid);
idx(idx==0)=[];

h = waitbar(0,'Merging zero-FAC CPs...');
for n=1:numel(idx);
    
    %extract CE containing CP
    [row,col]=find(CEgrid==idx(n));
    CE_CP=CPgrid(min(row):max(row),min(col):max(col));
    
    %count number of CPs
    uniqueCP=double(unique(CE_CP));
    uniqueCP(uniqueCP==0)=[];
    
    if numel(uniqueCP)>0
    
    % get FAC in CE
    CE_FAC=FAC(min(row):max(row),min(col):max(col)); %get FAC in CE    
    
    maxFAC=[];
    %get maximum FAC values for CPs
    for m=1:numel(uniqueCP);
    maxFAC(m,1)=max(CE_FAC(CE_CP==uniqueCP(m)));
    end
    
    %if any zero FAC CPs exist
    if any(maxFAC==0)
    
    %get their index value
    CPidx=uniqueCP(maxFAC==0);
    
    for m=1:numel(CPidx);
     
        mask=CE_CP==CPidx(m); %mask out zero-FAC CP
        outline=imdilate(mask,ones(3,3)); %dilate mask
        outline=outline.*(~(mask)); %get outline of mask
        outline=CE_CP(logical(outline)); %get values of pixels along outline of mask
    
        newCP=mode(outline); %get modal value of pixels along outline.  This value will be the CP into which zero-FAC CP is merged
        
        %merge miniCP into neighbouring CP
        CE_CP(CE_CP==CPidx(m))=newCP;
    
    end
    end
    
    %put CE_CP back into CPgrid
    CPgrid(min(row):max(row),min(col):max(col))=CE_CP;
    
    end    
    
waitbar(n / numel(idx)) %update waitbar
end
close(h)  
    
end
