#!/usr/bin/env python

import numpy as np, chainer, chainer.functions as F, chainer.links as L
from chainer import training, serializers
from chainer.training import extensions

class CPEN311NN(chainer.Chain):
    def __init__(self):
        super(CPEN311NN, self).__init__()
        with self.init_scope():
            self.l1 = L.Linear(None, 1000)
            self.l2 = L.Linear(None, 1000) 
            self.l3 = L.Linear(None, 10)
    def forward(self, x):
        o1 = F.relu(self.l1(x))
        o2 = F.relu(self.l2(o1))
        o3 = self.l3(o2)
        return o3

nn = L.Classifier(CPEN311NN())

optimizer = chainer.optimizers.Adam()
optimizer.setup(nn)

train, test = chainer.datasets.get_mnist()

train_iter = chainer.iterators.SerialIterator(train, 100)
test_iter = chainer.iterators.SerialIterator(test, 100, repeat=False, shuffle=False)

updater = training.updaters.StandardUpdater(train_iter, optimizer)
trainer = training.Trainer(updater, (20, 'epoch'))

trainer.extend(extensions.Evaluator(test_iter, nn))
trainer.extend(extensions.LogReport())
trainer.extend(extensions.PrintReport(['epoch', 'main/loss', 'validation/main/loss', 'main/accuracy', 'validation/main/accuracy', 'elapsed_time']))
trainer.extend(extensions.ProgressBar())

trainer.run()
serializers.save_npz('cpen311_trained_nn.npz', nn)
