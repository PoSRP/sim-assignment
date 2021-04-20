
PROGRAM _INIT
	// This loop deals with all robot2 control
	
	// Move to home position
	// If package buffer is not empty, move to above pickup position
	// When sensor.packageForPacker, move down to package height and grab package
	// Move upwards to clear track
	// Move to one of three packing positions
	// Release package
	// ??? Update used position for next package
	// Clear package from buffer
	// Loop end
	
	// Start with robot initialization
	robot2.comm.targets.initHome := TRUE;
END_PROGRAM

PROGRAM _CYCLIC
	CASE robot2.state OF
		RSTATE_INIT:
			robot2.target := RTARGET_HOME_POS;
			IF robot2.inPosition THEN
				robot2.state := RSTATE_WAITING;
			END_IF
		
		RSTATE_WAITING:
			// Robot is switched to PICKUP by the sensor loop
			
		RSTATE_PICKUP:
			IF robot2.inPosition THEN
				robot2.grip := TRUE;
				IF robot2.isGripping THEN
				END_IF
				
			END_IF
			
			
		RSTATE_DROPOFF:
			
		RSTATE_E_STOP:
		// Some kind of KILL state
		
	END_CASE
	
	// Write/read the current IO robot comm struct, this is ugly AF 
	CASE robot2.target OF
		RTARGET_HOME_POS:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_1:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := TRUE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_2:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := TRUE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_3:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := TRUE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_4:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := TRUE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_1:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := TRUE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_2:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := TRUE;
			robot2.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_3:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := TRUE;
	END_CASE	
	robot2.comm.doGrip := robot1.grip;
	robot2.isGripping := robot1.comm.diGrip;
	robot2.inPosition := robot1.comm.inPosition;
	robot2.isWaiting := robot1.comm.isWaiting;
	
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

