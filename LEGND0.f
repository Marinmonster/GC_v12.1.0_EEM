C $Id: LEGND0.f,v 1.1 2003/06/30 20:26:08 bmy Exp $
      SUBROUTINE LEGND0 (X,PL,N)
C---Calculates ORDINARY LEGENDRE fns of X (real) 
C---   from P[0] = PL(1) = 1,  P[1] = X, .... P[N-1] = PL(N)
      IMPLICIT NONE
      INTEGER N,I
      REAL*8 X,PL(N),DEN
C---Always does PL(2) = P[1]
        PL(1) = 1.D0
        PL(2) = X
        DO I=3,N
         DEN = (I-1)
         PL(I) = PL(I-1)*X*(2.d0-1.D0/DEN) - PL(I-2)*(1.d0-1.D0/DEN)
        ENDDO
      RETURN
      END
