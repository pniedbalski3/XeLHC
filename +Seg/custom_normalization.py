#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 19 12:29:29 2021

@author: chase
"""



import tensorflow as tf
import numpy as np
import ants
 

from tensorflow.keras.layers import Layer, InputSpec

from tensorflow.keras import initializers, regularizers, constraints

from tensorflow.keras import backend as K

 

 

class InstanceNormalization(Layer):

 

    """

    Instance normalization layer.

 

    Normalize the activations of the previous layer at each step,

    i.e. applies a transformation that maintains the mean activation

    close to 0 and the activation standard deviation close to 1.

 

    Taken from

 

    https://github.com/keras-team/keras-contrib/blob/master/keras_contrib/layers/normalization/instancenormalization.py

 

    Arguments

    ---------

 

    axis: integer

        Integer specifying which axis should be normalized, typically

        the feature axis.  For example, after a Conv2D layer with

        `channels_first`, set axis = 1.  Setting `axis=-1L` will

        normalize all values in each instance of the batch.  Axis 0

        is the batch dimension for tensorflow backend so we throw an

        error if `axis = 0`.

 

    epsilon: float

        Small float added to variance to avoid dividing by zero.

 

    center: If True, add offset of `beta` to normalized tensor.

        If False, `beta` is ignored.

 

    scale: If True, multiply by `gamma`.

        If False, `gamma` is not used.  When the next layer is linear (also e.g.,

        `nn.relu`), this can be disabled since the scaling will be done by the

        next layer.

 

    beta_initializer : string

        Initializer for the beta weight.

 

    gamma_initializer : string

        Initializer for the gamma weight.

 

    beta_regularizer : string

        Optional regularizer for the beta weight.

 

    gamma_regularizer : string

        Optional regularizer for the gamma weight.

 

    beta_constraint : string

        Optional constraint for the beta weight.

 

    gamma_constraint : string

        Optional constraint for the gamma weight.

 

    Returns

    -------

    Keras layer

 

 

    """

    def __init__(self, axis=None, epsilon=1e-3, center=True, scale=True,

                 beta_initializer='zeros', gamma_initializer='ones',

                 beta_regularizer=None, gamma_regularizer=None,

                 beta_constraint=None, gamma_constraint=None, **kwargs):

 

        super(InstanceNormalization, self).__init__(**kwargs)

        self.supports_masking = True

        self.axis = axis

 

        if self.axis == 0:

            raise ValueError('Axis cannot be zero')

 

        self.epsilon = epsilon

        self.center = center

        self.scale = scale

        self.beta_initializer = initializers.get(beta_initializer)

        self.gamma_initializer = initializers.get(gamma_initializer)

        self.beta_regularizer = regularizers.get(beta_regularizer)

        self.gamma_regularizer = regularizers.get(gamma_regularizer)

        self.beta_constraint = constraints.get(beta_constraint)

        self.gamma_constraint = constraints.get(gamma_constraint)

 

    def build(self, input_shape):

        dimensionality = len(input_shape)

 

        if (self.axis is not None) and (dimensionality == 2):

            raise ValueError('Cannot specify axis for rank 1 tensor')

 

        self.input_spec = InputSpec(ndim=dimensionality)

 

        if self.axis is None:

            shape = (1,)

        else:

            shape = (input_shape[self.axis],)

 

        if self.scale:

            self.gamma = self.add_weight(shape=shape,

                                         name='gamma',

                                         initializer=self.gamma_initializer,

                                         regularizer=self.gamma_regularizer,

                                         constraint=self.gamma_constraint)

        else:

            self.gamma = None

 

        if self.center:

            self.beta = self.add_weight(shape=shape,

                                        name='beta',

                                        initializer=self.beta_initializer,

                                        regularizer=self.beta_regularizer,

                                        constraint=self.beta_constraint)

        else:

            self.beta = None

 

        self.built = True

 

    def call(self, inputs, training=None):

        input_shape = K.int_shape(inputs)

        reduction_axes = list(range(0, len(input_shape)))

 

        if self.axis is not None:

            del reduction_axes[self.axis]

 

        del reduction_axes[0]

 

        mean = K.mean(inputs, reduction_axes, keepdims=True)

        stddev = K.std(inputs, reduction_axes, keepdims=True)

        normed = (inputs - mean) / (stddev + self.epsilon)

 

        broadcast_shape = [1] * len(input_shape)

        if self.axis is not None:

            broadcast_shape[self.axis] = input_shape[self.axis]

 

        if self.scale:

            broadcast_gamma = K.reshape(self.gamma, broadcast_shape)

            normed = normed * broadcast_gamma

        if self.center:

            broadcast_beta = K.reshape(self.beta, broadcast_shape)

            normed = normed + broadcast_beta

        return normed

 

    def get_config(self):

        config = {

            'axis': self.axis,

            'epsilon': self.epsilon,

            'center': self.center,

            'scale': self.scale,

            'beta_initializer': initializers.serialize(self.beta_initializer),

            'gamma_initializer': initializers.serialize(self.gamma_initializer),

            'beta_regularizer': regularizers.serialize(self.beta_regularizer),

            'gamma_regularizer': regularizers.serialize(self.gamma_regularizer),

            'beta_constraint': constraints.serialize(self.beta_constraint),

            'gamma_constraint': constraints.serialize(self.gamma_constraint)

        }

        base_config = super(InstanceNormalization, self).get_config()

        return dict(list(base_config.items()) + list(config.items()))


def crop_image_center(image,

                      crop_size):

    """

    Crop the center of an image.

 

    Arguments

    ---------

    image : ANTsImage

        Input image

 

    crop_size: n-D tuple (depending on dimensionality).

        Width, height, depth (if 3-D), and time (if 4-D) of crop region.

 

    Returns

    -------

    A list (or array) of patches.

 

    Example

    -------

    >>> import ants

    >>> image = ants.image_read(ants.get_ants_data('r16'))

    >>> cropped_image = crop_image_center(image, crop_size=(64, 64))

    """

 

    image_size = np.array(image.shape)

 

    if len(image_size) != len(crop_size):

        raise ValueError("crop_size does not match image size.")

 

    if (np.asarray(crop_size) > np.asarray(image_size)).any():

        raise ValueError("A crop_size dimension is larger than image_size.")

 

    start_index = (np.floor(0.5 * (np.asarray(image_size) - np.asarray(crop_size)))).astype(int)

    end_index = start_index + np.asarray(crop_size).astype(int)

 

    cropped_image = ants.crop_indices(ants.image_clone(image) * 1, start_index, end_index)

 

    return(cropped_image) 


def pad_or_crop_image_to_size(image,

                              size):

    """

    Pad or crop an image to a specified size

 

    Arguments

    ---------

    image : ANTsImage

        Input image

 

    size : tuple

        size of output image

 

    Returns

    -------

    A cropped or padded image

 

    Example

    -------

    >>> import ants

    >>> image = ants.image_read(ants.get_ants_data('r16'))

    >>> padded_image = pad_or_crop_image_to_size(image, (333, 333))

    """

 

    image_size = np.array(image.shape)

 

    delta = image_size - np.array(size)

 

    if np.any(delta < 0):

        pad_size = abs(delta.min())

        pad_shape = image_size + pad_size

        image = ants.pad_image(image, shape=pad_shape)

 

    cropped_image = crop_image_center(image, size)

 

    return(cropped_image)

 
