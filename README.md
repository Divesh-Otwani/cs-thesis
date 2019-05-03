# Syr2k Optimizations in Chapel and C

In this folder we have C and Chapel codes that are various optimizations
of the dense matrix codes syr2k from PolyBench 4.0. We also have several
recorded timing results.


**The official results used in my thesis are in the `official-thesis` folder.**

Note:
* Keller is the name of our research machine with two E5-2620 chips
* Goldwasser is the name of our intel core i5-6500 machine


## Running The Codes

```bash
$ python3 run-timing.py filename-you-want
```

Play around with the configuration at the top to customize which tests run and
how many times.




##  Getting The Tools

The results will (obviously) vary by architecture.  Hopefully the results we
obtained on our specific architectures are reproducible.

The instructions below work for Ubuntu 18.04 Bionic Beaver.


### Getting the right C compiler

Hopefully the standard gcc works. If not, dig through the Makefile and see what tools you need.


### Getting Chapel Working

To get chapel working you need to install docker.


1. Install docker from [here](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository). You should follow the 'install via repository section'.

2. Let docker run without root permissions: see [here](https://docs.docker.com/install/linux/linux-postinstall/)



### Checking Correctness

For C programs:

1. Edit the Makefile by reading the comments in there.

2. Do this:

```bash
$ cp c-codes/syr2k.backup.c syr2k.c
$ make syr2k PLY_SIZE=-DMEDIUM_DATASET 
$ ./syr2k 2> original_output_on_med
$ cp c-codes/syr2k.somethingelse.c syr2k.c
$ make syr2k PLY_SIZE=-DMEDIUM_DATASET 
$ ./syr2k 2> somethingelse_output_on_med
$ diff original_output_on_med somethingelse_output_on_med
```

Note that we could replace MEDIUM with SMALL, MEDIUM, LARGE, HAVERLARGE to get
further checks.


For Chapel programs:

1. Uncomment the print statement at the bottom of the code.
2. Compare the values with the output from the original syr2k Chapel version,
   which is correct.



