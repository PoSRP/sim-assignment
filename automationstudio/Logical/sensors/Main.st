
PROGRAM _INIT
	// Loop description
	
	// SENSORS ON THE CIRCULAR CONVEYOR
	// When a new package is detected, start recording measurements
	// When package releases, calculate angle and actual size / volume
		// If robot1 is currently away from waiting position, pause the conveyor or ignore the package
	// Fill result into newPack and determine if it is 'good'
	// If new package is detected before newPackLoaded is true, stop the feeder and conveyor
	// If no gap is detected between two packages, ignore the second package
	
	// SENSOR ON THE PACKING CONVEYOR
	// If sensor is activated, stop the conveyor until it is de-activated again
	
END_PROGRAM

PROGRAM _CYCLIC
	(* Insert code here *)
	
	// Conveyor loop
	
	// Packing conveyor
	IF sensors.packageForPacker THEN
		conveyors.packer := FALSE;
	END_IF
	
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

