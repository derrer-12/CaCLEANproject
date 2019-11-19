close all
clear
A = imread('sample1.tif');
save('myTiff2mat','A');
load myTiff2mat.mat

Idenoised = A;
Bgr = A;
[r,c,f] = size(A);
Mask = true(r,c);
xyt_dim= [0.215,0.215,6.415];

CleanObj=CICRcleanSimp(Idenoised,Bgr,Mask,xyt_dim,'ApparentDiffusionK',60,'CleanDiffusionK',30,'CaCleanThreshold',10);
%CleanObj=CICRcleanSimp(A,A,A,A,'ApparentDiffusionK',60,'CleanDiffusionK',30,'CaCleanThreshold',10);

%% Display the sample data.
subplot(1,3,1)
imagesc(CleanObj.CaRelease2D); axis image off; caxis([0,1500])
title('CaCLEANed CRU map')

subplot(1,3,2)
imagesc(membrane); axis image off; caxis([0,1500])
title('Deconvolved Cell membrane')

G=CleanObj.CaRelease2D;
G=G/1500; G(G<0)=0; G(G>1)=1;

R=membrane; R=R/1500;
R(R<0)=0; R(R>1)=1;

R=G;
subplot(1,3,3)
imagesc(cat(3,R,G,zeros(size(G)))); axis image off
title('Merged Ca2+ Release Map and Cell membrane')


%% Rebuild the upstroke from the CaCLEAN results and put it in the field "CICRrebuilt".
CleanObj=CICRrebuildSimp(CleanObj);