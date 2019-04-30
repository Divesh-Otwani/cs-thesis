/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* syr2k.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "syr2k.h"


/* Array initialization. */
static
void init_array(int n, int m,
		DATA_TYPE *alpha,
		DATA_TYPE *beta,
		DATA_TYPE POLYBENCH_2D(C,N,N,n,n),
		DATA_TYPE POLYBENCH_2D(A,N,M,n,m),
		DATA_TYPE POLYBENCH_2D(B,N,M,n,m))
{
  int i, j;

  *alpha = 1.5;
  *beta = 1.2;
  for (i = 0; i < n; i++)
    for (j = 0; j < m; j++) {
      A[i][j] = (DATA_TYPE) ((i*j+1)%n) / n;
      B[i][j] = (DATA_TYPE) ((i*j+2)%m) / m;
    }
  for (i = 0; i < n; i++)
    for (j = 0; j < n; j++) {
      C[i][j] = (DATA_TYPE) ((i*j+3)%n) / m;
    }
}


/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static
void print_array(int n,
		 DATA_TYPE POLYBENCH_2D(C,N,N,n,n))
{
  int i, j;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("C");
  for (i = 0; i < n; i++)
    for (j = 0; j < n; j++) {
	if ((i * n + j) % 20 == 0) fprintf (POLYBENCH_DUMP_TARGET, "\n");
	fprintf (POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, C[i][j]);
    }
  POLYBENCH_DUMP_END("C");
  POLYBENCH_DUMP_FINISH;
}


/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static
void kernel_syr2k(int n, int m,
		  DATA_TYPE alpha,
		  DATA_TYPE beta,
		  DATA_TYPE POLYBENCH_2D(C,N,N,n,n),
		  DATA_TYPE POLYBENCH_2D(A,N,M,n,m),
		  DATA_TYPE POLYBENCH_2D(B,N,M,n,m),
		  DATA_TYPE POLYBENCH_2D(At,M,N,m,n),
		  DATA_TYPE POLYBENCH_2D(Bt,M,N,m,n))
{

  /* Sizes

   * the linesize is 64 bytes on keller and blum
   * on keller, L1,L2,L3 is 32 KB, 256 KB, 20480 KB
   * on blum, 32KB , 256 KB, 6 MB
   * 64 bits per word; each word is 8 bytes


  */

  // Indices
  int i, j, k;
  int ii, jj;

  // PARAMETER 1
  // make sure you change the data size when you change this too!!!
  int cacheSize = 256; // IN kilobytes !!!

  // PARAMETER 2
  int jumpA = floor((cacheSize * 1024) /  (4*8*8));
  int jumpB = floor((cacheSize * 1024 ) / (18*8) );
  int jump = jumpA;

  // Misc. Calculations
  int linesize = 8; // how many bytes per cache line?
  int blockcount = cacheSize * 1024 / linesize;
  // kb * (bytes / per kb) / (bytes / per cache line)



//BLAS PARAMS
//UPLO  = 'L'
//TRANS = 'N'
//A is NxM
//At is MxN
//B is NxM
//Bt is MxN
//C is NxN
#pragma scop
  // Note: I can't figure out how to 
  // stack allocate the array; I do this beforehand
  // and it's untimed.

  for (ii=0; ii < _PB_N; ii += jump){
    for(jj=0; jj < _PB_M; jj += jump){
      for (i=ii; i < fmin(jump + ii, _PB_N); i++){
        for (j=jj; j < fmin(jump + jj, _PB_M); j++){
          // Transpose
          At[j][i] = A[i][j];
          Bt[j][i] = B[i][j];
        }
      }
    }
  }

  // At is M by N
  // Bt is M by N


  for (i = 0; i < _PB_N; i++) {
    for (j = 0; j <= i; j++)
      C[i][j] *= beta;
    for (k = 0; k < _PB_M; k++)
      for (j = 0; j <= i; j++)
	{
	  C[i][j] += At[k][j]*alpha*B[i][k] + Bt[k][j]*alpha*A[i][k];
	}
  }

#pragma endscop
}


int main(int argc, char** argv)
{
  /* Retrieve problem size. */
  int n = N;
  int m = M;


  double footprint = 8*(n*n + 2*n*m);	// HAVERFORD added code
  double FP_ops = 3.0 * m * (n + 1) * n;	// HAVERFORD added code

#ifdef POLYBENCH_GFLOPS
  polybench_set_program_flops(FP_ops); 	// HAVERFORD addition
#endif

#if defined POLYFORD_VERBOSE
  printf("Starting %s, n=%8d, m=%8d, Footprint %8.4g M,  Source FP ops=%8.4g G\n",
	 __FILE__, n, m, footprint / (1024 * 1024), FP_ops/1000000000.0);
#endif


  /* Variable declaration/allocation. */
  DATA_TYPE alpha;
  DATA_TYPE beta;
  POLYBENCH_2D_ARRAY_DECL(C,DATA_TYPE,N,N,n,n);
  POLYBENCH_2D_ARRAY_DECL(A,DATA_TYPE,N,M,n,m);
  POLYBENCH_2D_ARRAY_DECL(B,DATA_TYPE,N,M,n,m);
  POLYBENCH_2D_ARRAY_DECL(At,DATA_TYPE,M,N,m,n);
  POLYBENCH_2D_ARRAY_DECL(Bt,DATA_TYPE,M,N,m,n);

  /* Initialize array(s). */
  init_array (n, m, &alpha, &beta,
	      POLYBENCH_ARRAY(C),
	      POLYBENCH_ARRAY(A),
	      POLYBENCH_ARRAY(B));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_syr2k (n, m,
		alpha, beta,
		POLYBENCH_ARRAY(C),
		POLYBENCH_ARRAY(A),
		POLYBENCH_ARRAY(B),
                POLYBENCH_ARRAY(At),
                POLYBENCH_ARRAY(Bt));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(n, POLYBENCH_ARRAY(C)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(C);
  POLYBENCH_FREE_ARRAY(A);
  POLYBENCH_FREE_ARRAY(B);

  return 0;
}
