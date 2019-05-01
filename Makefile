

###############################################################################
#                       Configuration
#
#   Set the PLY_SIZE, PLY_MEASURE, PLY_OPTIONS, PLY_C_LDFLAGS
#
# TO use PAPI: 	see the comments "FOR PAPI:"
# TO dump the matrix C, uncommment the "FOR PRINTING:"
#
###############################################################################



# |||| Size

#PLY_SIZE=-DHAVERSMALL_DATASET
#PLY_SIZE=-DHAVEREXTRALARGE_DATASET
#PLY_SIZE=-DLARGE_DATASET
PLY_SIZE=-DMEDIUM_DATASET



# |||| What we measure

#PLY_MEASURE=-DPOLYBENCH_GFLOPS
## FOR PAPI:
PLY_MEASURE=-DPOLYBENCH_PAPI -DPOLYBENCH_PAPI_VERBOSE



# |||| Are we printing the result?

PLY_OPTIONS=-DPOLYBENCH_USE_C99_PROTO -DPOLYFORD_VERBOSE
#FOR PRINTING:
#PLY_OPTIONS=-DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_USE_C99_PROTO -DPOLYFORD_VERBOSE



# FOR PAPI:
#PLY_C_LDFLAGS=-lm # -lpapi  # C/C++ libraries go here
PLY_C_LDFLAGS=-lm -lpapi  # C/C++ libraries go here




###############################################################################
#                       Don't touch stuff below here
###############################################################################

CC=gcc
PLY_C_OPTIMIZE=-O3
PLY_C_EXTRA_FLAGS=-fopenmp


CFLAGS=${PLY_C_OPTIMIZE} ${PLY_OPTIONS} ${PLY_DATATYPE} ${PLY_SIZE} ${PLY_MEASURE} ${PLY_C_EXTRA_FLAGS}
LDFLAGS=${PLY_C_LDFLAGS}
# END generic stuff


# The making part
BENCHNAME=syr2k
EXTRA_FLAGS=

syr2k: syr2k.c syr2k.h
	${VERBOSE} ${CC} -o $(BENCHNAME) $(BENCHNAME).c ${CFLAGS} -I. -I./utilities ./utilities/polybench.c ${EXTRA_FLAGS} ${LDFLAGS}

clean:
	@ rm -f $(BENCHNAME)

