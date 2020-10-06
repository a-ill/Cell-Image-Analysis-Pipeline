
% Directories where to look for files
main_dir = 'Batches\';
% You can specify folders in "Batches" that will be analysed, 
% otherwise, all are analysed
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
num_folders = length(folders);
last_dir_repl = true; % Are the last folders replicates?
%Define variables
volumes = cell(1,num_folders);
vacuoles = cell(1,num_folders);
vacuoles_per_bin = cell(1,num_folders);
fr_out = cell(1,num_folders);
fr_vac_out = cell(1,num_folders);
entries_out = cell(1,num_folders);
num_cells_out = cell(1,num_folders);
num_vacs_out = cell(1,num_folders);
ratio_out = cell(1,num_folders);
ratio_edges_out = cell(1,num_folders);
max_cell_volume = 3000;
max_vac_volume = 1000;
bins_cell_volume = 800;
bins_vac_volume = 4000;
% Main loop
for k = 1:length(folders)
  initial_dir = main_dir+folders(k)+"\";
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
  volumes{k} = cell(1,length(subFolders));
  vacuoles{k} = cell(1,length(subFolders));
  vacuoles_per_bin{k} = cell(1,length(subFolders));
  for l = 1:length(subFolders)
    files= dir(initial_dir+subFolders(l));
    subFolders2 = files([files.isdir]);
    subFolders2 = subFolders2(3:end);
    if isempty(subFolders2)
      subFolders2 = "";
    else
      subFolders2 = arrayfun(@(x) string(x.name+"\"),subFolders2);
      if subFolders2=="temp\"
        subFolders2 = "";
      end
    end
    for i = 1:length(subFolders2)
      data = load(strcat(initial_dir,subFolders(l),subFolders2(i),...
        '\temp\volumes.mat'),'volumes','vacuole_volumes');
      V = single([data.volumes{:}]);
      V_vac = single([data.vacuole_volumes{:}]);
      volumes{k}{l} = [volumes{k}{l},V];
      vacuoles{k}{l} = [vacuoles{k}{l},V_vac];
    end
  end
  % Define entries names based on folders' names
  if last_dir_repl
    entries = subFolders';
  else
    entries = subFolders2';
  end
  for i = 1:length(entries)
    temp = char(entries(i));
    entries(i) = string(temp(1:end-1));
  end
  % Defining and preallocating variables
  fr = cell(1,length(entries));
  fr_vac = cell(1,length(entries)); 
  num_cells = zeros(1,length(entries),'single');
  num_vacs = zeros(1,length(entries),'single');
  % x axis values for histogram construction
  edges = linspace(0,max_cell_volume,bins_cell_volume);
  edges_vac = linspace(0,max_vac_volume,bins_vac_volume);
  % Loop for calculations
  for l = 1:length(entries)
    % Remove vacuole volume values, where cell/vacuole ratio is smaller than the value
    coef = 0.02; 
    inds = find((vacuoles{k}{l}./volumes{k}{l})>coef);
    vacuoles{k}{l} = vacuoles{k}{l}(inds);
    temp_volumes = volumes{k}{l}(inds);
    % Get cell and vacuole volume frequency histograms
    h = histogram(volumes{k}{l},edges,'Normalization','probability');
    num_cells(l) = length(volumes{k}{l});
    fr{l} = h.Values;
    h = histogram(vacuoles{k}{l},edges_vac,'Normalization','probability');
    fr_vac{l} = h.Values;
    % Get vacuole volume per cell volume bin
    temp = zeros(1,length(fr{l}));
    num_vacs(l) = length(vacuoles{k}{l});
    for j = 1:length(fr{l})-1
      temp(j) = mean(vacuoles{k}{l}(vacuoles{k}{l} & temp_volumes<edges(j+1) & temp_volumes>edges(j)));
    end
    vacuoles_per_bin{k}{l} = temp';
    % Get vacuole to cell volume ratios
    cnt_last = 1;
    cnt = 0;
    ind = 1;
    temp = zeros(1,length(edges),'single');
    temp_edges = zeros(1,length(edges),'single');
    temp2 = 0;
    min_num_cells = 30; % Minimum number of accumulated cells to make a bin
    while cnt<length(fr{l})
      while cnt<length(fr{l}) && sum(temp2)<min_num_cells
        cnt = cnt + 1;
        temp2 = temp_volumes>edges(cnt_last) & temp_volumes<edges(cnt);
      end
      if sum(temp2)>=min_num_cells
        temp(ind) = median(vacuoles{k}{l}(temp2)./temp_volumes(temp2));
        temp_edges(ind) = median(edges(cnt_last:cnt));
        cnt_last = cnt+1;
        ind = ind + 1;
        temp2 = 0;
      else
        break
      end
    end
    temp = temp(1:ind-1);
    temp_edges = temp_edges(1:ind-1);
    ratio_out{k}{l} = temp;
    ratio_edges_out{k}{l} = temp_edges;
  end
  entries_out{k} = entries;
  fr_out{k} = fr;
  fr_vac_out{k} = fr_vac;
  num_cells_out{k} = num_cells;
  num_vacs_out{k} = num_vacs;
end
close all

%% Saving cell numbers
entries = [entries_out{:}];
% Cells
data = [num_cells_out{:}];
save_data = [num2cell(entries);num2cell(data)];
writecell(save_data,'num_cells.xlsx');
% Vacuoles
data = [num_vacs_out{:}];
save_data = [num2cell(entries);num2cell(data)];
writecell(save_data,'num_vacs.xlsx');

%% Saving volume distributions
entries = [entries_out{:}];
% Cell volume distributions
edges = linspace(0,max_cell_volume,bins_cell_volume);
edges = mean([edges(1:end-1);edges(2:end)])';
data = [fr_out{:}]';
data = vertcat(data{:})';
save_data = [num2cell(['V',entries]);num2cell([edges,data])];

writecell(save_data,'data_volumes.xlsx');

% Volume per cell volume bin distributions
edges = linspace(0,max_cell_volume,bins_cell_volume);
edges = mean([edges(1:end-1);edges(2:end)])';
data = [vacuoles_per_bin{:}];
data = horzcat(data{:});
save_data = [num2cell(['V',entries]);num2cell([edges,data])];

writecell(save_data,'data_volume_vs_vacuoles.xlsx');

% Vacuole volume distributions
edges = linspace(0,max_vac_volume,bins_vac_volume);
edges = mean([edges(1:end-1);edges(2:end)])';
data = [fr_vac_out{:}]';
data = vertcat(data{:})';
save_data = [num2cell(['V',entries]);num2cell([edges,data])];

writecell(save_data,'data_vacuoles.xlsx');

%% Saving median and standard deviations
% Calculating mode and standard deviations
avg_volumes = cell(1,length(volumes));
dev_volumes = cell(1,length(volumes));
avg_vacuoles = cell(1,length(vacuoles));
dev_vacuoles = cell(1,length(vacuoles));
for k = 1:length(volumes)
    fr_in = [fr_out{k}{:}];
    fr_vac_in = [fr_vac_out{k}{:}];
    volumes_in = volumes{k}(:)';
    vacuoles_in = vacuoles{k}(:)';
    avg_volumes{k} = cellfun(@median,volumes_in);
    dev_volumes{k} = zeros(2,length(avg_volumes{k}));
    avg_vacuoles{k} = cellfun(@median,vacuoles_in);
    dev_vacuoles{k} = zeros(2,length(avg_vacuoles{k}));
    for i = 1:length(volumes{k})
      temp_log = volumes{k}{i}<avg_volumes{k}(i);
      temp_volumes1 = volumes{k}{i}(temp_log);
      temp_volumes1 = [temp_volumes1,avg_volumes{k}(i) - temp_volumes1 + avg_volumes{k}(i)];
      temp_volumes2 = volumes{k}{i}(~temp_log);
      temp_volumes2 = [temp_volumes2,avg_volumes{k}(i) - temp_volumes2 + avg_volumes{k}(i)];
      dev_volumes{k}(:,i) = [std(temp_volumes1),std(temp_volumes2)];
      
      temp_log = vacuoles{k}{i}<avg_vacuoles{k}(i);
      temp_vacuoles1 = vacuoles{k}{i}(temp_log);
      temp_vacuoles1 = [temp_vacuoles1,avg_vacuoles{k}(i) - temp_vacuoles1 + avg_vacuoles{k}(i)];
      temp_vacuoles2 = vacuoles{k}{i}(~temp_log);
      temp_vacuoles2 = [temp_vacuoles2,avg_vacuoles{k}(i) - temp_vacuoles2 + avg_vacuoles{k}(i)];
      dev_vacuoles{k}(:,i) = [std(temp_vacuoles1),std(temp_vacuoles2)];
    end
end
% Cell volumes
data_avg = [avg_volumes{:}];
data_dev = [dev_volumes{:}];
num_col = length(data_avg);
avg = cell(1,num_col);
dev = cell(2,num_col);
for i = 1:num_col
  avg(:,i) = num2cell(data_avg(i));
  dev(:,i) = num2cell(data_dev(:,i));
end
writecell(horzcat({"";"avg";"dev_neg";"dev_pos"},vertcat(num2cell(entries), ...
  vertcat(avg,dev))),'median dev volumes.xlsx'); %#ok<CLARRSTR>

% Vacuole volumes
data_avg = [avg_vacuoles{:}];
data_dev = [dev_vacuoles{:}];
num_col = length(data_avg);
avg = cell(1,num_col);
dev = cell(2,num_col);
for i = 1:num_col
  avg(:,i) = num2cell(data_avg(i));
  dev(:,i) = num2cell(data_dev(:,i));
end
writecell(horzcat({"";"avg";"dev_neg";"dev_pos"},vertcat(num2cell(entries), ...
  vertcat(avg,dev))),'median dev vacuoles.xlsx'); %#ok<CLARRSTR>

