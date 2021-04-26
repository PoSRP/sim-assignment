
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
	
	// Init robot2
	robot2.state := RSTATE_INIT;
END_PROGRAM

PROGRAM _CYCLIC
	
	CASE robot2.state OF
		RSTATE_INIT:
			// Set the home position target and wait for arrival
			robot2.target := RTARGET_FORCE_HOME;
			robot2.state := RSTATE_FORCE_HOME;
			
		RSTATE_FORCE_HOME:
			// Wait for robot to be in position
			IF robot2.inPosition THEN
				// Clear the target IO and wait
				robot2.target := RTARGET_CLEAR;
				robot2.state := RSTATE_WAITING;
			END_IF
			
		RSTATE_WAITING:
			// Nothing really here
			
		RSTATE_PICKUP:
			// Sensor loop sent us here, and set a target for us
			// Save this target
			robot2.previousTarget := robot2.target;
			
			// Wait for robot to be in position
			IF robot2.inPosition THEN
				// Arrived, pick up something
				robot2.grip := TRUE;
				IF robot2.isGripping THEN
					// Gripping, move back to home
					robot2.nextState := RSTATE_PICKUP_R;
					robot2.state := RSTATE_CLEAR;
				END_IF
			END_IF
			
		RSTATE_PICKUP_R:
			// Select reverse based on previous target
			CASE robot2.previousTarget OF
				RTARGET_PICKUP_1: 
					robot2.target := RTARGET_PICKUP_1_R;
					
				RTARGET_PICKUP_2:
					robot2.target := RTARGET_PICKUP_2_R;
					
				RTARGET_PICKUP_3:
					robot2.target := RTARGET_PICKUP_3_R;
					
				RTARGET_PICKUP_4:
					robot2.target := RTARGET_PICKUP_4_R;
					
			END_CASE
			
			IF robot2.inPosition THEN
				// If robot says we're home, change to drop state
				robot2.nextState := RSTATE_DROP;
				robot2.state := RSTATE_CLEAR;
			END_IF
			
		RSTATE_DROP:
			// Select drop target from the first element in the buffer
			CASE packBuffer[0].size OF
				PACKAGE_INVALID:
					// Something is wrong, this should be here ..
					robot2.state := RSTATE_E_STOP;
					
				PACKAGE_SMALL:
					robot2.target := RTARGET_DROPOFF_1;
					
				PACKAGE_MEDIUM:
					robot2.target := RTARGET_DROPOFF_2;
					
				PACKAGE_LARGE:
					robot2.target := RTARGET_DROPOFF_3;
				
			END_CASE
			
			// Wait until we're there
			IF robot2.inPosition THEN
				// Save the target
				robot2.previousTarget := robot2.target;
				
				// Release the package
				robot2.grip := FALSE;
				IF NOT robot2.isGripping THEN
					// State stuff
					robot2.nextState := RSTATE_DROP_R;
					robot2.state := RSTATE_CLEAR;
				END_IF
			END_IF
			
		RSTATE_DROP_R:
			// Select the path home from previous target
			CASE robot2.previousTarget OF
				RTARGET_DROPOFF_1:
					robot2.target := RTARGET_DROPOFF_1_R;
					
				RTARGET_DROPOFF_2:
					robot2.target := RTARGET_DROPOFF_2_R;
					
				RTARGET_DROPOFF_3:
					robot2.target := RTARGET_DROPOFF_3_R;
				
			END_CASE
			
			// Wait for inPosition
			IF robot2.inPosition THEN
				// We're ready for new things
				robot2.state := RSTATE_CLEAR;
				robot2.nextState := RSTATE_WAITING;
				
			END_IF
			
		RSTATE_CLEAR:
			// Set the state from next set state if filled.
			// We use this to get a cycle of clear IO between moves out and back
			// Else just clear through wait
			IF NOT (robot2.nextState = RSTATE_WAITING) THEN
				robot2.state := robot2.nextState;
				robot2.target := RTARGET_CLEAR;
				robot2.previousTarget := RTARGET_CLEAR;
				robot2.nextState := RSTATE_WAITING;
			ELSE
				robot2.state := RSTATE_WAITING;
			END_IF
		
		RSTATE_E_STOP:
		// General kill state .. 
		
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
		RTARGET_PICKUP_1_R:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
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
		RTARGET_PICKUP_2_R:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
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
		RTARGET_PICKUP_3_R:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
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
		RTARGET_PICKUP_4_R:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
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
		RTARGET_DROPOFF_1_R:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
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
		RTARGET_DROPOFF_2_R:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
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
		RTARGET_DROPOFF_3_R:
			robot2.comm.targets.initHome := FALSE;
			robot2.comm.targets.home := TRUE;
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

