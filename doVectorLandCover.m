%% get vector land cover data
function [CEpctCover,CPpctCover]=doVectorLandCover(CPgrid, CEgrid, CElist, R, shape)
%DOVECTORLANDCOVER Extracts land cover data for CEs and CPs
%   Uses the CPgrid/CEgrid and a shapefile of a given land cover class (eg.
%   water bodies, wetlands) to compute the percentage that that land cover
%   class contributes to the CPs/CEs.  

%   Input variable 'shape' is an ArcGIS shapefile structure containing 
%   polygons pertaining to waterbodies or wetlands (or other land cover 
%   types if necessary).  'shape' is loaded into Matlab using the Mapping 
%   Toolbox function shaperead.m).  
%
%   'shape' must be  in UTM, same zone as DEM/FAC/CAT from ArcHydro.  It
%   must also be of type 'polygon', NOT polygonZ or polygon ZM

%   Processing speed for this function is dramatically increased if the
%   polygons in shapefile do not have more than 500 vertices.  Use 'DICE' 
%   in ArcGIS to reduce number of vertices per polygon.
%
%   [CEpctCover,CPpctCover]=doVectorLandCover(CPgrid, CEgrid, CElist, R, shape)
%
%   Input:  'CPgrid'        - CPgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'CEgrid'        - CEgrid raster. Same dimensions as FAC/CAT/DEM rasters.
%           'CElist'        - Vector of CEs sorted by (i,j) coordinate (sorted first based on i and then based on j)
%           'R'             - Raster worldfile giving coordinate system of CAT/FAT/DEM rasters.  Loaded using worldfileread.m function of Matlab Mapping Toolbox
%           'shape'         - ESRI shapefile of specific land cover type within watershed (eg. water bodies, wetlands).  Must be in UTM projection, same zone as CAT/FAC/DEM
%          
%   Output: 'CEpctCover'    - Vector of percentage of that polygons in 'shape' contribute to surface area of CP
%           'CPpctCover'    - Vector of percentage of that polygons in 'shape' contribute to surface area of CE
%           
%   By Stephen Dugdale, 2015-04-01

%prepare shapefile
shapeX=[shape.X]';
shapeY=[shape.Y]';
%tic;

%get CE land cover data
h = waitbar(0,'Getting vector land cover data...');
CPlist=[];
CPpctCover=[];
for n=1:numel(CElist);
        
    %Chop out Nth CE
    [row col]=find(CEgrid==CElist(n)); %find location of CE in CE grid
    CE=CEgrid(min(row):max(row),min(col):max(col)); 
    CE_CP=CPgrid(min(row):max(row),min(col):max(col));
    
    %get x,y vector polygon for CE
    bCE=bwboundaries(CE);
    xCE=bCE{1}(:,2);
    yCE=bCE{1}(:,1);
    
    %add row,col to give true location of xCE, yCE
    xCE=xCE+min(col)-1;
    yCE=yCE+min(row)-1;
    
    %convert xCE, yCE to map coordinates
    [xCE,yCE] = pix2map(R,yCE,xCE);
    
    %do intersection and get % area
    [XshapeCE YshapeCE]=polybool('intersection',shapeX,shapeY,xCE,yCE);
    [XshapeCE_split YshapeCE_split] = polysplit(XshapeCE,YshapeCE); %split multipart polygons separated by NaNs
    
     %calculate area for multipart polygon (water) if polygon is not empty
     if ~isempty(XshapeCE_split)
                
     for nn = 1:numel(XshapeCE_split)
     shapeArea(nn,1) = polyarea(XshapeCE_split{nn},YshapeCE_split{nn});
     end

     %seperate polygon into surfaces (true) and holes (false) and subtract area of holes from area of surfaces
     cw=ispolycw(XshapeCE_split, YshapeCE_split);
     shapeArea=sum(shapeArea(cw))-sum(shapeArea(~(cw)));

     else
                
     shapeArea=0;
            
     end
    
     %calculate percentage area
     CEpctCover(n,1)=(shapeArea./polyarea(xCE,yCE))*100;
    
     %---------------------------------------------------------------------
     
        %get CP vector land use data
        idx=unique(CE_CP(CE_CP>0));
        for m=1:numel(idx);

            bCP=bwboundaries(CE_CP==idx(m)); %trace boundaries of Mth CP
            xCP=[]; %seed vectors
            yCP=[];

            %loop through if multiple boundaries and extract and convert to
            %vector polygon
            for mm=1:numel(bCP);
            
                %if bCP{m} is a line or point (due to CP only being a single pixel
                %or line of pixels), enlargen by 0.5 pix either side
                uX=numel(unique(bCP{mm}(:,2)));
                uY=numel(unique(bCP{mm}(:,1)));
                if uX==1 & uY>1
                midPoint=find(bCP{mm}(:,1)==max(bCP{mm}(:,1)));
                newTop=[bCP{mm}(1:midPoint,1) bCP{mm}(1:midPoint,2)-0.5];
                newBottom=[bCP{mm}(midPoint:end,1) bCP{mm}(midPoint:end,2)+0.5];
                bCP{mm}=[newTop;newBottom;newTop(1,:)];
                [bCP{mm}(:,2), bCP{mm}(:,1)] = poly2ccw(bCP{mm}(:,2), bCP{mm}(:,1));
                end
                if uY==1 & uX>1
                midPoint=find(bCP{mm}(:,2)==max(bCP{mm}(:,2)));    
                newTop=[bCP{mm}(1:midPoint,1)-0.5 bCP{mm}(1:midPoint,2)];
                newBottom=[bCP{mm}(midPoint:end,1)+0.5 bCP{mm}(midPoint:end,2)];
                bCP{mm}=[newTop;newBottom;newTop(1,:)];
                %[bCP{mm}(:,2), bCP{mm}(:,1)] = poly2ccw(bCP{mm}(:,2), bCP{mm}(:,1));
                end
                if uY==1 & uX==1
                tempY=bCP{mm}(1,1);
                tempX=bCP{mm}(1,2);
                bCP{mm}=[tempY+0.5,tempX-0.5;tempY+0.5 tempX+0.5;tempY-0.5 tempX+0.5;tempY-0.5 tempX-0.5;tempY+0.5 tempX-0.5]; 
                [bCP{mm}(:,2), bCP{mm}(:,1)] = poly2ccw(bCP{mm}(:,2), bCP{mm}(:,1));    
                end
                
            xCP=[xCP;bCP{mm}(:,2);NaN];
            yCP=[yCP;bCP{mm}(:,1);NaN];
            end

            %add row,col to give true location of xCP,yCP
            xCP=xCP+min(col)-1;
            yCP=yCP+min(row)-1;

            %convert xCP, yCP to map coordinates
            [xCP,yCP] = pix2map(R,yCP,xCP);

            %do intersection and get % area
            [XshapeCP YshapeCP]=polybool('intersection',XshapeCE,YshapeCE,xCP,yCP); %do intersection with previously extracted CE area
            [xCP_split yCP_split] = polysplit(xCP,yCP);
            [XshapeCP_split YshapeCP_split] = polysplit(XshapeCP,YshapeCP); %split multipart polygons separated by NaNs

            %calculate area for multipart polygon (CP)
            CParea = 0;
            for nn = 1:numel(xCP_split)
            CParea = CParea+polyarea(xCP_split{nn},yCP_split{nn});
            end
           
            %calculate area for multipart polygon (water) if polygon is not empty
            if ~isempty(XshapeCP_split)
                
            for nn = 1:numel(XshapeCP_split)
            shapeArea(nn,1) = polyarea(XshapeCP_split{nn},YshapeCP_split{nn});
            end

            %seperate polygon into surfaces (true) and holes (false) and subtract area of holes from area of surfaces
            cw=ispolycw(XshapeCP_split, YshapeCP_split);
            shapeArea=sum(shapeArea(cw))-sum(shapeArea(~(cw)));

            else
                
            shapeArea=0;
            
            end
            
            %calculate percentage area
            CPpctCover=[CPpctCover;(shapeArea./CParea)*100];
            CPlist=[CPlist;idx(m)];
            clear shapeArea CParea

        end
        
        %------------------------------------------------------------------
    
    waitbar(n / numel(CElist));%update waitbar
    %toc
end
close(h);

temp=sortrows([double(CPlist),CPpctCover],1);
CPpctCover=temp(:,2);

end