#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division
import numbers
import numpy as np
import bcdtw
#from collections import defaultdict

try:
    range = xrange
except NameError:
    pass


def fastdtw(x, y, radius=1, dist=None):

    ###############################################
    #x,y: Two time Series to be compared
    #radius: number of elements searched around when projecting path from on to a bigger matrix.
    #       Large radius produces more accurate results but results in more computations which defies the purpose
    #       of speed boosting. It's recommended to use bcdtw.dtw is accuracy is the outmost concern.  
 

    #default distance function is Eculidean
    if dist is None:
        dist = lambda x,y:np.linalg.norm(x-y,ord=1)
    
    min_time_size = radius + 2

    if len(x) < min_time_size or len(y) < min_time_size:
        return bcdtw.dtwWindowed(x, y, dist=dist)

    x_shrinked = __shrinkByHalf(x)
    y_shrinked = __shrinkByHalf(y)
    distance, path = \
            fastdtw(x_shrinked, y_shrinked, radius=radius, dist=dist)
    window = __expandWindow(path, len(x), len(y), radius)
    return bcdtw.dtwWindowed(x, y, window, dist=dist)



########Internal Function Not to Be Exposed##################3

#Shrink 1/2 length by taking averages for adjacent elements in the sereis 
def __shrinkByHalf(x):
    return [(x[i] + x[1+i]) / 2 for i in range(0, len(x) - len(x) % 2, 2)]

#create a new windows by projecting a path from a smaller matrix and add the region which is covered
#search radius as well.
def __expandWindow(path, len_x, len_y, radius):
    path_ = set(path)
    for i, j in path:
        for a, b in ((i + a, j + b)
                     for a in range(-radius, radius+1)
                     for b in range(-radius, radius+1)):
            path_.add((a, b))

    window_ = set()
    for i, j in path_:
        for a, b in ((i * 2, j * 2), (i * 2, j * 2 + 1),
                     (i * 2 + 1, j * 2), (i * 2 + 1, j * 2 + 1)):
            window_.add((a, b))

    window = []
    start_j = 0
    for i in range(0, len_x):
        new_start_j = None
        for j in range(start_j, len_y):
            if (i, j) in window_:
                window.append((i, j))
                if new_start_j is None:
                    new_start_j = j
            elif new_start_j is not None:
                break
        start_j = new_start_j

    return window
