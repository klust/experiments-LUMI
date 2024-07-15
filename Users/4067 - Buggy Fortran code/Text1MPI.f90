PROGRAM Parallel_Metropolis_Algorithm
USE MPI
IMPLICIT NONE
INTEGER,PARAMETER::N_Tau12=1                   ! Total number of half-period steps
INTEGER,PARAMETER::L=48, N=L**3  							  ! Lx= Ly= Lz= L
INTEGER,PARAMETER::N_Sample=1        
INTEGER,PARAMETER::TNP=1                      ! Total number of period
INTEGER,PARAMETER::TNDP=0                     ! Total number of discarded period
INTEGER,DIMENSION(2)::Myneigbrs
INTEGER,ALLOCATABLE, DIMENSION(:,:,:)::Spin
INTEGER::Mynrows
INTEGER::I,J,K,II, IJ,Sample,MCS
INTEGER,DIMENSION(1000)::Seed
INTEGER::Count
INTEGER::Initial_Tau12,Final_Tau12,Tau12_Step
INTEGER::Tau,Total_Period,dTau12,Tau_12
INTEGER::N_MCSS, N_Equilibration
REAL*8,ALLOCATABLE,DIMENSION(:)::M_t_Local, M_t_GLOBAL	    ! Keeping the magnetization at time "t" for each and all processors, respectively.
REAL*8,ALLOCATABLE,DIMENSION(:,:)::ML_t_Local, ML_t_GLOBAL, ML_Global 
REAL*8,ALLOCATABLE,DIMENSION(:)::E_t_Local, E_t_GLOBAL    	! Keeping the energy at time "t" for each and all processors, respectively.
REAL*8,ALLOCATABLE,DIMENSION(:)::M_Global, E_Global
REAL*8,DIMENSION(0:N_Tau12)::Q_Global,Q_Global2,Q_Global4
REAL*8,DIMENSION(1:L,0:N_Tau12)::QL_Global,QL_Global2,QL_Global4
REAL*8,DIMENSION(0:N_Tau12)::EQ_Global,EQ_Global2
REAL*8::J1,T,Delta                                          !	Spin-spin coupling, temperature and the crystal field coupling
REAL*8::M                                                   ! Magnetization
REAL*8,ALLOCATABLE,DIMENSION(:)::ML, ML_0
REAL*8,DIMENSION(6)::JJ      
REAL*8::JS,JB                                               
REAL*8::E, E_J, E_H, E_D      									            ! Keeping the energy in a MC sweep for each and all processors, respectively
REAL*8::Suscep, HCap, Binder     
REAL*8, DIMENSION(L):: SuscepL, BinderL                     
REAL*8::Start1,Finish1,Total_Time,Total_Time_Max
REAL*8::M_Per_Site, E_Per_Site, X, Y, Z
REAL*8::h_0, Mag_Field, tau12_c
!Variables about mpi
INTEGER::Ierr,Myid,Nprocs,Nloc,Comm,STATUS(MPI_STATUS_SIZE),Tag
INTEGER,ALLOCATABLE,DIMENSION(:)::Nrows, disp


 ! Initialize MPI
CALL MPI_INIT(Ierr) 
CALL MPI_COMM_RANK(MPI_COMM_WORLD, Myid, Ierr )
CALL MPI_COMM_SIZE(MPI_COMM_WORLD, Nprocs, Ierr )

IF (Myid.EQ.0) THEN
 	OPEN(UNIT=1,FILE="M_vs_P.txt",STATUS="UNKNOWN")
 	OPEN(UNIT=2,FILE="E_vs_P.txt",STATUS="UNKNOWN")
 	OPEN(UNIT=3,FILE="B_vs_P.txt",STATUS="UNKNOWN")
  OPEN(UNIT=4,FILE="Ms_vs_P.txt",STATUS="UNKNOWN")
  OPEN(UNIT=5,FILE="Mb_vs_P.txt",STATUS="UNKNOWN")
 END IF



JB=1.0d0       ! Spin-Spin coupling OF THE BULK
JS=1.4d0       ! Spin-Spin coupling OF THE SURFACE
T=2.579169*0.8d0   ! Temperature fixed as 0.8Tc(Tc is the critical point of 3D bulk spin-1 model)
h_0=0.6d0			 ! Amplitude of external field
Delta=0.655D0    !Crystal field
tau12_c=55.5d0


Initial_Tau12=80    ! Initial Tau12
Final_Tau12=80    ! Final Tau12 
Tau12_Step=(Final_Tau12-Initial_Tau12)/N_Tau12 ! Tau12 Step

! Determine Neighbour Processors 
Myneigbrs(1)=modulo(Myid-1,Nprocs)
Myneigbrs(2)=modulo(Myid+1,Nprocs)


! Number of rows per cpu = L/nprocs
!Calculate the number of rows per processor (array nrows)
ALLOCATE(Nrows(Nprocs))
DO I=1, Nprocs
  IF(I.LE.MOD(L, Nprocs)) THEN
    Nrows(I)=L/nprocs+1
  ELSE
    Nrows(I)=L/nprocs
  END IF
END DO

 Mynrows=NROWS(Myid+1)


!WRITE(*,*) Myid, "mynrows", Mynrows, Nrows(Myid+1)
Start1=Mpi_Wtime()

ALLOCATE(Spin(0:Mynrows+1,0:L+1,0:L+1))
ALLOCATE(ML(1:mynrows))
ALLOCATE(ML_0(1:L))

! Initial condition...
Spin=1 !(All spins are up)


CALL SYSTEM_CLOCK(Count)  !
SEED=COUNT*(Myid+1)       !
CALL RANDOM_SEED(Put=SEED)!


! Simulation begins here......
!##########################################################################################################
 DO Sample=1,N_Sample
	 CALL SYSTEM_CLOCK(Count)
	 SEED=COUNT*(Myid+1)
	 CALL RANDOM_SEED(Put=SEED)
 	 
   ! CALL Initial_Configuration(Spin,L,Mynrows,Myid)

	 ! Apply periodic boundary conditions (by sharing the first and last row of the lattice with neighbour cpus)
	 CALL MPI_SEND(Spin(1,0:L+1, 0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(1), 0, MPI_COMM_WORLD, Ierr)
   CALL MPI_SEND(Spin(Mynrows,0:L+1, 0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(2), 0, MPI_COMM_WORLD, Ierr)

   CALL MPI_RECV(SPin(Mynrows+1,0:L+1, 0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(2), 0, MPI_COMM_WORLD, STATUS, Ierr)
   CALL MPI_RECV(Spin(0,0:L+1,0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(1), 0, MPI_COMM_WORLD, STATUS, Ierr)

	 ! Apply periodic boundary conditions within the sub lattice
	 ! Apply periodic boundary conditions within the sublattice
 	 Spin(:,0,:)=Spin(:,L,:)
 	 Spin(:,L+1,:)=Spin(:,1,:)

 	 Spin(:,:,0)=Spin(:,:,L)
 	 Spin(:,:,L+1)=Spin(:,:,1)

		DO dTau12=0,0!N_Tau12
	    Tau_12=Initial_Tau12+(dTau12)*Tau12_Step
  	  Tau=2*Tau_12
  	  N_MCSS=TNP*Tau; N_Equilibration=TNDP*Tau
  	  Total_Period=(N_MCSS-N_Equilibration)/(Tau)
      
      ALLOCATE(M_t_Local(1:N_MCSS),M_t_Global(1:N_MCSS), ML_t_Local(1:L,1:N_MCSS), ML_t_Global(1:L, 1:N_MCSS))
      ALLOCATE(E_t_Local(1:N_MCSS),E_t_Global(1:N_MCSS))
      ALLOCATE(M_Global(1:Total_Period),E_Global(1:Total_Period),ML_Global(1:L,1:Total_Period))


			M_t_Local=0.0d0;    E_t_Local=0.0d0;    ML_t_Local=0.0d0
	    M_Global=0.0d0; 		M_t_Global=0.0d0;   ML_t_Global=0.0d0; ML_Global=0.0d0; 
      E_Global=0.0d0; 		E_t_Global=0.0d0
      Q_Global=0.0d0;     Q_Global2=0.0d0;    Q_Global4=0.0d0
      QL_Global=0.0d0;    QL_Global2=0.0d0;   QL_Global4=0.0d0
			EQ_Global=0.0d0;    EQ_Global2=0.0d0

		DO MCS=1,N_MCSS
    	  CALL MPI_BARRIER(MPI_COMM_WORLD, Ierr)
				M=0.0D0; ML=0.0D0; ML_0=0.0d0
				E=0.0D0
        IF(MOD(MCS,2*Tau_12).LT.Tau_12) THEN
			  	Mag_Field=-h_0
			  ELSEIF(MOD(MCS,2*Tau_12).GE.Tau_12) THEN
			  	Mag_Field=h_0
			  END IF
			  IF(MCS<N_Equilibration) THEN
			  	Mag_Field=h_0
			  END IF
		    !The Monte Carlo update begins with the spins on the "upwards" boundary.
        ! Update spins in the first row of the spin array.
				DO IJ=1,L*L
					CALL RANDOM_NUMBER(Y)
			    CALL RANDOM_NUMBER(Z)
					I=1
  			  J=INT(Y*L)+1
		      K=INT(Z*L)+1
					IF (MYID.EQ.0) THEN
						!J1=i,j-1,k  J2=i,j+1,k   J3=i,j,k-1 J4=i,j,k+1 J5=i-1,j,k J6=i+1,j,k
						JJ(1)=JS;  JJ(2)=JS;  JJ(3)=JS; JJ(4)=JS; JJ(5)=0; JJ(6)=JB  
					ELSE
						JJ(1)=JB;  JJ(2)=JB;  JJ(3)=JB; JJ(4)=JB; JJ(5)=JB; JJ(6)=JB  
					END IF

		    	CALL METROPOLIS(Spin,L,Mynrows,I,J,K,JJ,T,Mag_Field,Delta)
        		! apply pbc
					Spin(1,0,k)=Spin(1,L,k)
 			  	Spin(1,L+1,k)=Spin(1,1,k)
      		Spin(1,j,0)=Spin(1,j,L)
 			  	Spin(1,j,L+1)=Spin(1,j,1)

					M=M+DFLOAT(Spin(I,J,K))
    			ML(i)=ML(i)+DFLOAT(Spin(I,J,K))
 					E_J=-0.5d0*DFLOAT((Spin(I,J,K)))*(JJ(1)*DFLOAT(Spin(I,J-1,K))+JJ(2)*DFLOAT(Spin(I,J+1,K))+&
					JJ(3)*DFLOAT(Spin(I,J,K-1))+JJ(4)*DFLOAT(Spin(I,J,K+1))+JJ(5)*DFLOAT(Spin(I-1,J,K))+JJ(6)*DFLOAT(Spin(I+1,J,K)))
        
					E_H=-Mag_Field*REAL(Spin(I,J,K))
        	E_D=Delta*(REAL(Spin(i,j,k)**2))
         
		 	  	E=E+E_J+E_D!+E_H  
       	END DO
     	  !As soon as these spins are updated the copy is sent in the "upwards" 
		 	  !direction cyclically for all the processors
				
 			  CALL MPI_SEND(Spin(1,0:L+1, 0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(1), 0, MPI_COMM_WORLD, Ierr)
 			  CALL MPI_RECV(Spin(Mynrows+1,0:L+1, 0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(2), 0, MPI_COMM_WORLD, STATUS, Ierr)

  			! Continue by updating spins in the interior strips and  "downwards" boundary (last row).	

      	DO IJ=1,(mynrows-1)*L*L
	  			CALL RANDOM_NUMBER(X)
					CALL RANDOM_NUMBER(Y)
     			CALL RANDOM_NUMBER(Z)
					I=INT(X*(mynrows-1))+2
				  J=INT(Y*L)+1
          K=INT(Z*L)+1
     			IF (MYID.EQ.NPROCS-1.AND.I.EQ.MYNROWS) THEN
     				!J1=i,j-1,k  J2=i,j+1,k   J3=i,j,k-1 J4=i,j,k+1 J5=i-1,j,k J6=i+1,j,k
			      JJ(1)=JS;  JJ(2)=JS;  JJ(3)=JS; JJ(4)=JS; JJ(5)=JB; JJ(6)=0
					ELSE
			      JJ(1)=JB;  JJ(2)=JB;  JJ(3)=JB; JJ(4)=JB; JJ(5)=JB; JJ(6)=JB  
		     END IF
				 CALL METROPOLIS(Spin,L,Mynrows,i,j,k,JJ,T,Mag_Field,Delta)
					! apply pbc
		    Spin(i,j,0)=Spin(i,j,L)
 				Spin(i,j,L+1)=Spin(i,j,1)
   		  Spin(i,0,k)=Spin(i,L,k)
 				Spin(i,L+1,k)=Spin(i,1,k)

			  M=M+DFLOAT(Spin(I,J,K))
       	ML(i)=ML(i)+DFLOAT(Spin(I,J,K))
      

         E_J=-0.5d0*DFLOAT((Spin(I,J,K)))*(JJ(1)*DFLOAT(Spin(I,J-1,K))+JJ(2)*DFLOAT(Spin(I,J+1,K))+&
					JJ(3)*DFLOAT(Spin(I,J,K-1))+JJ(4)*DFLOAT(Spin(I,J,K+1))+JJ(5)*DFLOAT(Spin(I-1,J,K))+JJ(6)*DFLOAT(Spin(I+1,J,K)))
        	
				 E_H=-Mag_Field*REAL(Spin(I,J,K))
         E_D=Delta*(Spin(i,j,k)**2)
         
 			   E=E+E_J+E_D!+E_H  
			END DO
			!When the spins in the "downwards" boundary are updated, these freshly updated spins are
			!then sent cyclically downwards to complete one full update cycle of the lattice.	
 			CALL MPI_SEND(Spin(Mynrows,0:L+1,0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(2), 0, MPI_COMM_WORLD, Ierr)
 			CALL MPI_RECV(Spin(0,0:L+1,0:L+1), (L+2)*(L+2), MPI_INTEGER, Myneigbrs(1), 0, MPI_COMM_WORLD, STATUS, Ierr)
				
			IF(MCS.GT.N_Equilibration) THEN
   			M_t_Local(MCS)=M
    		CALL MPI_GATHER(ML, MYNROWS, MPI_DOUBLE_PRECISION, ML_0, mynrows, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, Ierr)
		    IF (MYID.EQ.0) THEN
			    DO II=1,L
		      ML_t_Local(II,MCS)=ML_0(II)
			    END DO
		    END IF
				E_t_Local(MCS)=E
			END IF


	END DO  ! End of MC loop
  CALL MPI_REDUCE(M_t_Local, M_t_Global, N_MCSS, MPI_DOUBLE_PRECISION, MPI_SUM, 0, MPI_COMM_WORLD, Ierr) 
  CALL MPI_REDUCE(E_t_Local, E_t_Global, N_MCSS, MPI_DOUBLE_PRECISION, MPI_SUM, 0, MPI_COMM_WORLD, Ierr) 


 	IF (Myid.EQ.0) THEN
		M_Global=0.0d0; E_Global=0.0d0; ML_Global=0.0d0
        
 		DO I=1, Total_Period
  		DO ij=N_Equilibration+(i-1)*Tau+1,N_Equilibration+i*Tau
      	M_Per_Site=M_t_Global(IJ)/DFLOAT(N)
        E_Per_Site=E_t_Global(IJ)/DFLOAT(N)
  			M_Global(I)=M_Global(I)+M_Per_Site
  			E_Global(I)=E_Global(I)+E_Per_Site

        DO K=1,L
        	ML_Global(K,I)=ML_Global(K,I)+ML_t_local(K,IJ)/DFLOAT(L*L)
        END DO

      END DO
      M_Global(I)=ABS(M_Global(I))/REAL(TAU) 
      DO K=1,L
      	ML_Global(K,I)=ABS(ML_Global(K,I))/REAL(TAU) 
      END DO

			E_Global(I)=E_Global(I)/REAL(TAU)
      Q_Global(dTau12)=Q_Global(dTau12)+M_Global(I)
      Q_Global2(dTau12)=Q_Global2(dTau12)+M_Global(I)**2                        
      Q_Global4(dTau12)=Q_Global4(dTau12)+M_Global(I)**4
      DO K=1,L
      	QL_Global(K,dTau12)=QL_Global(K,dTau12)+ML_Global(K,I)
        QL_Global2(K,dTau12)=QL_Global2(K,dTau12)+ML_Global(K,I)**2                        
        QL_Global4(K,dTau12)=QL_Global4(K,dTau12)+ML_Global(K,I)**4
			END DO
      EQ_Global(dTau12)=EQ_Global(dTau12)+E_Global(I)
      EQ_Global2(dTau12)=EQ_Global2(dTau12)+E_Global(I)**2
 		END DO
    Q_Global(dTau12)=Q_Global(dTau12)/REAL(Total_Period)
    Q_Global2(dTau12)=Q_Global2(dTau12)/REAL(Total_Period)
    Q_Global4(dTau12)=Q_Global4(dTau12)/REAL(Total_Period)

    DO K=1,L
    	QL_Global(K,dTau12)=QL_Global(K,dTau12)/REAL(Total_Period)
      QL_Global2(K,dTau12)=QL_Global2(K,dTau12)/REAL(Total_Period)
      QL_Global4(K,dTau12)=QL_Global4(K,dTau12)/REAL(Total_Period)
    END DO

    EQ_Global(dTau12)=EQ_Global(dTau12)/REAL(Total_Period)
    EQ_Global2(dTau12)=EQ_Global2(dTau12)/REAL(Total_Period)
	  
     
		Suscep=REAL(N)*(Q_Global2(dTau12)-Q_Global(dTau12)**2)
		HCap=REAL(N)*(EQ_Global2(dTau12)-EQ_Global(dTau12)**2)
   	Binder=1.0d0-Q_Global4(dTau12)/(3.0d0*Q_Global2(dTau12)**2)
		DO K=1,L
	   SuscepL(K)=REAL(L*L)*(QL_Global2(K,dTau12)-QL_Global(K,dTau12)**2)
		 BinderL(K)=1.0d0-QL_Global4(K,dTau12)/(3.0d0*QL_Global2(K,dTau12)**2)
   	END DO

			WRITE(*,*) Tau_12/tau12_c, REAL(QL_Global(1,dTau12)), REAL(QL_Global(L/2,dTau12)), REAL(Q_Global(dTau12))
 			WRITE(1,*) Tau_12/tau12_c, REAL(Q_Global(dTau12)), REAL(Q_Global2(dTau12)), REAL(Suscep)
			WRITE(2,*) Tau_12/tau12_c, REAL(EQ_Global(dTau12)), REAL(EQ_Global2(dTau12)),REAL(HCap)
			WRITE(3,*) Tau_12/tau12_c, Real(BinderL(1)), Real(BinderL(L/2)), Real(Binder) 
      WRITE(4,*) Tau_12/tau12_c, REAL(QL_Global(1,dTau12)), REAL(QL_Global2(1,dTau12)), Real(SuscepL(1))
      WRITE(5,*) Tau_12/tau12_c, REAL(QL_Global(L/2,dTau12)), REAL(QL_Global2(L/2,dTau12)), Real(SuscepL(L/2))
	END IF
		
 	DEALLOCATE(M_t_Local,M_t_Global)
  DEALLOCATE(ML_t_Local,ML_t_Global)
	DEALLOCATE(E_t_Local,E_t_Global)
	DEALLOCATE(M_Global,E_Global, ML_Global)
 END DO  ! End of half_period
END DO  ! End of sample
! Simulation ends here....
!##########################################################################################################
 CALL MPI_BARRIER(MPI_COMM_WORLD, Ierr)
 Finish1=mpi_wtime()
 Total_time=Finish1-Start1
 CALL MPI_REDUCE(Total_time, Total_time_max, 1, MPI_DOUBLE_PRECISION, MPI_MAX , 0, MPI_COMM_WORLD, Ierr)
 IF(Myid.EQ.0) then
	WRITE(*,*) ""
 	WRITE(*,*) Total_time_max, "seconds", Total_time_max/60, "minute"
 END IF
 CALL MPI_FINALIZE(Ierr)
END PROGRAM
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE Initial_Configuration(Spin,L,Mynrows,Myid)
IMPLICIT NONE
INTEGER,INTENT(IN)::L,Mynrows,Myid
INTEGER,DIMENSION(0:Mynrows+1,0:L+1,0:L+1),INTENT(INOUT)::SPIN
INTEGER::I,J, K
REAL*8::R1


 SPIN=0
 DO I=1,Mynrows
 	DO J=1, L
  DO K=1, L
		CALL RANDOM_NUMBER(R1)
		Spin(I,J,K)=1!(-1)**NINT(R1)
	END DO
	END DO
 END DO
END SUBROUTINE Initial_Configuration
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE METROPOLIS(Spin,L,Mynrows,I,J,K,JJ,T,Mag_Field,Delta)           
IMPLICIT NONE
INTEGER,INTENT(IN)::L,Mynrows,I,J,K
INTEGER,DIMENSION(0:Mynrows+1,0:L+1,0:L+1),INTENT(INOUT)::SPIN
REAL*8,INTENT(IN)::T,Mag_Field,JJ(6),Delta
REAL*8::DeltaE_J,DeltaE_H, DeltaE_D, DeltaE
REAL*8::R1,R2,DS, W, WW
INTEGER::Spin_new,Spin_old

  Spin_old=Spin(I,J,K)
1	CALL RANDOM_NUMBER(R1)
  Spin(i,j,k)=INT(3.0*R1)-1
  IF(Spin(I,J,K)==Spin_old) GO TO 1
  Spin_new=Spin(I,J,K)
  Spin(I,J,k)=Spin_new
  Ds=(Spin_new-Spin_old)*1.0D0


                        
 DeltaE_J=-DS*(JJ(1)*DFLOAT(Spin(I,J-1,K))+JJ(2)*DFLOAT(Spin(I,J+1,K))+JJ(3)*DFLOAT(Spin(I,J,K-1))+&
					JJ(4)*DFLOAT(Spin(I,J,K+1))+JJ(5)*DFLOAT(Spin(I-1,J,K))+JJ(6)*DFLOAT(Spin(I+1,J,K)))


 DeltaE_H=-DS*Mag_Field
 DeltaE_D=Delta*(Spin_new**2-Spin_old**2)*1.0D0

 DeltaE=DeltaE_J+DeltaE_H+DeltaE_D


!Metropolis
 IF(DeltaE.GT.0.0d0)THEN
    CALL RANDOM_NUMBER(R2)
	  IF(R2.GT.EXP(-DeltaE/T))THEN
		  Spin(i,j,k)=Spin_old
		END IF
 END IF

END SUBROUTINE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



