%% remove small CP segments (merge with larger bits)
function [CEgrid_warning,CPgrid]=do4CPs(CEgrid,CPgrid,FAC)
%DO4CPS Ensures no more than 4 CPs per CE
%   For CEs containing more than 4 CPs, this function merges the smallest 
%   CPs with adjoining CPs.  Uses flow accumulation raster to ensure that 
%   this merging process is done in a hydrologically correct manner. 
%   This function forces 4 CPs per CE, and may very occasionally cause
%   circular flow routing problems.
%
%   If this is the case, it will be necessary to re-compute the size of CEs
%   and catchment delineation in ArcHydro tools, as it means that it in its
%   current configuration, the watershed cannot have less than 4 CPs per
%   CE.
%
%   CPgrid=do4CPs(CEgrid,CPgrid,FAC)
%
%   Input:  'CEgrid'        - Raster grid of arbitrarily numbered CEs. Same dimensions as FAC/CAT/DEM rasters
%           'CPgrid'        - Raster grid of arbitrarily numbered CPs. Same dimensions as FAC/CAT/DEM rasters
%           'FAC'           - Flow accumulation grid from ArcHydro Tools. Must be UTM projection.  Must be UTM, same zone as FAC/CAT/DEM rasters
%
%   Output: 'CPgrid'        - New CPgrid raster with a maximum of 4CPs per CE. Same dimensions as FAC/CAT/DEM rasters
%           'CEgridwarning' - Raster grid of CEs that MAY have circular flow routing problems created if force4CPs flag is used.  Same projection/resolution etc as CAT/FAC/DEM.

%
%   By Stephen Dugdale, 2015-04-01

CEgrid_warning=zeros(size(CPgrid));
idx=unique(CEgrid);
idx(idx==0)=[];

h = waitbar(0,'Forcing 4 CPs...');
for n=1:numel(idx);
    
    %extract CE containing CP
    [row,col]=find(CEgrid==idx(n));
    CE_CP=CPgrid(min(row):max(row),min(col):max(col));
    
    %count number of CPs
    uniqueCP=double(unique(CE_CP));
    uniqueCP(uniqueCP==0)=[];
    
    if numel(uniqueCP)>4
    
    % get FAC in CE
    CE_FAC=FAC(min(row):max(row),min(col):max(col)); %get FAC in CE    
     
    %get maximum FAC values for CPs
    for m=1:numel(uniqueCP);
    maxFAC(m,1)=max(CE_FAC(CE_CP==uniqueCP(m)));
    end
    
    %get size of CPs    
    area=histc(CE_CP,uniqueCP);
    area=sum(area,2);
    
    area=sortrows([area uniqueCP]);
    CPidx=area(1:end-4,2);
    
    for m=1:numel(CPidx);
     
        mask=CE_CP==CPidx(m); %get miniCP
        outline=imdilate(mask,ones(3,3)); %dilate mask
        outline=outline.*(~(mask)); %get outline of mask
        subFAC=CE_FAC.*int32(outline);
        subFAClist=subFAC(logical(outline)); %get FAC values in outline
    
        if max(subFAClist)<0 %if no neighbours, set miniCP to zero
        warndlg('CP has no neighbours...','Warning!');
        end
        %newCP=0;    
        
        if max(subFAClist)==0 %if neighbours with flow accumulation == 0, merge with biggest neighbouring CP
        outline=CE_CP(logical(outline));
        newCP=mode(outline); %get ID of CP containing
        
        elseif max(subFAClist)>0 %merge with neighbouring CP with highest flow accumulation
        [in_row,in_col]=find(subFAC==max(subFAClist)); %find location of highest flow accumulation in outline of miniCP
        newCP=mode(diag(CE_CP(in_row,in_col))); %get ID of CP containing
        end
              
        %if miniCP contains FAC values greater than CP into which it is being merged...
        if maxFAC(uniqueCP==newCP)<maxFAC(uniqueCP==CPidx(m))
        CEgrid_warning(min(row):max(row),min(col):max(col))=1; %essentially, if a small CP is merged into another that has a lower FAC value, there is a chance that a circular flow routing problem will occur    
        warning(['CP being merged has higher flow accumulation (',num2str(maxFAC(uniqueCP==CPidx(m))),') than the one into which it is being merged (',num2str(maxFAC(uniqueCP==newCP)),').']);   
        end
        
        %merge miniCP into neighbouring CP
        CE_CP(CE_CP==CPidx(m))=newCP;
    
    end
    
    %put CE_CP back into CPgrid
    CPgrid(min(row):max(row),min(col):max(col))=CE_CP;
    
    end    
    
waitbar(n / numel(idx)) %update waitbar
end
close(h)  
    
end
