C $Id: NOABS.f,v 1.1 2003/06/30 20:26:01 bmy Exp $
      SUBROUTINE NOABS(XLO3,XLO2,XLRAY,BCAER,RFLECT)
C-----------------------------------------------------------------------
C  Zero out absorption terms to check scattering code. Leave a little
C  Rayleigh to provide a minimal optical depth, and set surface albedo
C  to unity.
C-----------------------------------------------------------------------
      IMPLICIT NONE
      real*8 XLO3,XLO2,XLRAY,BCAER,RFLECT
      XLO3=0.d0
      XLO2=0.d0
      XLRAY=XLRAY*1.d-10
      BCAER=0.d0      
      RFLECT=1.d0
      RETURN
      END
