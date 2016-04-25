%% remove small CP segments (merge with larger bits)
function CPgrid=removeCPsegments(CEgrid,CPgrid,FAC)
%REMOVECPSEGMENTS Removes small CP segments and merges with large CPs
%   Removes extremely small CP segments from CP grid (segments less than 1%
%   of CE size) and merges them with adjoining CPs.  Uses flow accumulation
%   raster to ensure that this merging is done in a hydrologically correct
%   manner.  This helps to ensure 4 CPs per CE.
%
%   CPgrid=removeCPsegments(CEgrid,CPgrid,FAC)
%
%   Input:  'CEgrid'        - Raster grid of arbitrarily numbered CEs. Same dimensions as FAC/CAT/DEM rasters
%           'CPgrid'        - Raster grid of arbitrarily numbered CPs. Same dimensions as FAC/CAT/DEM rasters
%           'FAC'           - Flow accumulation grid from ArcHydro Tools. Must be UTM projection.  Must be UTM, same zone as FAC/CAT/DEM rasters
%
%   Output: 'CPgrid'        - New CPgrid raster with small CPs removed. Same dimensions as FAC/CAT/DEM rasters
%
%   By Stephen Dugdale, 2015-04-01

%get size of the middle CE (no reason why it's the middle one, just less likely that it's one of the fraction CEs at the edges...)
CEsize=numel(find(CEgrid==round(max(CEgrid(:))./2)));

%get CPs smaller than 1% of CE size
idx=(min(CPgrid(CPgrid>0)):max(CPgrid(:)))';
count=histc(CPgrid,idx); %count unique values
count=sum(count,2);
miniCP=idx(count<ceil(CEsize.*0.01)); %get CPs smaller than 1% of CE size

%find CEs containing these CPs
containingCE=zeros(size(miniCP));
h = waitbar(0,'Detecting small CPs...');
for n=1:numel(miniCP);
    containingCE(n,1)=mode(CEgrid(CPgrid==miniCP(n)));
    FACval(n,1)=max(FAC(CPgrid==miniCP(n)));
    waitbar(n / numel(miniCP)) %update waitbar
end
close(h)



h = waitbar(0,'Merging small CPs...');
for n=1:numel(miniCP);  
    [row,col]=find(CEgrid==containingCE(n,1)); %extract CE containing CP
    CE_CP=CPgrid(min(row):max(row),min(col):max(col));
    mask=CE_CP==miniCP(n); %get miniCP
    outline=imdilate(mask,ones(3,3)); %dilate mask
	outline=outline.*(~(mask)); %get outline of mask
    subFAC=FAC(min(row):max(row),min(col):max(col)); %get FAC in CE
    subFAC=subFAC.*int32(outline);
    subFAClist=subFAC(logical(outline)); %get FAC values in outline
    
    if max(subFAClist)<0 %if no neighbours, set miniCP to zero, unless miniCP has FAC value <= 1% of CE
    CE_CP(CE_CP==miniCP(n))=0;
    if FACval(n)<(CEsize*0.01);CPgrid(min(row):max(row),min(col):max(col))=CE_CP;end
    
    elseif max(subFAClist)==0 %if neighbours with flow accumulation == 0, merge with biggest neighbouring CP
    outline=CE_CP(logical(outline));
    CE_CP(CE_CP==miniCP(n))=mode(outline);
    CPgrid(min(row):max(row),min(col):max(col))=CE_CP;
    
    else %merge with neighbouring CP with highest flow accumulation
    [in_row,in_col]=find(subFAC==max(subFAClist)); %find location of highest flow accumulation in outline of miniCP     
    CE_CP(CE_CP==miniCP(n))=mode(diag(CE_CP(in_row,in_col))); %get ID of CP containing
    CPgrid(min(row):max(row),min(col):max(col))=CE_CP; %set miniCP to ID of CP (merge)
    end
    waitbar(n / numel(miniCP)) %update waitbar
end
close(h)  
    
end
