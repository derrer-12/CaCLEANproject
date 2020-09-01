%% Acquire Files
clear
%cont = dir('sample1.tif');
% cont = imread('sample1.tif');
fspec = '*.tif'; % specify file type to process
[fni, pni] = uigetfile(fspec, 'Select any image within the folder to be processed.');
tic % start run time clock, do this after user inputs
cont = dir([pni, fspec]);
n = length(cont);

%% Preallocate and initialize

meanvals = zeros(1,n);
Idenoised = zeros(1,n);
Bgr = zeros(1,n);
mask = zeros(1,n);
xyt_dim = [0.215,0.215,6.415];

file = struct2table(cont);
names = file(:,1);
% Initialize logical variables
ismask = false(1,n);
isimage = false(1,n);
isbgr = false(1,n);
flag1 = zeros(1,n);
h1 = waitbar(0,'Reading images');

%% 
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
FileNameA = table2array(names);
h2 = waitbar(0,'Reading images');

% set up the histogram values for sorting
% normalize values of meanlals between 0 and 1
Vmin = min(meanvals);
Vmax = max(meanvals);
I = double(meanvals);
In = double((I - Vmin)/(Vmax-Vmin));
k = 1;
for i = 1 : n    
    %creates array of mask immages (brightest
    if In(i) > .2
        SortArray(i) = 1;
        i_mask = xytarray(:,:,1);
       % k = k+1;
    %array for data images
%     elseif meanvals(i) > 70
    elseif In(i) > .1 && In(i)<= .2
        %meanvals(i) > min(meanvals) + 0.6 * (max(meanvals) - min(meanvals))
        SortArray(i) = 2;
        i_image = xytarray(:,:,2);
    %creates background images
    else 
        SortArray(i) = 3;
        i_bgr = xytarray(:,:,3);
    end
    waitbar(i/n, h2, ['Sorting images: ',num2str(i),'/',num2str(n),' completed.'])
end

maxmask = squeeze(max(i_mask, [],3));
maximg = squeeze(max(i_image,[],3));
maxbgr = squeeze(max(i_bgr,[],3));

sub1 = maxmask-maxbgr;

figure
    subplot(311)
    image(maxmask)
    colorbar
    subplot(312)
    image(maximg)
    colorbar
    subplot(313)
    image(maxbgr)
    colormap jet
    linkaxes
    colorbar

% Sort the images based on the mean value array numbers

%create the directories to sort the data into
mkdir([pni,'SignalData']);
mkdir([pni,'BkgData']);
mkdir([pni,'MaskData']);
% pull from table to create name array
filenames = table2array(file(:,1));
for i = 1 : n
    name = [pni, char(filenames(i))];
    %create folders to sort into 
    if SortArray(i) == 1
        %unsure of how to use imwrite functon to put into each folder
        copyfile(name,[pni,'MaskData']);
        ismask(i) = 1;
    elseif SortArray(i) == 2 
        copyfile(name,[pni,'SignalData']);
        isimage(i) = 1;
    elseif SortArray(i) == 3
        copyfile(name,[pni, 'BkgData']);
        isbgr(i) = 1;
    end
end

SortArrayF = SortArray';
%average background;
BgrAv = mean(mean(squeeze(isbgr(:,:))));        
close(h2)
% Vectorized version of calculating means of each frame
% meanvals = squeeze(mean(mean(xytarray,2),1));
figure
hist(In,0:0.01:1)
set(gca,'xlim',[0 1])
% mask = xytarray(:,:,flag1 == 3);
mask = xytarray(:,:,ismask);
Idenoised = xytarray(:,:,isimage);
Bgr = xytarray(:,:,isbgr);
size(mask)
size(Idenoised)
size(Bgr)

CleanObj=CICRcleanSimp(Idenoised,Bgr,mask,xyt_dim,'ApparentDiffusionK',60,'CleanDiffusionK',30,'CaCleanThreshold',10);

figure
% subplot(1,3,1)

imagesc(CleanObj.CaRelease2D); axis image off; caxis([0,1500])
title('CaCLEANed CRU map')
% 
% G=CleanObj.CaRelease2D;
% G=G/1500; G(G<0)=0; G(G>1)=1;
% 
% % R=membrane6; R=R/1500;
% R(R<0)=0; R(R>1)=1;
% 
% R=G;
% subplot(1,3,3)
% imagesc(cat(3,R,G,zeros(size(G)))); axis image off
% title('Merged Ca2+ Release Map and Cell membrane6')


t = toc;