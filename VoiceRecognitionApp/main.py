
import librosa
import pdb
import bcfastdtw
from scipy.spatial.distance import euclidean
import numpy
import bcdtw
from os import getcwd,path
np = numpy
from time import clock


from pylab import *
from numpy import *





def extractFeatures(labelFilePath,voiceSampleFolderPath):
    with open(labelFilePath) as f:
        labels=array([line.replace('\n','') for line in f])

    mfccArray={}

    sampleCount=len(labels)

    for i in range(sampleCount):
        wavData,sampleRate=librosa.load(voiceSampleFolderPath+"/"+str(i)+".wav")

        mfccValue=librosa.feature.mfcc(wavData,sampleRate,n_mfcc=13)

        mfccArray[i]=mfccValue.T

    return mfccArray,labels



def generate_train_test_set(P):
    train=[]
    test=[]

    for s in set(labels):
        all = find(labels == s)
        shuffle(all)
        train += all[:-P].tolist()
        test += all[-P:].tolist()
    
    return train,test
#D is the results for all dtw, each row represents

def saveNPArray(NPArray,Name,filePath=None):
    if filePath==None: filePath=getcwd()
    numpy.save(path.join(filePath,Name),NPArray)



labelFilePath1="patientSound/wavetexttag.txt"
soundFileFolderPath1="patientSound"
mfccs,labels=extractFeatures(labelFilePath1,soundFileFolderPath1)
startTime=clock()
D=ones((len(labels),len(labels)))*-1

def cross_validation(train, test):
    successCount = 0.0
    #pdb.set_trace()

    for i in test:
        x = mfccs[i]

        dmin, jmin = inf, -1
        for j in train:
            y = mfccs[j]
            
            #pdb.set_trace()
            d = D[i, j]
            if d == -1: #-1 is the initial value
                #d,haha= fastdtw(x, y, dist=lambda x, y: numpy.linalg.norm(x - y, ord=1))
                #pdb.set_trace()

                d,_= bcfastdtw.fastdtw(x, y, radius=2,dist=lambda x, y: numpy.linalg.norm(x - y, ord=1))
                #d,_=bcdtw.dtw(x,y,dist=lambda x,y:numpy.linalg.norm(x-y,ord=1))
                D[i, j] = d                

            if d < dmin:
                dmin = d
                jmin = j

        successCount += 1.0 if (labels[i] == labels[jmin]) else 0.0

        
    return successCount / len(test), len(test)

train,test = generate_train_test_set(P=1)
rec_rate,testCount=cross_validation(train,test)

endTime=clock()
print('Time Used For Average Second per Recognition/{}'.format((endTime-startTime)/testCount))
print ('Recognition rate :{}'.format(100.*rec_rate))

print(D)









    
