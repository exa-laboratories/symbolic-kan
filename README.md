# symbolicKAN

Julia implementation of B-spline KAN for symbolic regression - recreated pretty much as is from [pykan](https://github.com/KindXiaoming/pykan) on a smaller scale to develop understanding.

WORK IN PROGRESS 

Thank you to KindXiaoming and the rest of the KAN community for putting this awesome network out there for the world to see.

<p align="center">
<img src="figures/kan.png" alt="KAN Architecture" width="70%"
</p>

## To run

1. Precompile packages:

```bash
bash setup.sh
```

2. Unit tests:

```bash
bash src/unit_tests/run_tests.sh
```

3. Work in progress

## TODO

1. CUDA?
2. Optim for L-BFGS - not working

## Message from author:

A very important takeaway: if you ever decide to do something similar, (e.g. you decide to work with Optim optimisers), USE LUX INSTEAD OF FLUX. Explicit gradients are much easier to work with, meanwhile whilst working with Optim, I've had to call destrcuture/restructure which is quite inefficient. Plus, development has been hell.