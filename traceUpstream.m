function river = traceUpstream(FAC,pRow,pCol)
%TRACEUPSTREAM Traces river upstream from point on FAC
%   Uses flow accumulation raster to trace a river as far upstream as
%   possible from a point given by (row,col)

neighbourhood=FAC(pRow-1:pRow+1,pCol-1:pCol+1);
seedVal=FAC(pRow,pCol);
river=zeros(size(FAC,1),size(FAC,2));
river(pRow,pCol)=1;

while seedVal>1 & numel(seedVal)==1 & sum(neighbourhood(neighbourhood<seedVal))>0
neighbourhood(neighbourhood==seedVal)=1;    
neighbourhood=neighbourhood-seedVal;
neighbourhood(neighbourhood>0)=-inf;
[qRow qCol]=find(neighbourhood==max(neighbourhood(:)));

pRow=pRow+(qRow-2);
pCol=pCol+(qCol-2);
neighbourhood=FAC(pRow-1:pRow+1,pCol-1:pCol+1);
seedVal=FAC(pRow,pCol);
river(pRow,pCol)=1;
end

