#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 28 14:46:29 2021

@author: chase
"""

import numpy as np
import ants
import sys
from keras.models import load_model
from keras.losses import binary_crossentropy
from keras import backend as K
import tensorflow as tf

import os
with tf.device('/cpu:0'):
    
    def bce_dice_loss(y_true, y_pred):
        return binary_crossentropy(y_true, y_pred) + dice_coef_loss(y_true, y_pred)
    
    def dice_coef(y_true, y_pred, smooth=1):
        y_true_f = K.flatten(y_true)
        y_pred_f = K.flatten(y_pred)
    
        intersection = K.sum(y_true_f * y_pred_f)
        return (2. * intersection + smooth) / (K.sum(y_true_f) + K.sum(y_pred_f) + smooth)
    
    def dice_coef_loss(y_true, y_pred):
        return 1-dice_coef(y_true, y_pred)
    
    def segment_proton(proton_path=None, model_dims='3D', use_all_dims=True, all_probabilities=False):
        #model_path_2D= '/data/Proton_MRI_Segmentation/trained_models/proton_seg_Unet2D_v2.1.h5'

        filepath = os.path.dirname(os.path.abspath(__file__))
        newpath = os.path.dirname(filepath)
        model_path_2D=os.path.join(newpath,'Deep_Learning_Models/proton_seg_Unet2D_v2.1.h5')
        model_path_3D=model_path_2D=os.path.join(newpath,'Deep_Learning_Models/proton_3D_Resnet_UNET_v2.h5')

       # model_path_2D='/home/antsbox/Xenon_Pipeline/Analysis_Pipeline/Deep_Learning_Models/proton_seg_Unet2D_v2.1.h5'
        #model_path_3D = '/data/Proton_MRI_Segmentation/trained_models/proton_3D_Resnet_UNET_v2.h5'   
       # model_path_3D = '/home/antsbox/Xenon_Pipeline/Analysis_Pipeline/Deep_Learning_Models/proton_3D_Resnet_UNET_v2.h5'   

        model_2D = load_model(model_path_2D, custom_objects={'bce_dice_loss': bce_dice_loss, 'dice_coefficient': dice_coef})
        model_3D = load_model(model_path_3D, custom_objects={'bce_dice_loss': bce_dice_loss, 'dice_coefficient': dice_coef})
        if proton_path == None:
            try:
                proton_path = str(sys.argv[1])
                print(proton_path)
            except:
                raise ValueError("Must provide input image")
            try:
                model_dims = str(sys.argv[2])
            except:
                print('model_dims defaults to 3D')
            try:
                use_all_dims = sys.argv[3]
                if use_all_dims in ['True', True, 'true']:
                    use_all_dims = True
                else:
                    use_all_dims = False
            except:
                print('use_all_dims defaults to True')
            try:
                all_probabilities = sys.argv[4]
                if all_probabilities in ['True', True, 'true']:
                    all_probabilities = True
                else:
                    all_probabilities = False
            except:
                print('all_probabilities defaults to False')
                
        print('##########################################')
        print('## model_dims = {}, use_all_dims = {}'.format(model_dims, use_all_dims))
        print('##########################################')

            
        img = ants.image_read(proton_path)

        print('Read Successful')
        orig_dims = img.shape
        
        reshaped_results = []    
        
        if use_all_dims==True and model_dims !='3D':
            dim_1 = ants.image_clone(img)
            dim_2 = ants.from_numpy(np.swapaxes(ants.image_clone(img).numpy(),0,2))
            dim_3 = ants.from_numpy(np.swapaxes(ants.image_clone(img).numpy(),1,2))
            dims = (dim_1,dim_2,dim_3)
            for num,dim in enumerate(dims):
                #ants.plot(dim, axis=2)
                if (dim.shape[0],dim.shape[1]) != (128,128):
            	    resample = ants.resample_image(dim, resample_params = (128,128,dim.shape[2]), use_voxels=True, interp_type=0)
                norm = ants.iMath(resample, 'Normalize')
                trans = np.transpose(norm.numpy())
                reshaped = trans.reshape(*trans.shape,1)
                result = model_2D.predict(reshaped)
                i = np.squeeze(result, axis=3)
                i = np.transpose(i)
                i = ants.resample_image(ants.from_numpy(i), resample_params = (orig_dims[0],orig_dims[1],orig_dims[2]), use_voxels=True, interp_type=0)
                if num == 1:
                    i = ants.from_numpy(np.swapaxes(i.numpy(),0,2))
                if num == 2:
                    i = ants.from_numpy(np.swapaxes(i.numpy(),1,2))
                i = ants.copy_image_info(img,i)
                reshaped_results.append(i)      
        
        if model_dims == '3D' or model_dims == 'All':
            dim = ants.image_clone(img)
            if (dim.shape) != (128,128,128):
                resample = ants.resample_image(dim, resample_params = (128,128,128), use_voxels=True, interp_type=0)
            norm = ants.iMath(resample, 'Normalize').numpy()
            reshaped = norm.reshape(1,*norm.shape,1)
            result = model_3D.predict(reshaped)
            i = np.squeeze(result, axis=4)
            i = np.squeeze(i,axis=0)
            i = ants.resample_image(ants.from_numpy(i), resample_params = (orig_dims[0],orig_dims[1],orig_dims[2]), use_voxels=True, interp_type=0)
            i = ants.copy_image_info(img,i)
            reshaped_results.append(i)      
    
        if use_all_dims!=True and model_dims !='3D':
            dim_1 = ants.image_clone(img)
            if (dim_1.shape[0],dim_1.shape[1]) != (128,128):
                resample = ants.resample_image(dim_1, resample_params = (128,128,dim_1.shape[2]), use_voxels=True, interp_type=0)
            norm = ants.iMath(resample, 'Normalize')
            trans = np.transpose(norm.numpy())
            reshaped = trans.reshape(*trans.shape,1)
            result = model_2D.predict(reshaped)
            i = np.squeeze(result, axis=3)
            i = np.transpose(i)
            i = ants.resample_image(ants.from_numpy(i), resample_params = (orig_dims[0],orig_dims[1],orig_dims[2]), use_voxels=True, interp_type=0)
            i = ants.copy_image_info(img,i)
            reshaped_results.append(i)
        
        if all_probabilities:
            for num,result in enumerate(reshaped_results):
                ants.image_write(result, proton_path.replace('.nii.gz','_probability_segmentation_dim_{}.nii.gz'.format(num)))  
        
        if use_all_dims and model_dims == '2D':
            new_img = (reshaped_results[0] + reshaped_results[1] + reshaped_results[2]) / 3
        if model_dims == '3D':
            new_img = reshaped_results[0] 
        if use_all_dims==True and model_dims == 'All':
            new_img = (reshaped_results[0] + reshaped_results[1] + reshaped_results[2] + reshaped_results[3]) / 4     
        if use_all_dims==False and model_dims == '2D':
            new_img = reshaped_results[0]  
        if (use_all_dims!=True and model_dims=='All'):
            new_img = (reshaped_results[0] + reshaped_results[1]) / 2
            
        ants.image_write(new_img, proton_path.replace('.nii.gz','_probability_mask.nii.gz'))
        
        if model_dims == 'All':
            new_img[new_img > 0.5] = 1
            new_img[new_img < 1] = 0
        else:
            new_img[new_img > 0.6] = 1
            new_img[new_img < 1] = 0

        ants.image_write(new_img,  proton_path.replace('.nii.gz','_mask.nii.gz'))
    
    if __name__ == '__main__':
        segment_proton()

        
    
