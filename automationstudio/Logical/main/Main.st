
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
	// Conveyors are all moving at 0.5 m/s
	
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
	
END_PROGRAM

PROGRAM _CYCLIC

	CASE robot1.state OF
		RSTATE_INIT:
			// Set the waiting position target and wait for arrival
			robot1.target := RTARGET_HOME_POS;
			robot1.state := RSTATE_TO_WAIT;
			
		RSTATE_TO_WAIT:
			IF robot1.inPosition THEN
				robot1.state := RSTATE_WAITING;
			END_IF
			
		RSTATE_WAITING:
			// Robot is switched to PICKUP by the sensor loop
			// Do nothing here
			
		RSTATE_PICKUP:
			// Wait for robot to be in position
			// The target has been selected in the sensor loop
			IF robot1.inPosition THEN
				// Grip the package
				robot1.grip := TRUE;
				
				IF robot1.isGripping THEN
					// When gripped, set some flags
					newPackLoaded := TRUE;
					newPackReady := FALSE;
					
					// Determine where to put this package
					CASE newPack.size OF
						PACKAGE_INVALID:
							// Drop off at the discaring conveyor, drop point 1
							robot1.target := RTARGET_DROPOFF_1;
						PACKAGE_SMALL:
							// Drop off at drop point 2, the packing conveyor
							robot1.target := RTARGET_DROPOFF_2;
						PACKAGE_MEDIUM:
							// Drop off at drop point 2, the packing conveyor
							robot1.target := RTARGET_DROPOFF_2;
						PACKAGE_LARGE:
							// Drop off at drop point 2, the packing conveyor
							robot1.target := RTARGET_DROPOFF_2;
					END_CASE
					
					IF robot1.target = RTARGET_DROPOFF_2 THEN
						// Push the newPack to the conveyor buffer and increment the buffer
						packBuffer[bufIndex] := newPack;
						bufIndex := bufIndex + 1;
					END_IF
					
					// Set state to dropping off
					robot1.state := RSTATE_DROPOFF;
				END_IF
			END_IF
			
		RSTATE_DROPOFF:
			// Wait for robot to be in position
			IF robot1.inPosition THEN
				// Release the package
				robot1.grip := FALSE;
				
				// Wait for release
				IF NOT robot1.isGripping THEN
					// Reset the Pack Loaded flag
					newPackLoaded := FALSE;
					
					// Go to the waiting position
					robot1.target := RTARGET_HOME_POS;
					
					// Change the robot state
					robot1.state := RSTATE_TO_WAIT;
				END_IF
			END_IF
			
		RSTATE_E_STOP:
			// Some kind of KILL state
		
	END_CASE
	
	// Write the current IO to robot comm struct, this is ugly AF 
	CASE robot1.target OF
		RTARGET_HOME_POS:
			robot1.comm.targets.home := TRUE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_1:
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := TRUE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_2:
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := TRUE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_3:
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := TRUE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_PICKUP_4:
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := TRUE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_1:
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := TRUE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_2:
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := TRUE;
			robot1.comm.targets.drop3 := FALSE;
			
		RTARGET_DROPOFF_3:
			robot1.comm.targets.home := FALSE;
			robot1.comm.targets.pick1 := FALSE;
			robot1.comm.targets.pick2 := FALSE;
			robot1.comm.targets.pick3 := FALSE;
			robot1.comm.targets.pick4 := FALSE;
			robot1.comm.targets.drop1 := FALSE;
			robot1.comm.targets.drop2 := FALSE;
			robot1.comm.targets.drop3 := TRUE;
	END_CASE	
	robot1.comm.doGrip := robot1.grip;
	robot1.isGripping := robot1.comm.diGrip;
	robot1.inPosition := robot1.comm.inPosition;
	robot1.isWaiting := robot1.comm.isWaiting;
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

