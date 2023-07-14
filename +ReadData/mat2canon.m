function rotImage = mat2canon(Image)

rotImage = permute(Image,[2,3,1]);
rotImage = flip(rotImage,3);

