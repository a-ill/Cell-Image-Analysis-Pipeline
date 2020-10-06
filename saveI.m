function saveI(main_dir,cnt,I1,I2)

save(strcat(main_dir,'/TrainImages/',num2str(cnt),'.mat'),'I1')
save(strcat(main_dir,'/TrainMasks/',num2str(cnt),'.mat'),'I2')
