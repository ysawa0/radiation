import random
import numpy as np


def similarity(w_TD, w_OVH, w_STS, D_TD, D_OVH, D_STS):
    a = w_TD * (D_TD / max(D_TD))
    b = w_OVH * (D_OVH / max(D_OVH))
    c = w_STS * (D_STS / max(D_STS))
    ret = 1 - (a + b + c)
    return ret


if __name__ == '__main__':
    size = 3

    td = np.random.uniform(low=0, high=1, size=(size,))
    ovh = np.random.uniform(low=0, high=1, size=(size,))
    sts = np.random.uniform(low=0, high=1, size=(size,))

    wtd = 0.25
    wovh = 0.25
    wsts = 0.5

    assert wtd + wovh + wsts == 1
    s = similarity(wtd, wovh, wsts, td, ovh, sts)
    print('========= DONE =========')
    print(s)
