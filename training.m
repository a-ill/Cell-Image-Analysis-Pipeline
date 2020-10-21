
%% Prepare training data

main_dir = "TrainingData/";
dataDir = "TrainingData/Images/";
pxDir = "TrainingData/Labels/";
s = 160; % Target size
if ~exist("TrainingData/TrainMasks",'dir')
  mkdir("TrainingData/TrainMasks")
end
if ~exist("TrainingData/TrainImages",'dir')
  mkdir("TrainingData/TrainImages/")
end

allowed_ext = [".bmp",".jpeg",".jpg",".png",".tif",".tiff"];

files = dir(pxDir+"Images");
files = files(~[files.isdir]);
filenames = cellfun(@string, {files.name});
filenames = filenames(arrayfun(@(x) any(contains(x,allowed_ext)),filenames));
files = dir(strcat(dataDir));
files = files(~[files.isdir]);
filenamesImg = cellfun(@string, {files.name});
filenamesImg = filenamesImg(arrayfun(@(x) any(contains(x,allowed_ext,'IgnoreCase',true)),filenamesImg));
imgs_names = cellfun(@(x) x(1), arrayfun(@(x) split(x,'.'),filenamesImg,'UniformOutput',false));
labels_names = cellfun(@(x) x(1), arrayfun(@(x) split(x,'.'),filenames,'UniformOutput',false));
names = intersect(imgs_names,labels_names);
[~,inds] = intersect(imgs_names,names);
filenamesImg = filenamesImg(inds);
[~,inds] = intersect(labels_names,names);
filenames = filenames(inds);
cnt = 1;
for i = 1:length(filenames)

  tempname = char(filenames(i));
  tempname = tempname(1:end-4);
  
  pic = im2single(rgb2gray(imread(dataDir+filenamesImg(i))));
  field = ~imdilate(imgaussfilt(single(pic<0.3),4)>0.5,ones(20));
  field = ~bwareaopen(~field,30000);
  pic(~field) = 0;
  pic(isnan(pic)) = 0;
  pic = rescale(pic,-1,1);
  
  [labelimg,~,tr] = imread(strcat(pxDir,'Images/',filenames(i)));
  labelimg(repmat(~tr,1,1,3)) = 0;
  label = zeros([size(labelimg(:,:,1)),3],'single');
  label(:,:,1) = labelimg(:,:,2)==255;
  border = imdilate(bwperim(label(:,:,1)),ones(3));
  border(label(:,:,1)==1) = 0;
  border = imdilate(border,ones(5));
  label(:,:,2) = border & field;
  label(:,:,3) =  labelimg(:,:,1)==255;
  for j=1:3
    label(:,:,j) = label(:,:,j) & field;
  end
  saveLabel(main_dir,tempname,label) 

  angles = 0:30:330; % angles for augmentation
 for g = 1:length(angles) 
  pic2 = imrotate(pic,angles(g),'bicubic');
  label2 = imrotate(label,angles(g),'bicubic');   
  mult1 = floor(size(label2,1)/150);
  mult2 = floor(size(label2,2)/150);
  step1 = floor(size(label2,1)/mult1);
  step2 = floor(size(label2,2)/mult2);
   
 for h = 1:2
   if h==1
     pic3 = pic2;
     label3 = label2;
   elseif h==2
     pic3 = fliplr(pic2);
     label3 = fliplr(label2);
   end
   for j = 1:mult1-1
      for k = 1:mult2-1
        ymin = (j-1)*step1+1;
        xmin = (k-1)*step2+1;
        I2 = label3(ymin:ymin+s-1,xmin:xmin+s-1,:);
        if sum(logical(I2(:,:,1)),'all')<2560
          continue
        end       
        I1 = pic3(ymin:ymin+s-1,xmin:xmin+s-1,:);
        saveI(main_dir,cnt,I1,I2)
        cnt = cnt+1;
      end
   end
 end
 end
end
clear 

%% Initialisation
addpath("NeuralNetwork")
imDir = "TrainingData/TrainImages";
pxDir = "TrainingData/TrainMasks";
imds = imageDatastore(imDir,'ReadFcn',@importdata,'FileExtensions','.mat');
pxds = imageDatastore(pxDir,'ReadFcn',@importdata,'FileExtensions','.mat');
trainingData = combine(imds,pxds);  
addpath("NeuralNetwork")
load('net.mat','net');
layers = layerGraph(net);

%% Training

% Options for training
opts = trainingOptions('adam', ...
    'InitialLearnRate',1e-3, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.8, ...
    'LearnRateDropPeriod',1, ...
    'MaxEpochs',50, ...
    'MiniBatchSize',10, ...
    'Shuffle','every-epoch', ...
    'ResetInputNormalization', false, ...
    'Plots','training-progress', ...
    'VerboseFrequency',100);
  
[net,~] = trainNetwork(trainingData,layers,opts,nnGPU('Precision','half'));
save('NeuralNetwork\net2.mat','net'); % saving neural network


%% Testing
i = 1; % File index
allowed_ext = [".bmp",".jpeg",".jpg",".png",".tif"];
files = dir("TrainingData/Images/");
files = files(~[files.isdir]);
filenames = cellfun(@string, {files.name});
filenames = filenames(arrayfun(@(x) any(contains(x,allowed_ext, ...
  'IgnoreCase',true)),filenames));

pic = im2single(rgb2gray(imread(strcat("TrainingData/Images/",filenames(i)))));
pic = imresize(pic,0.5);
% Make size compatible with the neural network
pic_size = size(pic);
adj = (pic_size - floor(pic_size/16)*16)/2;
pic = pic(1+adj(1):end-adj(1),1+adj(2):end-adj(2));
% Run the neural network
layers = layerGraph(net);
layers = removeLayers(layers,'regressionoutput');
C = gather(forward(dlnetwork(layers),gpuArray(dlarray(pic,'SSCB'))));
C = extractdata(C);

% Prepare and visualise results
cells = C(:,:,1)>0.5;
border = C(:,:,2)>0.5;
vacuoles = C(:,:,3)>0.5;
img = uint8(cells);
img(border) = 2;
img(vacuoles) = 3;
B = labeloverlay(pic,img); 
imshow(B)  






