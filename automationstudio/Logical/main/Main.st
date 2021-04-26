
PROGRAM _INIT
	// Package gets dropped on continuous conveyor
	// 3 laser sensors detects package size
	//		One sensor placed above to determine package height
	//		Two sensors, one either side of conveyor, to determine angle, width, and length
	// Robot1 picks up the detected package while conveyor is moving
	// If package is within an accepted range it gets put on packing conveyor
	// If package does not match, it gets discarded to an eater
	// Packages dropped to the packing conveyor gets saved in buffer
	// Robot2 picks up packages from conveyor and palletizes
	// After pickup by robot2, package is removed from buffer
	
	// All sensors and IO are updated in the 'sensors' loop
	// All robot1 control is done in this loop
	// All robot2 control is done in the 'main2' loop
	// Conveyors are all moving at 0.5 m/s when on
	
	// Package range definitions, see sensors loop
	//	Small : Volumes from 8.000.000 mm3 to 16.000.000 mm3
	//	Medium : Volumes from 16.000.000 mm3 to 32.000.000 mm3
	//	Large : Volumes from 32.000.000 to 50.000.000 mm3
	
	
	// Loop description:
	// Move to home position (close to pickup position)
	// When a package releases the sensors, newPack should be filled out by sensor loop
	// If newPack.good is true, move to packing conveyor, release, and push package to buffer
	// If newPack.good is false, move to discarding conveyor, release
	// Return to home position
	
	// Init the robot
	robot1.state := RSTATE_INIT;
END_PROGRAM

PROGRAM _CYCLIC

	CASE robot1.state OF
		RSTATE_INIT:
			// Set the home position target and wait for arrival
			robot1.target := RTARGET_FORCE_HOME;
			robot1.state := RSTATE_FORCE_HOME;
			
		RSTATE_FORCE_HOME:
			// Wait for robot to be in position
			IF robot1.inPosition THEN
				// Clear the target IO and wait
				robot1.target := RTARGET_CLEAR;
				robot1.state := RSTATE_WAITING;
			END_IF
			
		RSTATE_WAITING:
			// Nothing really here
			
		RSTATE_PICKUP:
			// Sensor loop sent us here, and set a target for us
			// Save this target
			robot1.previousTarget := robot1.target;
			
			// Save the package
			newPackR1 := newPack;
			
			// Wait for robot to be in position
			IF robot1.inPosition THEN
				// Arrived, pick up something
				robot1.grip := TRUE;
				IF robot1.isGripping THEN
					// Gripping, move back to home
					robot1.nextState := RSTATE_PICKUP_R;
					robot1.state := RSTATE_CLEAR;
				END_IF
			END_IF
			
		RSTATE_PICKUP_R:
			// Select reverse based on previous target
			CASE robot1.previousTarget OF
				RTARGET_PICKUP_1: 
					robot1.target := RTARGET_PICKUP_1_R;
					
				RTARGET_PICKUP_2:
					robot1.target := RTARGET_PICKUP_2_R;
					
				RTARGET_PICKUP_3:
					robot1.target := RTARGET_PICKUP_3_R;
					
				RTARGET_PICKUP_4:
					robot1.target := RTARGET_PICKUP_4_R;
					
			END_CASE
			
			IF robot1.inPosition THEN
				// Remember some flags
				newPackLoaded := TRUE;
				newPackReady := FALSE;
				
				// If robot says we're home, change to drop state
				robot1.nextState := RSTATE_DROP;
				robot1.state := RSTATE_CLEAR;
			END_IF
			
		RSTATE_DROP:
			// Select drop target from newPackR1
			CASE newPackR1.size OF
				PACKAGE_INVALID:
					packDiscarded := TRUE;
					robot1.target := RTARGET_DROPOFF_1;
					
				PACKAGE_SMALL:
					robot1.target := RTARGET_DROPOFF_2;
					
				PACKAGE_MEDIUM:
					robot1.target := RTARGET_DROPOFF_2;
					
				PACKAGE_LARGE:
					robot1.target := RTARGET_DROPOFF_2;
				
			END_CASE
			
			IF robot1.target = RTARGET_DROPOFF_2 THEN
				IF packIndex < packBufSize - 1 THEN
					// Push to buffer, increment index
					packBuffer[packIndex] := newPackR1;
					packIndex := packIndex + 1;
				ELSE
					// Overflow ... 
					packDiscarded := TRUE;
					robot1.target := RTARGET_DROPOFF_1;
				END_IF
			END_IF
			
			// Wait until we're there and the packing conveyor has moved for at least some time
			IF robot1.inPosition AND (TIME_TO_DINT(timePacking) > TIME_TO_DINT(timePackingLimit)) THEN
				// Save the target
				robot1.previousTarget := robot1.target;
				
				// Release the package
				robot1.grip := FALSE;
				IF NOT robot1.isGripping THEN
					// Flag
					newPackLoaded := FALSE;
					
					// Reset the packing conveyor timer
					timePacking := t#0s;
					
					// State stuff
					robot1.nextState := RSTATE_DROP_R;
					robot1.state := RSTATE_CLEAR;
				END_IF
			END_IF
			
		RSTATE_DROP_R:
			// Select the path home from previous target
			CASE robot1.previousTarget OF
				RTARGET_DROPOFF_1:
					robot1.target := RTARGET_DROPOFF_1_R;
					
				RTARGET_DROPOFF_2:
					robot1.target := RTARGET_DROPOFF_2_R;
					
				RTARGET_DROPOFF_3:
					robot1.target := RTARGET_DROPOFF_3_R;
				
			END_CASE
			
			// Wait for inPosition
			IF robot1.inPosition THEN
				// We're ready for new things
				robot1.state := RSTATE_CLEAR;
				robot1.nextState := RSTATE_WAITING;
				
			END_IF
			
		RSTATE_CLEAR:
			// Set the state from next set state if filled.
			// We use this to get a cycle of clear IO between moves out and back
			// Else just clear through wait
			IF NOT (robot1.nextState = RSTATE_WAITING) THEN
				robot1.state := robot1.nextState;
				robot1.target := RTARGET_CLEAR;
				robot1.previousTarget := RTARGET_CLEAR;
				robot1.nextState := RSTATE_WAITING;
			ELSE
				robot1.state := RSTATE_WAITING;
			END_IF
		
		RSTATE_E_STOP:
			// General kill state .. 
		
	END_CASE
	
	
	// Write the current IO to robot comm struct, this is ugly AF 
	CASE robot1.target OF
		RTARGET_FORCE_HOME:
			robot1.comm.targets.initHome := TRUE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_1:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := TRUE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
		RTARGET_PICKUP_1_R:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := TRUE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_2:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := TRUE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
		RTARGET_PICKUP_2_R:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := TRUE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_3:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := TRUE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
		RTARGET_PICKUP_3_R:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := TRUE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_4:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := TRUE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
		RTARGET_PICKUP_4_R:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := TRUE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_1:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := TRUE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
		RTARGET_DROPOFF_1_R:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := TRUE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_2:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := TRUE;
			robot1.comm.targets.drop3 := FALSE;
		RTARGET_DROPOFF_2_R:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := TRUE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_3:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := TRUE;
		RTARGET_DROPOFF_3_R:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := TRUE;
		
		RTARGET_CLEAR:
			robot1.comm.targets.initHome := FALSE;
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
		
	END_CASE	
	robot1.comm.doGrip := robot1.grip;
	robot1.isGripping := robot1.comm.diGrip;
	robot1.inPosition := robot1.comm.inPosition;
	robot1.isWaiting := robot1.comm.isWaiting;
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

