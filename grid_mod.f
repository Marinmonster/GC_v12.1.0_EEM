! $Id: grid_mod.f,v 1.1 2003/06/30 20:26:02 bmy Exp $
      MODULE GRID_MOD
!
!******************************************************************************
!  Module GRID_MOD contains variables and routines which are used to specify 
!  the parameters of a GEOS-CHEM horizontal grid. (bmy, 3/11/03, 4/28/03)
!
!  Module Variables:
!  ============================================================================
!  (1 ) IS_NESTED  (LOGICAL) : =T if we are using a nested-grid 
!  (2 ) IIGLOB     (INTEGER) : Global longitude extent [# of boxes]
!  (3 ) JJGLOB     (INTEGER) : Global latitude  extent [# of boxes]
!  (4 ) I0         (INTEGER) : Nested-grid offset in longitude (X) dimension
!  (5 ) J0         (INTEGER) : Nested-grid offset in latitude  (Y) dimension
!  (6 ) XMID_G     (REAL*8 ) : GLOBAL array of grid-box lon centers [degrees]
!  (7 ) XEDGE_G    (REAL*8 ) : GLOBAL array of grid-box lon edges   [degrees]
!  (8 ) YMID_G     (REAL*8 ) : GLOBAL array of grid-box lat centers [degrees]
!  (9 ) YEDGE_G    (REAL*8 ) : GLOBAL array of grid-box lat edges   [degrees]
!  (10) YMID_R_G   (REAL*8 ) : GLOBAL array of grid-box lat centers [radians]
!  (11) YEDGE_R_G  (REAL*8 ) : GLOBAL array of grid-box lat edges   [radians]
!  (12) AREA_M2_G  (REAL*8 ) : GLOBAL array of grid-box surface areas [m2]
!  (13) AREA_CM2_G (REAL*8 ) : GLOBAL array of grid-box surface areas [cm2]
!  (14) XMID       (REAL*8 ) : WINDOW array of grid-box lon centers [degrees]
!  (15) XEDGE      (REAL*8 ) : WINDOW array of grid-box lon edges   [degrees]
!  (16) YMID       (REAL*8 ) : WINDOW array of grid-box lat centers [degrees]
!  (17) YEDGE      (REAL*8 ) : WINDOW array of grid-box lat edges   [degrees]
!  (18) YMID_R     (REAL*8 ) : WINDOW array of grid-box lat centers [radians]
!  (19) YEDGE_R    (REAL*8 ) : WINDOW array of grid-box lat edges   [radians]
!  (20) AREA_M2    (REAL*8 ) : WINDOW array of grid-box surface areas [m2]
!  (21) AREA_CM2   (REAL*8 ) : WINDOW array of grid-box surface areas [cm2]
!
!  Module Routines:
!  ============================================================================
!  (1 ) COMPUTE_GRID      : Computes all lon, lat, surface area quantities
!  (2 ) SET_XOFFSET       : Initializes nested grid longitude (X) offset
!  (3 ) SET_YOFFSET       : Initializes nested grid latitude  (Y) offset
!  (4 ) GET_XOFFSET       : Returns     nested grid longitude (X) offset
!  (5 ) GET_XOFFSET       : Returns     nested grid latitude  (Y) offset
!  (6 ) GET_XMID          : Returns grid box center  longitude [degrees]
!  (7 ) GET_XEDGE         : Returns grid box W. edge longitude [degrees]
!  (8 ) GET_YMID          : Returns grid box center  latitude  [degrees]
!  (9 ) GET_YEDGE         : Returns grid box S. edge latitude  [degrees]
!  (10) GET_YMID_R        : Returns grid box center  latitude  [radians]
!  (11) GET_YEDGE_R       : Returns grid box S. edge latitude  [radians]
!  (12) GET_AREA_M2       : Returns grid box surface area      [m2]
!  (13) GET_AREA_CM2      : Returns grid box surface area      [cm2]
!  (14) ITS_A_NESTED_GRID : Returns T for nested grid simulations; F otherwise
!  (15) INIT_GRID         : Allocates and zeroes all module arrays
!  (16) CLEANUP_GRID      : Deallocates all module arrays
!
!  GEOS-CHEM modules referenced by grid_mod.f:
!  ============================================================================
!  (1 ) error_mod.f       : Module containing I/O error and NaN check routines
!
!  NOTES:
!  (1 ) Fixed typos in "grid_mod.f" (bmy, 4/28/03)
!******************************************************************************
!
      IMPLICIT NONE

      !=================================================================
      ! MODULE PRIVATE DECLARATIONS -- keep certain internal variables 
      ! and routines from being seen outside "grid_mod.f"
      !=================================================================
      PRIVATE :: I0,       J0,        IIGLOB,    JJGLOB
      PRIVATE :: XMID_G,   XEDGE_G,   YMID_G,    YEDGE_G 
      PRIVATE :: YMID_R_G, YEDGE_R_G, AREA_M2_G, AREA_CM2_G
      PRIVATE :: XMID,     XEDGE,     YMID,      YEDGE 
      PRIVATE :: YMID_R,   YEDGE_R,   AREA_M2,   AREA_CM2
      PRIVATE :: IS_NESTED

      !==================================================================
      ! MODULE VARIABLES
      !==================================================================
      LOGICAL              :: IS_NESTED
      INTEGER              :: I0,           J0
      INTEGER              :: IIGLOB,       JJGLOB
      REAL*8,  ALLOCATABLE :: XMID_G(:),    XEDGE_G(:)
      REAL*8,  ALLOCATABLE :: YMID_G(:),    YEDGE_G(:)
      REAL*8,  ALLOCATABLE :: YMID_R_G(:),  YEDGE_R_G(:)
      REAL*8,  ALLOCATABLE :: AREA_M2_G(:), AREA_CM2_G(:)
      REAL*8,  ALLOCATABLE :: XMID(:),      XEDGE(:)
      REAL*8,  ALLOCATABLE :: YMID(:),      YEDGE(:)
      REAL*8,  ALLOCATABLE :: YMID_R(:),    YEDGE_R(:)
      REAL*8,  ALLOCATABLE :: AREA_M2(:),   AREA_CM2(:)

      !=================================================================
      ! MODULE ROUTINES -- follow below the "CONTAINS" statement 
      !=================================================================
      CONTAINS

!------------------------------------------------------------------------------

      SUBROUTINE COMPUTE_GRID
!
!******************************************************************************
!  Subroutine COMPUTE_GRID initializes the longitude, latitude and surface 
!  area arrays. (bmy, 3/11/03)
!
!  NOTES:
!******************************************************************************
!
#     include "CMN_SIZE"  ! Size parameters
#     include "CMN_GCTM"  ! Physical constants

      ! Local variables
      LOGICAL, SAVE       :: FIRST = .TRUE.
      INTEGER             :: I,    J
      REAL*8              :: FMID, FEDGE

      !=================================================================
      ! COMPUTE_GRID begins here!
      !=================================================================

      ! Allocate variables on first call
      IF ( FIRST ) THEN
         CALL INIT_GRID
         FIRST = .FALSE.
      ENDIF

      !=================================================================
      ! Compute latitude centers & edges (algorithm from old "input.f")
      ! Now save to global-sized arrays for the sake of iterating
      !=================================================================
      FMID  = 0.5d0 * DBLE( JJGLOB + 1 )
      FEDGE = 0.5d0 * DBLE( JJGLOB + 2 )

      DO J = 1, JJGLOB
         YMID_G(J)  = DJSIZE * ( DBLE(J) - FMID  )
         YEDGE_G(J) = DJSIZE * ( DBLE(J) - FEDGE )
      ENDDO
      
#if   defined( GRID4x5 )
      ! Overwrite YMID at poles for 4 x 5 grid
      YMID_G(1)      = -89.d0
      YMID_G(JJGLOB) = +89.d0

#elif defined( GRID2x25 )
      ! Overwrite YMID at poles for 2 x 2.5 grid
      YMID_G(1)      = -89.5d0
      YMID_G(JJGLOB) = +89.5d0

#elif defined ( GRID1x1 )
      ! Overwrite YMID at poles for 1 x 1 grid
      YMID_G(1)      = -89.75d0
      YMID_G(JJGLOB) = +89.75d0

#endif

      ! Overwrite YEDGE at poles
      YEDGE_G(1)        = -90d0
      YEDGE_G(JJGLOB+1) = +90d0

      ! Compute latitude center/edges in radians
      DO J = 1, JJGLOB
         YMID_R_G(J)  = ( PI / 180d0 ) * YMID_G(J)
         YEDGE_R_G(J) = ( PI / 180d0 ) * YEDGE_G(J)
      ENDDO
         
      ! Overwrite RLATV at N. pole
      YEDGE_R_G(JJGLOB+1) = PI / 2d0

      !=================================================================
      ! Compute longitude centers & edges (algorithm from old "input.f")
      ! Now save to global-sized arrays for the sake of iterating
      !=================================================================      
      XMID_G(1)  = -180d0
      XEDGE_G(1) = XMID_G(1) - ( DISIZE / 2d0 )

      DO I = 1, IIGLOB-1
         XMID_G(I+1)  = XMID_G(I)  + DISIZE
      ENDDO

      DO I = 1, IIGLOB
         XEDGE_G(I+1) = XEDGE_G(I) + DISIZE 
      ENDDO
      
      !=================================================================
      ! Compute surface areas (algorithm from old "input.f")
      ! Now save to global-sized arrays for the sake of iterating
      !=================================================================  
      DO J = 1, JJGLOB

         ! Area in m2 (symmetric in longitude)
         AREA_M2_G(J) = 2d0 * PI * Re * Re / DBLE( IIGLOB ) *
     &                  ( SIN( YEDGE_R_G(J+1) ) - SIN( YEDGE_R_G(J) ) ) 

         ! Area in cm2 (symmetric in longitude)
         AREA_CM2_G(J) = AREA_M2_G(J) * 1d4

      ENDDO

      !=================================================================
      ! Save to local size arrays so that we can index for all grids
      !=================================================================
      
      ! XMID
      DO I = 1, IIPAR
         XMID(I) = XMID_G(I+I0)
      ENDDO

      ! XEDGE
      DO I = 1, IIPAR+1
         XEDGE(I) = XEDGE_G(I+I0)
      ENDDO

      ! YMID, YMID_R, AREA_M2, AREA_CM2
      DO J = 1, JJPAR
         YMID(J)     = YMID_G(J+J0)
         YMID_R(J)   = YMID_R_G(J+J0)
         AREA_M2(J)  = AREA_M2_G(J+J0)
         AREA_CM2(J) = AREA_CM2_G(J+J0)
      ENDDO

      ! YEDGE, YEDGE_R
      DO J = 1, JJPAR+1
         YEDGE(J)   = YEDGE_G(J+J0)
         YEDGE_R(J) = YEDGE_R_G(J+J0)
      ENDDO

      !=================================================================
      ! Echo info to stdout
      !=================================================================
      WRITE( 6, '(a)' ) REPEAT( '=', 79 )
      WRITE( 6, '(a)' ) 'COMPUTE_GRID: Horizontal Grid Information!'
      WRITE( 6, '(a)' ) 
      WRITE( 6, '(''Nested-Grid X-offset (boxes) :'', i4 )' ) I0
      WRITE( 6, '(''Nested-Grid Y-offset (boxes) :'', i4 )' ) J0
      WRITE( 6, '(a)' )
      WRITE( 6, '(''Grid box longitude centers (degrees): '')' )
      WRITE( 6, '(8(f8.3,1x))' ) ( XMID(I),  I=1,IIPAR )
      WRITE( 6, '(a)' )
      WRITE( 6, '(''Grid box longitude edges (degrees): '')' )
      WRITE( 6, '(8(f8.3,1x))' ) ( XEDGE(I), I=1,IIPAR+1 )
      WRITE( 6, '(a)' )
      WRITE( 6, '(''Grid box latitude centers (degrees): '')' )
      WRITE( 6, '(8(f8.3,1x))' ) ( YMID(J),  J=1,JJPAR )
      WRITE( 6, '(a)' )
      WRITE( 6, '(''Grid box latitude edges (degrees): '')' )
      WRITE( 6, '(8(f8.3,1x))' ) ( YEDGE(J), J=1,JJPAR+1 )
      WRITE( 6, '(a)' ) REPEAT( '=', 79 )

      !=================================================================
      ! Deallocate global arrays -- we don't need these anymore
      !=================================================================
      IF ( ALLOCATED( XMID_G     ) ) DEALLOCATE( XMID_G     )
      IF ( ALLOCATED( XEDGE_G    ) ) DEALLOCATE( XEDGE_G    )
      IF ( ALLOCATED( YMID_G     ) ) DEALLOCATE( YMID_G     )
      IF ( ALLOCATED( YEDGE_G    ) ) DEALLOCATE( YEDGE_G    )
      IF ( ALLOCATED( YMID_R_G   ) ) DEALLOCATE( YMID_R_G   )
      IF ( ALLOCATED( YEDGE_R_G  ) ) DEALLOCATE( YEDGE_R_G  )
      IF ( ALLOCATED( AREA_M2_G  ) ) DEALLOCATE( AREA_M2_G  )
      IF ( ALLOCATED( AREA_CM2_G ) ) DEALLOCATE( AREA_CM2_G )

      ! Return to calling program
      END SUBROUTINE COMPUTE_GRID
      
!------------------------------------------------------------------------------

      SUBROUTINE SET_XOFFSET( X_OFFSET )
!
!******************************************************************************
!  Function SET_XOFFSET initializes the nested-grid latitude offset 
!  variable I0. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) X_OFFSET (INTEGER) : Nested grid longitude offset (# of grid boxes)
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: X_OFFSET

      !=================================================================
      ! SET_XOFFSET begins here!
      !=================================================================
      I0 = X_OFFSET

      ! Return to calling program
      END SUBROUTINE SET_XOFFSET

!------------------------------------------------------------------------------

      SUBROUTINE SET_YOFFSET( Y_OFFSET )
!
!******************************************************************************
!  Function SET_YOFFSET initializes the nested-grid latitude offset 
!  variable J0. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) Y_OFFSET (INTEGER) : Nested grid latitude offset (# of grid boxes)
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: Y_OFFSET

      !=================================================================
      ! SET_XOFFSET begins here!
      !=================================================================
      J0 = Y_OFFSET

      ! Return to calling program
      END SUBROUTINE SET_YOFFSET

!------------------------------------------------------------------------------

      FUNCTION GET_XOFFSET( GLOBAL ) RESULT( X_OFFSET )
!
!******************************************************************************
!  Function GET_XOFFSET returns the nested-grid longitude offset to the
!  calling program. (bmy, 3/11/03)
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      LOGICAL, INTENT(IN), OPTIONAL :: GLOBAL

      ! Function value
      INTEGER :: X_OFFSET

      !=================================================================
      ! GET_XOFFSET begins here!
      !=================================================================
      IF ( PRESENT( GLOBAL ) ) THEN

         ! If GLOBAL is passed, then return the actual window offset.
         ! This is necessary for certain instances (e.g. diagnostics)
         X_OFFSET = I0

      ELSE

         ! Otherwise, if we have a nested grid, then all of the met
         ! fields have been cut down to size already.  Return 0.
         X_OFFSET = 0

      ENDIF

      ! Return to calling program
      END FUNCTION GET_XOFFSET

!------------------------------------------------------------------------------

      FUNCTION GET_YOFFSET( GLOBAL ) RESULT( Y_OFFSET )
!
!******************************************************************************
!  Function GET_YOFFSET returns the nested-grid latitude offset to the
!  calling program. (bmy, 3/11/03)
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      LOGICAL, INTENT(IN), OPTIONAL :: GLOBAL

      ! Function value
      INTEGER :: Y_OFFSET

      !=================================================================
      ! GET_XOFFSET begins here!
      !=================================================================
      IF ( PRESENT( GLOBAL ) ) THEN 

         ! If GLOBAL is passed, then return the actual window offset.
         ! This is necessary for certain instances (e.g. diagnostics)
         Y_OFFSET = J0

      ELSE

         ! Otherwise, if we have a nested grid, then all of the met
         ! fields have been cut down to size already.  Return 0.
         Y_OFFSET = 0

      ENDIF

      ! Return to calling program
      END FUNCTION GET_YOFFSET

!------------------------------------------------------------------------------

      FUNCTION GET_XMID( I ) RESULT( X )
!
!******************************************************************************
!  Function GET_XMID returns the longitude in degrees at the center of a 
!  GEOS-CHEM grid box.  Works for nested-grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1) I (INTEGER) : GEOS-CHEM grid-box index for longitude
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I

      ! Function value
      REAL*8              :: X 

      !=================================================================
      ! GET_XMID begins here!
      !=================================================================
      X = XMID( I )

      ! Return to calling program
      END FUNCTION GET_XMID

!------------------------------------------------------------------------------

      FUNCTION GET_XEDGE( I ) RESULT( X )
!
!******************************************************************************
!  Function GET_XEDGE returns the longitude in degrees at the western edge of 
!  a GEOS-CHEM grid box.  Works for nested-grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1) I (INTEGER) : GEOS-CHEM grid-box index for longitude
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I

      ! Function value
      REAL*8              :: X 

      !=================================================================
      ! GET_XEDGE begins here!
      !=================================================================
      X = XEDGE( I )

      ! Return to calling program
      END FUNCTION GET_XEDGE

!------------------------------------------------------------------------------

      FUNCTION GET_YMID( J ) RESULT( Y )
!
!******************************************************************************
!  Function GET_YMID returns the latitude in degrees at the center of 
!  a GEOS-CHEM grid box.  Works for nested grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1) I (INTEGER) : GEOS-CHEM grid-box index for latitude
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: J

      ! Function value
      REAL*8              :: Y

      !=================================================================
      ! GET_YMID begins here!
      !=================================================================
      Y = YMID( J )

      ! Return to calling program
      END FUNCTION GET_YMID

!------------------------------------------------------------------------------

      FUNCTION GET_YEDGE( J ) RESULT( Y )
!
!******************************************************************************
!  Function GET_EDGE returns the latitude in degrees at the southern edge of 
!  a GEOS-CHEM grid box.  Works for nested grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1) J (INTEGER) : GEOS-CHEM grid-box index for latitude
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: J

      ! Function value
      REAL*8              :: Y

      !=================================================================
      ! GET_YEDGE begins here!
      !=================================================================
      Y = YEDGE( J )

      ! Return to calling program
      END FUNCTION GET_YEDGE

!------------------------------------------------------------------------------

      FUNCTION GET_YMID_R( J ) RESULT( Y )
!
!******************************************************************************
!  Function GET_YMID_R returns the latitude in radians at the center of 
!  a GEOS-CHEM grid box.  Works for nested grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1) J (INTEGER) : GEOS-CHEM grid-box index for latitude
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: J

      ! Function value
      REAL*8              :: Y

      !=================================================================
      ! GET_YMID_R begins here!
      !=================================================================
      Y = YMID_R( J )

      ! Return to calling program
      END FUNCTION GET_YMID_R

!------------------------------------------------------------------------------

      FUNCTION GET_YEDGE_R( J ) RESULT( Y )
!
!******************************************************************************
!  Function GET_YEDGE_R returns the latitude in radians at the southern edge 
!  of a GEOS-CHEM grid box.  Works for nested grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1) J (INTEGER) : GEOS-CHEM grid-box index for latitude
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: J

      ! Function value
      REAL*8              :: Y

      !=================================================================
      ! GET_YEDGE_R begins here!
      !=================================================================
      Y = YEDGE_R( J )

      ! Return to calling program
      END FUNCTION GET_YEDGE_R

!------------------------------------------------------------------------------

      FUNCTION GET_AREA_M2( J ) RESULT( A )
!
!******************************************************************************
!  Function GET_AREA_M2 returns the surface area [m2] of a GEOS-CHEM 
!  grid box.  Works for nested grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) J (INTEGER) : GEOS-CHEM grid-box index for latitude
!
!  NOTES:
!  (1 ) Surface area is only a function of latitude, since all grid boxes are 
!        symmetrical in longitude. (bmy, 3/11/03)
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: J

      ! Function value
      REAL*8              :: A

      !=================================================================
      ! GET_AREA_M2 begins here!
      !=================================================================
      A = AREA_M2( J )

      ! Return to calling program
      END FUNCTION GET_AREA_M2

!------------------------------------------------------------------------------

      FUNCTION GET_AREA_CM2( J ) RESULT( A )
!
!******************************************************************************
!  Function GET_AREA_CM2 returns the surface area [cm2] of a GEOS-CHEM 
!  grid box.  Works for nested grids too. (bmy, 3/11/03)
!
!  Arguments as Input:
!  ============================================================================
!  (1) J (INTEGER) : GEOS-CHEM grid-box index for latitude
!
!  NOTES:
!  (1 ) Surface area is only a function of latitude, since all grid boxes are 
!        symmetrical in longitude. (bmy, 3/11/03)
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: J

      ! Function value
      REAL*8              :: A

      !=================================================================
      ! GET_AREA_CM2 begins here!
      !=================================================================
      A = AREA_CM2( J )

      ! Return to calling program
      END FUNCTION GET_AREA_CM2

!------------------------------------------------------------------------------

      FUNCTION ITS_A_NESTED_GRID() RESULT( IT_IS_NESTED )
!
!******************************************************************************
!  Subroutine ITS_A_NESTED_GRID returns TRUE if we are using a nested-grid
!  (i.e. a subset of a global grid) or FALSE otherwise. (bmy, 3/11/03)
!
!  NOTES:
!******************************************************************************
!
      ! Function value
      LOGICAL :: IT_IS_NESTED

      !=================================================================
      ! ITS_A_NESTED_GRID begins here!
      !=================================================================
      IT_IS_NESTED = IS_NESTED

      ! Return to calling program
      END FUNCTION ITS_A_NESTED_GRID

!------------------------------------------------------------------------------

      SUBROUTINE INIT_GRID
!
!******************************************************************************
!  Subroutine INIT_GRID initializes variables and allocates module arrays.
!  (bmy, 3/11/03, 4/28/03)
!
!  NOTES:
!  (1 ) Fixed typos that caused AREA_CM2_G and AREA_CM2 to be initialized 
!        before they were allocated. (bmy, 4/28/03)
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD, ONLY : ALLOC_ERR

#     include "CMN_SIZE"

      ! Local variables
      INTEGER :: AS

      !=================================================================
      ! INIT_GRID begins here!
      !=================================================================

      ! Define global sizes for grid.  We need to redefine these here
      ! since for the nested grid, we set IGLOB=IIPAR and JGLOB=JJPAR
#if   defined( GRID1x1 )
      IIGLOB = 360
      JJGLOB = 181
#elif defined( GRID2x25 )
      IIGLOB = 144
      JJGLOB = 91
#elif defined( GRID4x5 ) 
      IIGLOB = 72
      JJGLOB = 46
#endif

      !=================================================================
      ! Allocate global-sized arrays (e.g. use IIGLOB, JJGLOB)
      !=================================================================
      ALLOCATE( XMID_G( IIGLOB ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'XMID_G' )
      XMID_G = 0

      ALLOCATE( XEDGE_G( IIGLOB+1 ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'XEDGE_G' )
      XEDGE_G = 0d0

      ALLOCATE( YMID_G( JJGLOB ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YMID_G' )
      YMID_G = 0d0

      ALLOCATE( YEDGE_G( JJGLOB+1 ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YEDGE_G' )
      YEDGE_G = 0d0

      ALLOCATE( YMID_R_G( JJGLOB ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YMID_R_G' )
      YMID_R_G = 0d0

      ALLOCATE( YEDGE_R_G( JJGLOB+1 ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YEDGE_R_G' )
      YEDGE_R_G = 0d0

      ALLOCATE( AREA_M2_G( JJGLOB ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AREA_M2_G' )
      AREA_M2_G = 0d0

      ALLOCATE( AREA_CM2_G( JJGLOB ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AREA_CM2_G' )
      AREA_CM2_G = 0d0      

      !=================================================================
      ! Allocate window-sized arrays (e.g. use IIPAR, JJPAR)
      !=================================================================
      ALLOCATE( XMID( IIPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'XMID' )
      XMID = 0

      ALLOCATE( XEDGE( IIPAR+1 ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'XEDGE' )
      XEDGE = 0d0

      ALLOCATE( YMID( JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YMID' )
      YMID = 0d0

      ALLOCATE( YEDGE( JJPAR+1 ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YEDGE' )
      YEDGE = 0d0

      ALLOCATE( YMID_R( JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YMID_R' )
      YMID_R = 0d0

      ALLOCATE( YEDGE_R( JJPAR+1 ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'YEDGE_R' )
      YEDGE_R = 0d0

      ALLOCATE( AREA_M2( JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AREA_M2' )
      AREA_M2 = 0d0

      ALLOCATE( AREA_CM2( JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AREA_CM2' )
      AREA_CM2 = 0d0

      !=================================================================
      ! Also test for 1x1 nested-grid (smaller than global size)
      !=================================================================
      IF ( IIPAR == IIGLOB .and. JJPAR == JJGLOB ) THEN
         IS_NESTED = .FALSE.
      ELSE
         IS_NESTED = .TRUE.
      ENDIF

      ! Return to calling program
      END SUBROUTINE INIT_GRID

!------------------------------------------------------------------------------

      SUBROUTINE CLEANUP_GRID
!
!******************************************************************************
!  Subroutine CLEANUP_GRID deallocates all module arrays (bmy, 3/11/03)
!
!  NOTES:
!******************************************************************************
!
      !=================================================================
      ! CLEANUP_GRID begins here!
      !=================================================================

      ! Deallocate window arrays
      IF ( ALLOCATED( XMID       ) ) DEALLOCATE( XMID       )
      IF ( ALLOCATED( XEDGE      ) ) DEALLOCATE( XEDGE      )
      IF ( ALLOCATED( YMID       ) ) DEALLOCATE( YMID       )
      IF ( ALLOCATED( YEDGE      ) ) DEALLOCATE( YEDGE      )
      IF ( ALLOCATED( YMID_R     ) ) DEALLOCATE( YMID_R     )
      IF ( ALLOCATED( YEDGE_R    ) ) DEALLOCATE( YEDGE_R    )
      IF ( ALLOCATED( AREA_M2    ) ) DEALLOCATE( AREA_M2    )
      IF ( ALLOCATED( AREA_CM2   ) ) DEALLOCATE( AREA_CM2   )

      ! Return to calling program
      END SUBROUTINE CLEANUP_GRID

!------------------------------------------------------------------------------

      END MODULE GRID_MOD
