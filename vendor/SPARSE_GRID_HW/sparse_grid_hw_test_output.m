EDU>> sparse_grid_hw
>> sparse_grid_hw_test
10-May-2012 23:33:41

SPARSE_GRID_HW_TEST
  MATLAB version
  Test the SPARSE_GRID_HW library.

CCU_SPARSE_TEST:
  CCU sparse grid:
  Sparse Gaussian unweighted quadrature over [0,1].

   D  Level   Nodes    SG error    MC error

  10      2      21   0.0039099    0.024636
  10      3     221  6.4537e-05   0.0078468
  10      4    1581  1.2369e-07   0.0028145

CCU_TEST:
  Clenshaw Curtis quadrature over [0,1]:

   Level   Nodes    Estimate  Error

   1          1     0.19333   0.0097753
   2          3     0.19147  5.6817e-05
   3          5     0.19146  3.9596e-08
   4          9     0.19146  6.5235e-15
   5         17     0.19146   4.349e-16

GET_SEQ_TEST
  GET_SEQ returns all D-dimensional vectors that sum to NORM.

  D = 3
  NORM = 6
   1:     4   1   1
   2:     3   2   1
   3:     3   1   2
   4:     2   3   1
   5:     2   2   2
   6:     2   1   3
   7:     1   4   1
   8:     1   3   2
   9:     1   2   3
  10:     1   1   4

GQN_SPARSE_TEST:
  GQN sparse grid:
  Gauss quadrature, Hermite weight over (-oo,+oo).

   D  Level   Nodes    SG error    MC error

   5      2      11     0.93333      2.4304
   5      3      61         0.4     0.70213
   5      4     241  5.9212e-16     0.50888

GQN_TEST:
  Gauss-Hermite quadrature over (-oo,+oo):

   Level   Nodes    Estimate  Error

   1          1           0           1
   2          2           1     0.93333
   3          3           9         0.4
   4          4          15  3.5527e-16
   5          5          15  2.3685e-16

GQU_SPARSE_TEST:
  GQU sparse grid:
  Sparse Gaussian unweighted quadrature over [0,1].

   D  Level   Nodes    SG error    MC error

  10      2      21   0.0049444    0.025135
  10      3     221  0.00015519   0.0076167
  10      4    1581  3.5752e-06    0.002932

GQU_TEST:
  Gauss-Legendre quadrature over [0,1]:

   Level   Nodes    Estimate  Error

   1          1     0.19333   0.0097753
   2          2     0.19146  3.7965e-05
   3          3     0.19146  9.4658e-08
   4          4     0.19146  1.7425e-10
   5          5     0.19146  2.5456e-13

KPN_SPARSE_TEST:
  KPN sparse grid:
  Sparse nested, Hermite weight over (-oo,+oo).

   D  Level   Nodes    SG error    MC error

   5      2      11         0.4      2.0391
   5      3      51         0.4     0.96633
   5      4     151  5.4475e-15     0.58763

KPN_TEST:
  Kronrod-Patterson-Hermite quadrature over (-oo,+oo):

   Level   Nodes    Estimate  Error

   1          1           0           1
   2          3           9         0.4
   3          3           9         0.4
   4          7          15   4.737e-16
   5          9          15  1.1842e-16

KPU_SPARSE_TEST:
  KPU sparse grid:
  Sparse nested, unweighted quadrature over [0,1].

   D  Level   Nodes    SG error    MC error

  10      2      21    0.004529    0.025176
  10      3     201  0.00011893   0.0082602
  10      4    1201  2.0738e-06   0.0032182

KPU_TEST:
  Kronrod-Patterson quadrature over [0,1]:

   Level   Nodes    Estimate  Error

   1          1     0.19333   0.0097753
   2          3     0.19146  9.5609e-08
   3          3     0.19146  9.5609e-08
   4          7     0.19146  2.1022e-09
   5          7     0.19146  2.1022e-09

NWSPGR_TEST:
  NWSPGR generates a sparse grid, based on either:
  one of the built-in 1D rules, or a family of 1D rules
  supplied by the user.

  Kronrod-Patterson, [0,1], Dim 2, Level 3

   1:  0.0771605 * f(0.112702,0.112702)
   2:  0.123457 * f(0.112702,0.5)
   3:  0.0771605 * f(0.112702,0.887298)
   4:  0.123457 * f(0.5,0.112702)
   5:  0.197531 * f(0.5,0.5)
   6:  0.123457 * f(0.5,0.887298)
   7:  0.0771605 * f(0.887298,0.112702)
   8:  0.123457 * f(0.887298,0.5)
   9:  0.0771605 * f(0.887298,0.887298)

  Kronrod-Patterson, (-oo,+oo), Dim 2, Level 3

   1:  0.0277778 * f(-1.73205,-1.73205)
   2:  0.111111 * f(-1.73205,0)
   3:  0.0277778 * f(-1.73205,1.73205)
   4:  0.111111 * f(0,-1.73205)
   5:  0.444444 * f(0,0)
   6:  0.111111 * f(0,1.73205)
   7:  0.0277778 * f(1.73205,-1.73205)
   8:  0.111111 * f(1.73205,0)
   9:  0.0277778 * f(1.73205,1.73205)

  Gauss-Legendre, [0,1], Dim 2, Level 3

   1:  0.277778 * f(0.112702,0.5)
   2:  0.25 * f(0.211325,0.211325)
   3:  -0.5 * f(0.211325,0.5)
   4:  0.25 * f(0.211325,0.788675)
   5:  0.277778 * f(0.5,0.112702)
   6:  -0.5 * f(0.5,0.211325)
   7:  0.888889 * f(0.5,0.5)
   8:  -0.5 * f(0.5,0.788675)
   9:  0.277778 * f(0.5,0.887298)
  10:  0.25 * f(0.788675,0.211325)
  11:  -0.5 * f(0.788675,0.5)
  12:  0.25 * f(0.788675,0.788675)
  13:  0.277778 * f(0.887298,0.5)

  Gauss Hermite, (-oo,+oo), Dim 2, Level 3

   1:  0.166667 * f(-1.73205,0)
   2:  0.25 * f(-1,-1)
   3:  -0.5 * f(-1,0)
   4:  0.25 * f(-1,1)
   5:  0.166667 * f(0,-1.73205)
   6:  -0.5 * f(0,-1)
   7:  1.33333 * f(0,0)
   8:  -0.5 * f(0,1)
   9:  0.166667 * f(0,1.73205)
  10:  0.25 * f(1,-1)
  11:  -0.5 * f(1,0)
  12:  0.25 * f(1,1)
  13:  0.166667 * f(1.73205,0)

  Clenshaw Curtis, [-1,+1], Dim 2, Level 3

   1:  0.0277778 * f(0,0)
   2:  -0.0222222 * f(0,0.5)
   3:  0.0277778 * f(0,1)
   4:  0.266667 * f(0.146447,0.5)
   5:  -0.0222222 * f(0.5,0)
   6:  0.266667 * f(0.5,0.146447)
   7:  -0.0888889 * f(0.5,0.5)
   8:  0.266667 * f(0.5,0.853553)
   9:  -0.0222222 * f(0.5,1)
  10:  0.266667 * f(0.853553,0.5)
  11:  0.0277778 * f(1,0)
  12:  -0.0222222 * f(1,0.5)
  13:  0.0277778 * f(1,1)

ORDER_REPORT
  For each family of rules, report:
  L,  the level index,
  RP, the required polynomial precision,
  AP, the actual polynomial precision,
  O,  the rule order (number of points).

  GQN family
  Gauss quadrature, exponential weight, (-oo,+oo)

   L  RP  AP   O

   1   1   1   1
   2   3   3   2
   3   5   5   3
   4   7   7   4
   5   9   9   5
   6  11  11   6
   7  13  13   7
   8  15  15   8
   9  17  17   9
  10  19  19  10
  11  21  21  11
  12  23  23  12
  13  25  25  13
  14  27  27  14
  15  29  29  15
  16  31  31  16
  17  33  33  17
  18  35  35  18
  19  37  37  19
  20  39  39  20
  21  41  41  21
  22  43  43  22
  23  45  45  23
  24  47  47  24
  25  49  49  25

  GQU family
  Gauss quadrature, unit weight, [0,1]

   L  RP  AP   O

   1   1   1   1
   2   3   3   2
   3   5   5   3
   4   7   7   4
   5   9   9   5
   6  11  11   6
   7  13  13   7
   8  15  15   8
   9  17  17   9
  10  19  19  10
  11  21  21  11
  12  23  23  12
  13  25  25  13
  14  27  27  14
  15  29  29  15
  16  31  31  16
  17  33  33  17
  18  35  35  18
  19  37  37  19
  20  39  39  20
  21  41  41  21
  22  43  43  22
  23  45  45  23
  24  47  47  24
  25  49  49  25

  KPN family
  Gauss-Kronrod-Patterson quadrature, exponential weight, (-oo,+oo)

   L  RP  AP   O

   1   1   1   1
   2   3   5   3
   3   5   5   3
   4   7   7   7
   5   9  15   9
   6  11  15   9
   7  13  15   9
   8  15  15   9
   9  17  17  17
  10  19  29  19
  11  21  29  19
  12  23  29  19
  13  25  29  19
  14  27  29  19
  15  29  29  19
  16  31  31  31
  17  33  33  33
  18  35  51  35
  19  37  51  35
  20  39  51  35
  21  41  51  35
  22  43  51  35
  23  45  51  35
  24  47  51  35
  25  49  51  35

  KPU family
  Gauss-Kronrod-Patterson quadrature, unit weight, [0,1]

   L  RP  AP   O

   1   1   1   1
   2   3   5   3
   3   5   5   3
   4   7  11   7
   5   9  11   7
   6  11  11   7
   7  13  23  15
   8  15  23  15
   9  17  23  15
  10  19  23  15
  11  21  23  15
  12  23  23  15
  13  25  47  31
  14  27  47  31
  15  29  47  31
  16  31  47  31
  17  33  47  31
  18  35  47  31
  19  37  47  31
  20  39  47  31
  21  41  47  31
  22  43  47  31
  23  45  47  31
  24  47  47  31
  25  49  95  63

TENSOR_PRODUCT_TEST:
  Given a sequence of 1D quadrature rules, construct the
  tensor product rule.

  A 1D rule over [-1,+1]:

   1:  1 * f(-1)
   2:  1 * f(1)

  A 2D rule over [-1,+1] x [2.0,3.0]:

   1:  0.25 * f(-1,2)
   2:  0.5 * f(-1,2.5)
   3:  0.25 * f(-1,3)
   4:  0.25 * f(1,2)
   5:  0.5 * f(1,2.5)
   6:  0.25 * f(1,3)

  A 3D rule over [-1,+1] x [2.0,3.0] x [10.0,15.0]:

   1:  0.625 * f(-1,2,10)
   2:  0.625 * f(-1,2,15)
   3:  1.25 * f(-1,2.5,10)
   4:  1.25 * f(-1,2.5,15)
   5:  0.625 * f(-1,3,10)
   6:  0.625 * f(-1,3,15)
   7:  0.625 * f(1,2,10)
   8:  0.625 * f(1,2,15)
   9:  1.25 * f(1,2.5,10)
  10:  1.25 * f(1,2.5,15)
  11:  0.625 * f(1,3,10)
  12:  0.625 * f(1,3,15)

SPARSE_GRID_HW_TEST
  Normal end of execution.

10-May-2012 23:33:49
>>
 