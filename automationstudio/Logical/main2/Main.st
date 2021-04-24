
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
			// Set the home position target and wait for arrival
			robot2.target := RTARGET_FORCE_HOME;
			robot2.state := RSTATE_TO_HOME;
			
		RSTATE_TO_HOME:
			// Wait for robot to be in position
			IF robot2.inPosition THEN
				// Clear the target IO and start waiting
				robot2.target := RTARGET_CLEAR;
				robot2.state := RSTATE_WAITING;
			END_IF

		RSTATE_WAITING:
			// Nothing to see here
			
		RSTATE_PICKUP:
			// Wait for robot to be in position
			// Target is set in the sensor loop
			IF robot2.inPosition THEN
				// Grip a package
				robot2.grip := TRUE;
				IF robot2.isGripping THEN
					// Start moving to the home position before going to drop position
					robot2.target := RTARGET_HOME_POS;
					robot2.state := RSTATE_HOME_DROPOFF;
				END_IF
			END_IF
			
		RSTATE_HOME_DROPOFF:
			// Wait for robot to be in position
			IF robot2.inPosition THEN
				// Determine where the package should go
				CASE packBuffer[0].size OF
					PACKAGE_INVALID:
						// Why did an invalid package enter this buffer?
						robot2.state := RSTATE_E_STOP;
						
					PACKAGE_SMALL:
						robot2.target := RTARGET_DROPOFF_1;
						
					PACKAGE_MEDIUM:
						robot2.target := RTARGET_DROPOFF_2;
						
					PACKAGE_LARGE:
						robot2.target := RTARGET_DROPOFF_3;
						
				END_CASE
				
				// Change the state to drop off
				robot2.state := RSTATE_DROPOFF;
			END_IF
			
		RSTATE_DROPOFF:
			// Wait for robot to be in position and for the conveyor to have moved for some time
			IF robot2.inPosition AND timePacking > t#2s THEN
				// Release the package and go back to home
				robot2.grip := FALSE;
				IF NOT robot2.isGripping THEN
					// Shift the pack out of the buffer
					FOR Index:=0 TO packBufSize - 1 DO
						packBuffer[Index] := packBuffer[Index + 1];
					END_FOR
					
					// Reset the time counter for the conveyor
					timePacking := t#0s;
					
					// Go back to home position
					robot2.target := RTARGET_HOME_POS;
					robot2.state := RSTATE_TO_HOME;
				END_IF
			END_IF
			
		RSTATE_E_STOP:
		// Some kind of KILL state
		robot2.target := RTARGET_CLEAR;
		
	END_CASE
	
	// Write the current IO to robot comm struct, this is ugly AF 
	CASE robot2.target OF
		RTARGET_FORCE_HOME:
			robot2.comm.targets.initHome := TRUE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
		
		RTARGET_HOME_POS:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
			//robot2.comm.targets.pick1 := FALSE;
			//robot2.comm.targets.pick2 := FALSE;
			//robot2.comm.targets.pick3 := FALSE;
			//robot2.comm.targets.pick4 := FALSE;
			//robot2.comm.targets.drop1 := FALSE;
			//robot2.comm.targets.drop2 := FALSE;
			//robot2.comm.targets.drop3 := FALSE;
			
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
		
		RTARGET_CLEAR:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := FALSE;
			robot2.comm.targets.pick1 := FALSE;
			robot2.comm.targets.pick2 := FALSE;
			robot2.comm.targets.pick3 := FALSE;
			robot2.comm.targets.pick4 := FALSE;
			robot2.comm.targets.drop1 := FALSE;
			robot2.comm.targets.drop2 := FALSE;
			robot2.comm.targets.drop3 := FALSE;
		
	END_CASE	
	robot2.comm.doGrip := robot2.grip;
	robot2.isGripping := robot2.comm.diGrip;
	robot2.inPosition := robot2.comm.inPosition;
	robot2.isWaiting := robot2.comm.isWaiting;
	
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

