
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
	(* Insert code here *)
	 
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

