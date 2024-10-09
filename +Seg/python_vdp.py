# -*- coding: utf-8 -*-
"""
Created on Mon Oct  7 12:02:01 2024

@author: pniedbalski
"""

import sys
import ants.core
import ants.utils
from ants import image_read, image_write
from ants import atropos
from ants import fuzzy_spatial_cmeans_segmentation
from segment_ventilation import el_bicho

#Read in images
path_vent = sys.argv[1]
ref_img = image_read(sys.argv[1])

path_mask = sys.argv[2]
ref_img = image_read(sys.argv[2])

image = ants.image_read(path_vent)
mask = ants.image_read(path_mask)
try:
    atropos_seg = atropos(a=image,x=mask,i='Kmeans[6]',m='[0.3,2x2x2]')
    vent_atropos = path_vent.replace('.nii.gz', '_atropos.nii.gz')
    ants.image_write(atropos_seg['segmentation'],vent_atropos)
except:
    vent_atropos = path_vent.replace('.nii.gz', '_atropos.nii.gz')
    ants.image_write(mask, vent_atropos)
    
cmeans_seg = fuzzy_spatial_cmeans_segmentation(image, mask,convergence_threshold =0.01)
vent_cmeans = path_vent.replace('.nii.gz', '_cmeans.nii.gz')
ants.image_write(cmeans_seg['segmentation_image'],vent_cmeans)

el_bicho_seg = el_bicho(image, mask)
vent_el_bicho = path_vent.replace('.nii.gz', '_elbicho.nii.gz')
ants.image_write(el_bicho_seg['segmentation_image'],vent_el_bicho)