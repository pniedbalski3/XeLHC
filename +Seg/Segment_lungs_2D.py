#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jan  6 11:14:41 2021

@author: chall2
"""

from segment_1H_MRI import *
from helper import *
import sys
import os
import numpy
import pathlib
import ants

#path_model = '/home/antsbox/Desktop/proton_seg_Unet2D_v2.h5'
#proton_path = '/media/sf_Tmp_Share_VM_Folder/Xe-011_Vent/Anatomic_Image.nii'
#vent_path = '/media/sf_Tmp_Share_VM_Folder/Xe-011_Vent/Vent_Image.nii'

path_model = sys.argv[1]

proton_path = sys.argv[2]
#ref_img = image_read(sys.argv[1])

#vent_path = sys.argv[3]
#ref_img = image_read(sys.argv[1])

###############################################################################
proton_resampled = proton_path.replace('.nii.gz', '_resampled.nii.gz')
proton_seg = proton_resampled.replace('.nii.gz','_mask.nii.gz' )
#vent_mask = vent_path.replace('.nii.gz', '_mask.nii.gz')
#reg_mask = proton_seg.replace('.nii.gz', '_registered.nii.gz')
#reg_mat = proton_seg.replace('.nii.gz', '_registered_0GenericAffine.mat')
#reg_fwd = proton_seg.replace('.nii.gz', '_registered_1Warp.nii.gz')
#final_mask= proton_seg.replace('.nii.gz','_registered_warped.nii.gz')
#bias_cor_vent = vent_path.replace('.nii.gz','Segmentation0N4.nii.gz' )

#align_1H_to_vent(proton=proton_path, vent=vent_path)

segment_1H(img=proton_path, model=path_model)

#mask_vent(vent=vent_path, proton_seg=proton_seg)

#snr= snr(vent_path, vent_mask)

#register_images(vent_mask,proton_seg)

#warp_image(reg_mask, vent_mask, [reg_fwd, reg_mat], interpolation='genericLabel')

#plot(vent_path, final_mask, axis=2)

#functional_segmentation_tustison(vent_path, final_mask)

#get_VDP(bias_cor_vent, final_mask)
