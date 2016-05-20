format long;
Identifier = 'medium-100';
build = 'growth_cuda';
rscRadiiHist=h5read(strcat('refactor-stable-cuda-',Identifier,'-',build,'-output.h5'),'/radiiHistory');
fmrRadiiHist=h5read(strcat('forward-map-refactor-',Identifier,'-',build,'-output.h5'),'/radiiHistory');
[row,col]=find(rscRadiiHist-fmrRadiiHist);
diffRadiiHist = [row,col];

rscRatesHist=h5read(strcat('refactor-stable-cuda-',Identifier,'-',build,'-output.h5'),'/ratesHistory');
fmrRatesHist=h5read(strcat('forward-map-refactor-',Identifier,'-',build,'-output.h5'),'/ratesHistory');
[row,col]=find(rscRatesHist-fmrRatesHist);
diffRatesHist = [row,col];
