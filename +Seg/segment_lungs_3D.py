import sys
import os
import numpy
import pathlib
import ants
from ants import image_read, resample_image, iMath, from_numpy, threshold_image, copy_image_info, image_write
from keras.losses import binary_crossentropy
from copy import copy
from keras.models import load_model
from keras import backend as K
import timeit
import tensorflow as tf

with tf.device('/cpu:0'):
	###################################----VARIABLES----###################################

#    _model = '/home/antsbox/Desktop/proton_3D_UNET_v2.h5'
#    _model = '/home/antsbox/Desktop/proton_seg_Unet2D_v2.h5'
    img_size = (128,128,128)
    feature_scale = True
    single_label_mask = True
    slm_threshold = 0.25

	###################################----VARIABLES----###################################


    def get_nifti(filepath):
    	img = image_read(filepath)
    	if img.shape != img_size:
    	    img = resample_image(img, resample_params = (img_size), use_voxels=True, interp_type=0)
    	if feature_scale == True:
    	    img = iMath(img, 'Normalize')
    	print(img)
    	array = img.numpy()
    	array = numpy.reshape(array, (1, *img_size, 1))
    	return array
    
    # interp_type = one of 0 (linear), 1 (nearest neighbor), 2 (gaussian), 3 (windowed sinc), 4 (bspline)
    def convert_original(orig_img, img, mask):
        i = resample_image(img, resample_params = (orig_img.shape), use_voxels=True, interp_type=0)
        m = resample_image(mask, resample_params = (orig_img.shape), use_voxels=True, interp_type=1)
        return i, m
    
    def segment(image, model):
        return model.predict(image)
    
    def dice_coefficient(y_true, y_pred):
        smoothing_factor = 1
        y_true_f = K.flatten(y_true)
        y_pred_f = K.flatten(y_pred)
        intersection = K.sum(y_true_f * y_pred_f)
        return (2.0 * intersection + smoothing_factor) / (K.sum(y_true_f) + K.sum(y_pred_f) + smoothing_factor)
    
    def loss_dice_coefficient_error(y_true, y_pred):
        return 1-dice_coefficient(y_true, y_pred)
    
    def bce_dice_loss(y_true, y_pred):
        return binary_crossentropy(y_true, y_pred) + dice_coef_loss(y_true, y_pred)
    
    def dice_coefficient(y_true, y_pred):
        from keras import backend as K    
        smoothing_factor = 1
        y_true_f = K.flatten(y_true)
        y_pred_f = K.flatten(y_pred)
        intersection = K.sum(y_true_f * y_pred_f)
        return (2.0 * intersection + smoothing_factor) / (K.sum(y_true_f) + K.sum(y_pred_f) + smoothing_factor)
    
    def loss_dice_coefficient_error(y_true, y_pred):
        return -dice_coefficient(y_true, y_pred)
    
    def dice_coef_loss(y_true, y_pred):
        return 1-dice_coefficient(y_true, y_pred)

	#####################################################################
    
    _model = sys.argv[1]
    path_nifti = sys.argv[2]
    ref_img = image_read(sys.argv[2])
    
    #get the image array
    imagearray = get_nifti(path_nifti)

    #load classifier
    model = load_model(_model, custom_objects={'bce_dice_loss': bce_dice_loss, 'dice_coefficient': dice_coefficient})
    
    #get the lung mask
    lungmask = segment(imagearray, model)
    	
    #reshape images
    lungmask = numpy.reshape(lungmask, (img_size))
    imagearray = numpy.reshape(imagearray, (img_size))
    
    print (imagearray.shape)
    
    #convert from numpy array to ants image
    output_img = from_numpy(imagearray)
    output_mask = from_numpy(lungmask)
    
    output_img, output_mask = convert_original(orig_img = ref_img, img = output_img, mask = output_mask)
    
    # Re-convert to a single label mask after the interpolation
    prob_mask = copy(output_mask)
    
    if single_label_mask:
        output_mask = threshold_image(output_mask, low_thresh=slm_threshold, high_thresh=None, inval=1, outval=0, binary=True)
    
    	#copy original image header to new image
    copy_image_info(ref_img, output_img)
    copy_image_info(ref_img, output_mask)
    copy_image_info(ref_img, prob_mask)
    if 'nii.gz' in path_nifti:
        image_write(prob_mask, path_nifti.replace('.nii.gz', '_Probability_mask.nii.gz'))
    else:
        image_write(prob_mask, path_nifti.replace('.nii', '_Probability_mask.nii.gz'))
    
    if single_label_mask:
        if 'nii.gz' in path_nifti:
            image_write(output_mask,path_nifti.replace('.nii.gz', '_Mask.nii.gz'))
        else:
            image_write(output_mask,path_nifti.replace('.nii', '_Mask.nii.gz'))

