function saveLabel(main_dir,tempname,label)
  save(strcat(main_dir,'/Labels/',tempname,'.mat'),'label'); 