addpath('matlab')
addpath('matlab/examples')
stateoutfile='forward-map-refactor-small-connected-growth-output'

close all;

global ratesHistory;
global radiiHistory;
global burstinessHist;
global spikesHistory;
global xloc;
global yloc;
global neuronTypes;
global neuronThresh;
global starterNeurons;      % 1 based indexing
global now;                 % read now from history dump
global Tsim;                % length of an epoch
global numSims;             % number of epochs
global numNeurons;
global xlen;
global ylen;
global INH;
global EXC;
global reg_peakpos;
global fColor;
global fShowDIV;            % true if show DIV
global sSec2Div;            % convert simulation sec to virtual DIV
global spikesProbedNeurons;
global attrPNUint;

INH = 1;
EXC = 2;

fColor=1;
fShowDIV=0;

%stateoutfile = 'historyDump';
ratesHistory = double((hdf5read([stateoutfile '.h5'], 'ratesHistory'))');
radiiHistory = double((hdf5read([stateoutfile '.h5'], 'radiiHistory'))');
burstinessHist = double((hdf5read([stateoutfile '.h5'], 'burstinessHist'))');
spikesHistory = double((hdf5read([stateoutfile '.h5'], 'spikesHistory'))');
xloc = double((hdf5read([stateoutfile '.h5'], 'xloc'))');
yloc = double((hdf5read([stateoutfile '.h5'], 'yloc'))');
neuronTypes = double((hdf5read([stateoutfile '.h5'], 'neuronTypes'))');
neuronThresh = double((hdf5read([stateoutfile '.h5'], 'neuronThresh'))');
starterNeurons = double((hdf5read([stateoutfile '.h5'], 'starterNeurons') + 1)');    % 1 based indexing
now = double(hdf5read([stateoutfile '.h5'], 'simulationEndTime'));    % read now from history dump
Tsim = double(hdf5read([stateoutfile '.h5'], 'Tsim'));                % read Tsim from history dump
%spikesProbedNeurons = double((hdf5read([stateoutfile '.h5'], 'spikesProbedNeurons'))');
%attrPNUint = h5readatt([stateoutfile '.h5'],'/spikesProbedNeurons','attrPNUint');

numSims = now / Tsim;
numNeurons = size(ratesHistory, 2);
xlen = sqrt(numNeurons);
ylen = xlen;
reg_peakpos(1)=0;
if fShowDIV
    sSec2Div = 40/(60*60*24);
else
    sSec2Div=1;
end

%for fE = 0.90:0.01:0.98
 %   for tR = 0.1:0.2:1.9
	%tR = 1.9;
	%fE = 0.90;
%       stateoutfile = ['tR_', num2str(tR, '%0.1f'),'--fE_', num2str(fE, '%1.2f')];
        [fig1, fig2, fig3, fig4, fig5] = growth2();
print(fig1,'fig1','-dpdf')
print(fig2,'fig2','-dpdf')
print(fig5,'fig5','-dpdf')
