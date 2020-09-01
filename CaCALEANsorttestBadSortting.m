%cont = dir('sample1.tif');
% cont = imread('sample1.tif');
fspec = '*.tif'; % specify file type to process
[fni, pni] = uigetfile(fspec, 'Select any image within the folder to be processed.');
tic % start run time clock, do this after user inputs
cont = dir([pni, fspec]);
n = length(cont);
% xytarray = zeros(1,n);
% size(xytarray)
meanvals = zeros(1,n);
Idenoised = zeros(1,n);
Bgr = zeros(1,n);
mask = zeros(1,n);
xyt_dim= [0.215,0.215,6.415];

file = struct2table(cont);
names = file(:,1);
% FileNameA = table2array(names);
% for i = 1:n
%  %attempting to switch to 8 bit within this for loop
%    FileA(i) = double(fopen(pni));
%    im1new(i) = uint8((FileA(i)/max(max(FileA(i))))* 255);     
% end
%Initialize logical variables
ismask = false(1,n);
isimage = false(1,n);
isbgr = false(1,n);
flag1 = zeros(1,n);
h1 = waitbar(0,'Reading images');
    
for i = 1 : n
    fntemp = cont(i).name;
    temp = imread([pni,fntemp]);
    k = size(temp);
    s = [k,n];
    % We know the images only have data in green; so, we only keep that
    % channel.
    if i == 1 % If 1st iteration
        [r,c, ch] = size(temp); % Obtain size of first frame
        xytarray = zeros(r,c,n); % Declare array for all frames
        % This is a 3D x-y-t array
    end        
    xytarray(:,:,i) = squeeze(temp(:,:,2));
    % Mean values of each frame
    meanvals(i) = mean(mean(squeeze(temp(:,:,2))));
    waitbar(i/n, h1, ['Reading images: ',num2str(i),'/',num2str(n),' completed.'])
end
close(h1)
h2 = waitbar(0,'Reading images');
%im write to these folders the outfour name is not correct 
if exist([pni,'\output']) ~= 7
    mkdir('bgr');
end
% create if statements for each of these 
mkdir('signal');
mkdir('bright');
mkdir('other');
SortArray = (n);
for i = 1 : n 
    %creates array of mask immages (brightest
%     if meanvals(i) > 71
%use quantile to sort the files by indensity in cdf
% quantile(meanArray,[.25,.5,.75,1]);
    File = string(FileNameA(i));
    if meanvals(i) > min(meanvals) + 0.9 * (max(meanvals) - min(meanvals))
        SortArray(i) = 1;
        imwrite(FileNameA(i),'TIFF');
    %array for data images and make for each if statement to read into the
    %folder
    elseif meanvals(i) > 70
        SortArray(i) = 2;
        imwrite(FileNameA,[fopen(File(i)),'\']);
    elseif meanvals(i) > min(meanvals) + 0.6 * (max(meanvals) - min(meanvals))
        SortArray(i) = 3;
        imwrite(imagearray,[pni,'\bright\FileNameA(i)'],'TIFF');
    %creates background images
    else 
        SortArray(i) = 4;
        imwrite(imagearray,[pni,'\other\FileNameA(i)'],'TIFF');
    end
    waitbar(i/n, h2, ['Sorting images: ',num2str(i),'/',num2str(n),' completed.'])
end
SortArrayF = SortArray';
%average background;
BgrAv = mean(mean(squeeze(isbgr(:,:))));        
close(h2)
% Vectorized version of calculating means of each frame
% meanvals = squeeze(mean(mean(xytarray,2),1));
figure(1)
hist(meanvals,0:255)
set(gca,'xlim',[0 255])
% mask = xytarray(:,:,flag1 == 3);
mask = xytarray(:,:,ismask);
Idenoised = xytarray(:,:,isimage);
Bgr = xytarray(:,:,isbgr);
CleanObj=CICRcleanSimp(Idenoised,Bgr,mask,xyt_dim,'ApparentDiffusionK',60,'CleanDiffusionK',30,'CaCleanThreshold',10);
figure(2)
subplot(1,3,1)
imagesc(CleanObj.CaRelease2D); axis image off; caxis([0,1500])
title('CaCLEANed CRU map')

subplot(1,3,2)
imagesc(membrane); axis image off; caxis([0,1500])
title('Deconvolved Cell Membrane')

G=CleanObj.CaRelease2D;
G=G/1500; G(G<0)=0; G(G>1)=1;

R=membrane; R=R/1500;
R(R<0)=0; R(R>1)=1;

R=G;
subplot(1,3,3)
imagesc(cat(3,R,G,zeros(size(G)))); axis image off
title('Merged Ca2+ Release Map and Cell Membrane')

t = toc;