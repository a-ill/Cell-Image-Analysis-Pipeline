
umperpix = 0.0782; % um per pixel. Change that to scale properly
main_dir = "Batches\"; % Main folder
% You can specify folders in "Batches" that will be analysed, 
% by adding them to "folders_user"
folders_user = []; 
if isempty(folders_user)
  files= dir(main_dir);
  folders = files([files.isdir]);
  folders = folders(3:end);
  if isempty(folders)
    folders = "";
  else
    folders = arrayfun(@(x) string(x.name+"\"),folders);
  end
else
  folders = folders_user;
end

% Neural network preparation
load('NeuralNetwork\net.mat','net') 
layers = layerGraph(net);
layers = removeLayers(layers,'regressionoutput');
net = dlnetwork(layers);

% Main loop
for k = 1:length(folders)
  initial_dir = main_dir+folders(k);
  files= dir(initial_dir);
  subFolders = files([files.isdir]);
  subFolders = subFolders(3:end);
  if isempty(subFolders)
    subFolders = "";
  else
    subFolders = arrayfun(@(x) string(x.name+"\"),subFolders);
    if subFolders=="temp\"
      subFolders = "";
    end
  end
  for i = 1:length(subFolders)
    files2 = dir(strcat(initial_dir,subFolders(i)));
    subFolders2 = files2([files2.isdir]);
    subFolders2 = subFolders2(3:end);
    if isempty(subFolders2)
      subFolders2 = "";
    else
      subFolders2 = arrayfun(@(x) string(x.name+"\"),subFolders2);
      if subFolders2=="temp\"
        subFolders2 = "";
      end
    end
    for j = 1:length(subFolders2)
      dataDir = strcat(initial_dir,subFolders(i),subFolders2(j));
      detection(dataDir,net,umperpix);  
    end
  end
end