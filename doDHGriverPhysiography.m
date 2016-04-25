%% attributes river physiography data necessary to run CEQUEAUqualité
function bassinVersant=doDHGriverPhysiography(routing_Data,bassinVersant,barrageSuperficies)
%DODHGRIVERPHYSIOGRAPHY Computes length, width, depth and slope of river
%   Calculates length, width, depth and slope of river channel based on 
%   downstream hydraulic geometry relationships found in CEQUEAU
%   manual.  Uses CEQUEAU physiography structure and 'routingData'
%   structure outputted by CEQUEAUphysiography.m (found in routing_data.allUpstreamCPs)
%
%   See section D2 of CEQUEAU manual (p307) for correct units for
%   physiography
%
%   bassinVersant=getCumulCPareas(routingData,bassinVersant,barrageSuperficies)
%
%   Input:  'routingData'           - 'routingData' structure outputted by CEQUEAUphysiography.m.  Contains vector showing all CPs upstream of current CP.
%           'bassinVersant'         - CEQUEAU 'bassinVersant' model structure WITHOUT river physiography data
%           'barrageSuperficies'    - 1 x no. dams vector containing areas upstream of each dam.  ONLY NECESSARY IF DAMS present in system.           
%
%
%   Output: 'bassinVersant' - CEQUEAU 'bassinVersant' model structure WITH river physiography data
%           
%   By Stephen Dugdale, 2015-07-07

%if type 3 dams exist in structure, create 'CPareas' vector based on input
%'barrageSuperficies' vector.  If 'barrageSuperficies' vector is there,
%remind user to create it.
if isfield(bassinVersant.barrage,'type')
    if max([bassinVersant.barrage.type])==3 & nargin<3
    warndlg('Your structure contains type 3 dams.  Please ensure that you enter the area upstream of each dam in the relevant cell of "barrageSuperficies"','Warning!');
    elseif max([bassinVersant.barrage.type])==3 & nargin==3
    damCPareas=zeros(numel(bassinVersant.carreauxPartiels),1);    
    damCPareas([bassinVersant.barrage.idCP])=barrageSuperficies;
    end    
end

%extract table showing all CPs upstream of current CP from routingData structure
allUpstreamCPs=routing_Data.allUpstreamCPs;

%get surface areas (in km2) of each CP
CPareas=[bassinVersant.carreauxPartiels.pctSurface]'.*(bassinVersant.superficieCE./100);

%add CPareas and damCPareas to include the area upstream of each type 3 dam
if isfield(bassinVersant.barrage,'type')
CPareasDams=CPareas+damCPareas;
end

for n=1:size(allUpstreamCPs,1);
CPlist=allUpstreamCPs(n,:); %get list of CPs upstream of and including Nth CP
CPlist(CPlist==0)=[]; %remove zeros from list
sumCPareas(n,1)=sum(CPareasDams(CPlist)); %sum all CP areas contained within CP list 
end

%do DHG physiography based on equations from CEQUEAU manual
profondeurMin=(0.0198.*((sumCPareas).^0.53))*100; %calculated as function of upstream area (units = cm)
longueurCoursEauPrincipal=((CPareas).^0.5)*10; %calculated as function of current CP (units = 1/100 km)
largeurCoursEauPrincipal=(0.49.*((sumCPareas).^0.6))*10; %calculated as function of upstream area (units = 1/10m)
penteRiviere(1:numel(sumCPareas),1)=1000; %(units = 1/1000 metres/km)

for n=1:numel(bassinVersant.carreauxPartiels);
bassinVersant.carreauxPartiels(n).profondeurMin=profondeurMin(n);
bassinVersant.carreauxPartiels(n).longueurCoursEauPrincipal=longueurCoursEauPrincipal(n);
bassinVersant.carreauxPartiels(n).largeurCoursEauPrincipal=largeurCoursEauPrincipal(n);
bassinVersant.carreauxPartiels(n).penteRiviere=penteRiviere(n);
end
