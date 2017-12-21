from numpy import array, zeros, argmin, inf
from numpy.linalg import norm
from collections import defaultdict
import pdb


def dtw(x, y, dist=lambda x, y: norm(x - y, ord=1)):
   
    
    x = array(x)
    if len(x.shape) == 1:
        x = x.reshape(-1, 1)
    y = array(y)
    if len(y.shape) == 1:
        y = y.reshape(-1, 1)

    #Produce Number of Frames
    Nx, Ny = len(x), len(y)

    D = zeros((Nx + 1, Ny + 1))
    D[0, 1:] = inf
    D[1:, 0] = inf

    #Populate the distance Map with initial one-to-one distance
    for i in range(Nx):
        for j in range(Ny):
            #by default, first norm, abs(xi-yi) is used
            D[i+1, j+1] = dist(x[i], y[j])

    #calculate the accumulated distance
    for i in range(Nx):
        for j in range(Ny):
            D[i+1, j+1] += min(D[i, j], D[i, j+1], D[i+1, j])

    D = D[1:, 1:]
    
    dist = D[-1, -1] / sum(D.shape)

    #return dist, D, _trackeback(D)
    return dist,D

def dtwConstrainted(x,y,c,dist=lambda x, y: numpy.linalg.norm(x - y, ord=1)):
    D=zeros((len(x)+1,len(y)+1))
    #Select Proper Constraint size.
    c = max(c, abs(len(x)-len(y)))


    #Fill in the first row/column with inf as a "Boundary" for the calculation later
    for i in range(-1,len(x)):
        for j in range(-1,len(y)):
            D[i,j] = float('inf')
    #Initialize x-first-point to y-first-point distance
    D[1,1] = 0

    for i in range(len(x)):
        for j in range(max(0, i-c), min(len(y), i+c)):
            distance=dist(x[i],y[j])
            D[i,j] = distance + min(DTW[i-1, j],DTW[i, j-1], DTW[i-1, j-1])

    return D[len(x),len(y)]

def dtwWindowed(x, y, window=None, dist=lambda x,y:numpy.linalg.norm(x-y,ord=1)):
    #Faster Implementation comparing with dtw by using higher performance data structures
    #added windowed function to select a specific window to dtw
    
    Nx, Ny = len(x), len(y)

    # if no specified window provided, No optimization is required 
    #use the entire matrix as the windows by default
    if window is None:
        window = [(i, j) for i in range(Nx) for j in range(Ny)]

    # add one for each element in the windows,to ensure that we left "inf" boundry out of the map
    window = ((i + 1, j + 1) for i, j in window)

    # Create distance Map with inf served as boundary/default
    D = defaultdict(lambda: (float('inf'),))

    D[0, 0] = (0, 0, 0)

    #Only calculate the Minimum Accumulated
    for i, j in window:
        d = dist(x[i-1], y[j-1])
        D[i, j] = min((D[i-1, j][0]+d, i-1, j), (D[i, j-1][0]+d, i, j-1),
                      (D[i-1, j-1][0]+d, i-1, j-1), key=lambda a: a[0])
    
    pathForWindow = []
    i, j = Nx, Ny
    while not (i == j == 0):
        pathForWindow.append((i-1, j-1))
        i, j = D[i, j][1], D[i, j][2]
    pathForWindow.reverse()

    return (D[Nx, Ny][0], pathForWindow)

# use to extract the minimum warped path given the accumulative minimum distance matrix
def _trackeback(D):
    i, j = array(D.shape) - 1
    p, q = [i], [j]
    while (i > 0 and j > 0):
        tb = argmin((D[i-1, j-1], D[i-1, j], D[i, j-1]))

        if (tb == 0):
            i = i - 1
            j = j - 1
        elif (tb == 1):
            i = i - 1
        elif (tb == 2):
            j = j - 1

        p.insert(0, i)
        q.insert(0, j)

    p.insert(0, 0)
    q.insert(0, 0)
    return (array(p), array(q))
