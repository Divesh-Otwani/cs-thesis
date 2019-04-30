// Packages
use Time;


// Config params
config param N : int;
config param M : int;

enum IterChoice { original, ptile, ptilepar, pluto };
config param iterChoice = IterChoice.original;

// Defined below record definitions:
//   config type recChoice = OriginalArr;

// Options for recChoice:
//   OriginalArr
//   TransposedArr


/*                              Records                                 */
/*    ***************************************************************   */
/*    ***************************************************************   */

record OriginalArr {
  const n: int;
  const m: int;
  const dom: domain(2);
  var Array: [dom] real;


  proc init(nn:int, mm:int, Arr: [] real){
    this.n = nn;
    this.m = mm;
    this.dom = {1..n,1..m};
    this.Array = (Arr: [1..n,1..m] real);

  }

  proc this(i: int, j: int) ref: real {
    return Array[i,j];
  }

}


record TransposedArr {
  const n: int;
  const m: int;
  const dom: domain(2);
  var TransArr: [dom] real;


  proc init(nn:int, mm:int, Arr: [] real){
    this.n = nn;
    this.m = mm;
    this.dom = {1..m,1..n};
    this.TransArr = 0; // Sigh, this is necessary.

    const cacheSize: int = 256;
    const jump: int = divfloor(cacheSize * 1024,  4 * 8 * 8 );
    for ii in {1..n} by jump do {
      for jj in {1..n} by jump do {
        for i in {ii..(min(ii+jump,n))} do {
          for j in {jj..(min(jj+jump,m))}  do {
            TransArr[j,i] = Arr[i,j];
          }
        }
      }
    }
  }


  proc this(i: int, j: int) ref: real {
    return TransArr[j,i];
  }

}





config type recChoice = OriginalArr;


/*                             Iterators                                */
/*    ***************************************************************   */
/*    ***************************************************************   */


enum Stmt {betamult, updateC};

/*    **************************   */
/*        Original Iterator       */
/*    **************************   */

iter org(n:int, m:int): (int, int, int, Stmt) {
  for i in {1..n} do {
    for j in {1..i} do {
      yield (i,j,0,Stmt.betamult);
    }
    for k in {1..m} do
      for j in {1..i} do {
        yield (i,k,j,Stmt.updateC);
      }
  }
}

/*    **************************   */
/*       Pluto iterator            */
/*    **************************   */

iter pluto(n:int, m:int): (int, int, int, Stmt) {
  var t2:int;
  var t3:int;
  var t4:int;
  for t2 in {0..(n-1)} do {
    for t3 in {0..t2} do {
      yield (t2+1, t3+1, 0, Stmt.betamult);
    }
  }

  for t2 in {0..(n-1)} do {
    for t3 in {0..t2} do {
      for t4 in {0..(m-1)} do {
        yield (t2+1,t4+1,t3+1, Stmt.updateC);
      }
    }
  }

}



/*    **************************   */
/*     pluto tile iterator         */
/*    **************************   */


iter plutoTile(n: int, m:int): (int, int, int, Stmt) {
  const t2bound: int = divfloor(n-1,32);
  var t4bound: int;
  var lbv: int;
  var ubv: int;

  var t5bound: int,
      t6bound: int,
      t7bound: int;
  const t4bound2: int = divfloor(m-1,32): int;

  for t2 in {0..t2bound} do {

    for t3 in {0..t2} do {
      t4bound = min(n-1, 32*t2 + 31);
      for t4 in {(32*t2)..t4bound} do {
        lbv = 32*t3;
        ubv=min(t4, 32*t3 + 31);
        for t5 in {lbv..ubv} do {
          yield (t4+1, t5+1, 0, Stmt.betamult);
        }
      }
    }

    t5bound = min(n-1, 32*t2+31);
    for t3 in {0..t2} do {
      for t4 in {0..t4bound2} do {
        t7bound = min(m-1,32*t4+31);
        for t5 in {(32*t2..t5bound)} do {
          t6bound = min(t5, 32*t3 + 31);
          for t6 in {(32*t3)..t6bound} do {
            for t7 in {(32*t4)..t7bound} do {
              yield (t5+1,t7+1,t6+1, Stmt.updateC);
            }
          }
        }
      }
    }
  }

}




/*    **************************   */
/*  Pluto Tile Parallel Iterator  */
/*    **************************   */


iter plutoTilePar(param tag: iterKind, n: int, m:int): (int, int, int, Stmt) 
where tag == iterKind.standalone {
  const t2bound: int = divfloor(n-1,32);
  const t4bound2: int = divfloor(m-1,32): int;
  forall t2 in {0..t2bound} do {

    for t3 in {0..t2} do {
      var t4bound: int = min(n-1, 32*t2 + 31);
      for t4 in {(32*t2)..t4bound} do {
        var lbv: int = 32*t3;
        var ubv: int=min(t4, 32*t3 + 31);
        for t5 in {lbv..ubv} do {
          yield (t4+1, t5+1, 0, Stmt.betamult);
        }
      }
    }

    var t5bound: int = min(n-1, 32*t2+31);
    for t3 in {0..t2} do {
      for t4 in {0..t4bound2} do {
        var t7bound: int = min(m-1,32*t4+31);
        for t5 in {(32*t2..t5bound)} do {
          var t6bound: int = min(t5, 32*t3 + 31);
          for t6 in {(32*t3)..t6bound} do {
            for t7 in {(32*t4)..t7bound} do {
              yield (t5+1,t7+1,t6+1, Stmt.updateC);
            }
          }
        }
      }
    }
  }
}


/*    **************************   */
/*     Choose Iterator Function    */
/*    **************************   */

iter chooseIter(param tag: iterKind, n: int, m: int, whichIter: IterChoice): (int, int, int, Stmt)
where tag == iterKind.standalone {
  select whichIter {
    when IterChoice.original do {
      for x in org(n,m) do { yield x; }
    }

    when IterChoice.pluto do {
      for x in pluto(n,m) do { yield x; }
    }


    when IterChoice.ptile do {
      for x in plutoTile(n,m) do { yield x; }
    }

    when IterChoice.ptilepar do {
      for x in plutoTilePar(iterKind.standalone, n,m) do { yield x; }
    }
  }
}






/*                           Initialization                             */
/*    ***************************************************************   */
/*    ***************************************************************   */



proc init(
      n : int, m : int
    , beta : real
    , alpha : real
    , C : [1..N,1..N] real
    , A : [1..N,1..M] real
    , B : [1..N,1..M] real) : void {

  for i in {1..n} do {
    for j in {1..m} do {
      var ii: int = i - 1;
      var jj: int = j - 1;
      A[i,j] = ((((ii*jj)  + 1)% n ) / (n:real)   ):real;
      B[i,j] = ((((ii*jj)  + 2)% m ) / (m:real)   ):real;
    }
  }

  for i in {1..n} do {
    for j in {1..n} do {
      var ii: int = i - 1;
      var jj: int = j - 1;
      C[i,j] = (((ii*jj  + 3)% n ) / (m:real) ):real;
    }
  }

}




/*                                Kernel                                */
/*    ***************************************************************   */
/*    ***************************************************************   */

proc kernel(
      n : int, m : int
    , beta : real
    , alpha : real
    , C : [1..N,1..N] real
    , A : [1..N,1..M] real
    , B : [1..N,1..M] real) : real {

  var timer2: Timer;
  timer2.start();

  var Adelta: recChoice = new recChoice(n, m, A);
  var Bdelta: recChoice = new recChoice(n, m, B);

  for (i,k,j,stmt) in chooseIter(iterKind.standalone,n,m,iterChoice) do {
    select stmt {
      when Stmt.betamult do {
        C[i,k] *= beta;
      }
      when Stmt.updateC do {
        C[i,j] += Adelta[j,k]*alpha*Bdelta[i,k] + Bdelta[j,k]*alpha*Adelta[i,k];
      }
    }
  }

  timer2.stop();
  return (timer2.elapsed():real);
}




/*                                 Main                                 */
/*    ***************************************************************   */
/*    ***************************************************************   */


proc printArr(n : int, C : [1..N,1..N] real) : void {
  for i in {1..n} do {
    for j in {1..n} do {
      writef("%7.3dr", C[i,j]);
      write(" ");
    }
    writeln("");
  }
}



proc main(){
  var n : int = N;
  var m : int = M;
  var FP_ops : real = 3.0 * m * (n+1) * n;
  var footprint : real = 8 * (n * n + 2 * n * m);
  var gfp_ops : real = FP_ops / 1000000000.0;
  writeln("Starting run. n=", N, ", m=", M
      ,", Footprint ", footprint / (1024 * 1024)," M,  Source FP ops=",
      gfp_ops, " G");


  // Variable declaration and initialization
  const alpha : real  = 1.5;
  const beta : real  = 1.2;
  var A : [1..n,1..m] real;
  var B : [1..n,1..m] real;
  var C : [1..n,1..n] real;
  init(n,m,beta,alpha,C,A,B);


  // Time and run kernel

  var timer : Timer;

  writeln("Starting test ...");
  timer.start();
  var innertime:real = kernel(n,m,beta,alpha,C,A,B);
  timer.stop();
  var gflops : real = gfp_ops / timer.elapsed();
  var gflops2 : real = gfp_ops / innertime;
  writeln("GFLOPS rate: ", gflops);
  //writeln("GFLOPS outer rate: ", gflops);
  //writeln("GFLOPS inner rate: ", gflops2);
  //printArr(n,C);

}

