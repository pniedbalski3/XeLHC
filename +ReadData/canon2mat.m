function rotImage = canon2mat(Image)

rotImage = permute(Image,[3,1,2]);
rotImage = fliplr(rot90(rotImage,2));