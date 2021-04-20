
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
		ROBOT_INIT:
			robot1.state := ROBOT_WAITING;
			
		ROBOT_WAITING:
			// Robot is switched to PICKUP by the sensor loop
			
		ROBOT_PICKUP:
			// Change the newPack flags
			newPackLoaded := TRUE;
			newPackReady := FALSE;
			robot1.state := ROBOT_WORKING;
			
		ROBOT_WORKING:
			// Wait for the robot to finish?? Move to drop off point, drop, come back to waiting
			
		ROBOT_E_STOP:
			// Some kind of KILL state
		
	END_CASE
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

