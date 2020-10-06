function mask_out = func2Dto3D(mask)
    D = bwdist(~mask);
    w = zeros([size(D),9],'single');
    for i = 1:9
      u = zeros(9,1,'single');
      u(i) = 1;
      u = reshape(u,[3,3]);
      w(:,:,i) = conv2(D,u,'same');
    end
    w(:,:,5) = [];
    pks = all(D>=w,3);
    mask2 = true(size(mask));
    mask2(pks) = 0;
    mask2(mask2==mask) = 1;
    D2 = bwdist(~logical(mask2));
    D2(~mask) = 0;
    mask_out = sqrt((D+D2).^2-D2.^2);
end