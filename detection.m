function detection(dataDir,net,umperpix,scale)

allowed_ext = [".bmp",".jpeg",".jpg",".png",".tif"];

% Detect file names
files = dir(dataDir);
files = files(~[files.isdir]);
filenames = cellfun(@string, {files.name});
filenames = filenames(arrayfun(@(x) any(contains(x,allowed_ext)),filenames));

% Check if temporary folder exists
if ~exist(strcat(dataDir,'temp'),'dir')
  mkdir(strcat(dataDir,'temp'))
end
% Check if temporary files exist. Skip if so
con = 0;
if ~exist(strcat(dataDir,'temp/masks.mat'),'file') 
  con = 1;
end
if con==1
  pics = cell(1,length(filenames));
  masks = cell(1,length(filenames));
  fields = cell(1,length(filenames));
  % Import pictures
  for i = 1:length(filenames) 
    pic = imread(strcat(dataDir,filenames(i))); 
    pic = im2single(rgb2gray(pic));
    pic = imresize(pic,scale);
    field = ~imdilate(imgaussfilt(single(pic<0.3),4)>0.5,ones(20));
    fields{i} = ~bwareaopen(~field,30000);
    pic = rescale(pic,-1,1);
    % Make size compatible with the neural network
    pic_size = size(pic);
    adj = (pic_size - floor(pic_size/16)*16)/2;
    pic = pic(1+adj(1):end-adj(1),1+adj(2):end-adj(2));
    pics{i} = pic;
  end
  % Detect features
  for i = 1:length(pics)
    mask = gather(extractdata(predict(net, ...
      gpuArray(dlarray(pics{i},'SSCB'))))>0.5);
    masks{i} = imresize(mask,1/scale);
  end
  % Save to temporary folder
  save(strcat(dataDir,'temp/masks.mat'),'masks');
end

%%
% Check if temporary files exist. Skip if so
con = 0;
if ~exist(strcat(dataDir,'temp/volumes.mat'),'file')
  con = 1;
end
% Feature refinement and volume, ratio calculations
if con==1
  if ~exist('masks','var')
    load(strcat(dataDir,'temp/masks.mat'),'masks');
  end
  volumes = cell(1,length(filenames));
  vacuole_volumes = cell(1,length(filenames));
  small_cutoff = 0.04*sum(size(masks{1}(:,:,1))); % Cutoff for small pieces
  parfor k = 1:length(filenames)  
    % Make temporary variables
    cells = masks{k}(:,:,1);
    border = masks{k}(:,:,2);
    vacuoles = masks{k}(:,:,3);
    % Refine border
    border = imgaussfilt(single(border),1.5)>0.5;
    skel_border = bwskel(border);
    border = imerode(border,ones(6)) | skel_border;
    % Connect small pieces that were incorrectly segmented
    small = bwareafilt(~bwskel(border),[0,small_cutoff],4);
    small = imdilate(small,ones(3));
    small_perim = bwperim(small);
    small(imdilate(small_perim,ones(4))) = 0;
    border(small) = 0;
    % Remove cells with bad borders and refine cell selection
    border_4C = bwconncomp(~border,4);
    stats = regionprops(border_4C,cells,'MeanIntensity','PixelIdxList');
    MeanIntensity = [stats.MeanIntensity];
    inds = MeanIntensity>0.7;
    cells_out = false(size(cells));
    cells_out(vertcat(stats(inds).PixelIdxList)) = 1;
    cells = cells_out & cells;
    cells = bwareaopen(cells,10,4);
    cells = imfill(cells,8,'holes');
    % Construct 3D models of cells and vacuole for volume calculation
    cells3D = func2Dto3D(cells);
    vacuoles3D = func2Dto3D(vacuoles);
    % Calculating volumes
    statsCells = regionprops(bwconncomp(cells,4),cells3D,'PixelValues');
    statsVacuoles = regionprops(bwconncomp(cells,4),vacuoles3D,'PixelValues');
    volumes{k} = half(cellfun(@(x) 2*sum(x)*(umperpix^3), ...
                      {statsCells(:).PixelValues}));    
    vacuole_volumes{k} = half(cellfun(@(x) 2*sum(x)*(umperpix^3), ...
                              {statsVacuoles(:).PixelValues}));
  end
  % Save to temporary folder
  save(strcat(dataDir,'temp/volumes.mat'),'volumes','vacuole_volumes');
end
fprintf('%s\n',strcat(dataDir, " was analysed."));

