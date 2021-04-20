
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
	
END_PROGRAM

PROGRAM _CYCLIC
	CASE robot1.state OF
		ROBOT_INIT:
			robot1.state := ROBOT_WAITING;
			
		ROBOT_WAITING:
			// Robot is switched to PICKUP by the sensor loop
			
		ROBOT_PICKUP:
			
			
		ROBOT_WORKING:
			// Wait for the robot to finish?? Move to drop off point, drop, come back to waiting
			
		ROBOT_E_STOP:
		// Some kind of KILL state
		
	END_CASE
	 
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

