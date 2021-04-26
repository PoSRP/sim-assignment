
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
	
	// Lasers in Experior are very very broken
	// They cannot do distance measurements unless perfectly level
	// This was only found out after preparing for it..
	
	// Initializing the accepted package sizes
	packRanges.small.min.volume := 8000000; 				(*  8.000.000 mm3 *)
	packRanges.small.max.volume := 16000000; 				(* 16.000.000 mm3 *)
	packRanges.medium.min.volume := packRanges.small.max.volume;
	packRanges.medium.max.volume := 32000000;				(* 32.000.000 mm3 *)
	packRanges.large.min.volume := packRanges.medium.max.volume;
	packRanges.large.max.volume := 50000000;				(* 50.000.000 mm3 *)
	
	// Initialize the timer
	timer_discard.PT := t#3s;
END_PROGRAM

PROGRAM _CYCLIC
	// Conveyor fsm
	CASE sensorState OF
		STATE_SENSOR_CONVEYOR_INIT:
			// Restart the tracks, Experior doesn't read on connection properly?
			conveyors.circular.run := TRUE;
			conveyors.discard.run := TRUE;
			conveyors.feed.run := TRUE;
			conveyors.packer.run := TRUE;
			sensorState := STATE_SENSOR_CONVEYOR_STOP;
			
		STATE_SENSOR_CONVEYOR_STOP:
			// Restart the tracks, Experior doesn't read on connection properly?
			conveyors.circular.run := FALSE;
			conveyors.discard.run := FALSE;
			conveyors.feed.run := FALSE;
			conveyors.packer.run := FALSE;
			sensorState := STATE_SENSOR_CONVEYOR_START;
			
		STATE_SENSOR_CONVEYOR_START:
			// Start them again and check
			conveyors.circular.run := TRUE;
			conveyors.discard.run := TRUE;
			conveyors.feed.run := TRUE;
			conveyors.packer.run := TRUE;
			
			//// Experior doesn't really like updating the inputs, so we'll be ignoring them .. 
			//IF conveyors.circular.isOn AND conveyors.discard.isOn AND conveyors.feed.isOn AND conveyors.packer.isOn THEN
				// Change state if both robots are also ready
			
				IF robot1.state = RSTATE_WAITING AND robot2.state = RSTATE_WAITING THEN
					packFeeder.doFeed := TRUE;
					sensorState := STATE_SENSOR_MEASURING;
				END_IF
			
			//END_IF
			
		STATE_SENSOR_WAIT:
			IF sensors.widthBlocked[0] OR sensors.widthBlocked[1] THEN
				// Reset buffer index
				bufIndex := 0;
				
				// Grab first set of data
				//packageDetectionBuffer[bufIndex].height := MAX(sensors.height[0], sensors.height[1], sensors.height[2]);
				packageDetectionBuffer[bufIndex].height := 300; (* Let's pretend it's always 300mm. I blame Experior. *)
				packageDetectionBuffer[bufIndex].width := sensors.width;
				
				// Increment index
				bufIndex := bufIndex + 1;
				
				// Change to continuos measuring state
				sensorState := STATE_SENSOR_MEASURING;
			END_IF
			
		STATE_SENSOR_MEASURING:
			// When a package is detected, save first set of data and enter continuous measurement
			IF sensors.widthBlocked[0] OR sensors.widthBlocked[1] THEN
				// Grab a set of data while either sensor is still blocked
				//packageDetectionBuffer[bufIndex].height := MAX(sensors.height[0], sensors.height[1], sensors.height[2]);
				packageDetectionBuffer[bufIndex].height := 300; (* Let's pretend it's always 300mm. I blame Experior. *)
				packageDetectionBuffer[bufIndex].width := sensors.width;
				
				// Increment the buffer index
				IF bufIndex > bufSize - 1 THEN
					// Size overflow, just change to the next state
					sensorState := STATE_SENSOR_CALCULATING;
				ELSE
					// Increment for next measurement
					bufIndex := bufIndex + 1;
				END_IF
			ELSE
				// Change to the calculation state
				sensorState := STATE_SENSOR_CALCULATING;
			END_IF
			
		STATE_SENSOR_CALCULATING:
			// Stop the tracks, robot1 isn't happy about them moving while picking up
			conveyors.circular.run := FALSE;
			conveyors.feed.run := FALSE;
			
			// Find the package stuff, prime robot1 and the required track for movement
			// We assume a box shape. BufIndex isn't a filled value.
			// Find a corner
			FOR Index:=0 TO bufIndex - 2 DO
				
				// Resolution in the track direction isn't great, 0.5 m/s @ 10ms samples = 5mm 
				// Also the Laser sensors in Experior are very unreliable in general ... 
				
				//// Width sensor 0
				IF NOT (packageDetectionBuffer[Index].width[0] = LASER_DEFAULT_VALUE_WIDTH) THEN
					// Valid measurement
					// Save initial detection position in packCalc
					IF NOT packCalc.cornerIndexFilled[0] THEN
						packCalc.cornerIndex[0] := Index;
						packCalc.cornerIndexFilled[0] := TRUE;
					END_IF
					// Sensors will always start going down, as free measurement is high limit
					// If box is square on, they will not change
					// If box is angled, it will ramp up until a corner, and ramp back down after. 
					// Some detector measurement error has to be allowable, as a false positive wrecks the "algorithm"
					// However this is simulated, so we won't 
					IF packageDetectionBuffer[Index].width[0] < packageDetectionBuffer[Index + 1].width[0] THEN
						// Corner found
						IF NOT packCalc.cornerIndexFilled[1] THEN
							packCalc.cornerIndex[1] := Index;
							packCalc.cornerIndexFilled[1] := TRUE;
						END_IF
					END_IF
					// Check for a ramp going up after finding the corner, that would be a new box
					IF packageDetectionBuffer[Index].width[0] > packageDetectionBuffer[Index + 1].width[0] AND packCalc.cornerIndexFilled[1] THEN
						IF NOT packCalc.cornerIndexFilled[2] THEN
							packCalc.cornerIndex[2] := Index;
							packCalc.cornerIndexFilled[2] := TRUE;
						END_IF
					END_IF
				ELSIF packCalc.cornerIndexFilled[0] AND NOT packCalc.cornerIndexFilled[2] THEN
					// If sensor is free and we did find the first point, this is the end
					// If the third point is already filled, we found another box instead
					// We decrement the index to save the last valid measurement instead of the first invalid one
					packCalc.cornerIndex[2] := Index - 1;
					packCalc.cornerIndexFilled[2] := TRUE;
				END_IF
				
				//// Width sensor 1 (copied from width sensor 0)
				IF NOT packageDetectionBuffer[Index].width[1] = LASER_DEFAULT_VALUE_WIDTH THEN
					// Valid measurement
					// Save initial detection position in packCalc
					IF NOT packCalc.cornerIndexFilled[3] THEN
						packCalc.cornerIndex[3] := Index;
						packCalc.cornerIndexFilled[3] := TRUE;
					END_IF
					// Sensors will always start going down, as free measurement is high limit
					// If box is square on, they will not change
					// If box is angled, it will ramp up until a corner, and ramp back down after. 
					// Some detector measurement error has to be allowable, as a false positive wrecks the "algorithm"
					// However this is simulated, so we won't 
					IF packageDetectionBuffer[Index].width[1] < packageDetectionBuffer[Index + 1].width[1] THEN
						// Corner found
						IF NOT packCalc.cornerIndexFilled[4] THEN
							packCalc.cornerIndex[4] := Index;
							packCalc.cornerIndexFilled[4] := TRUE;
						END_IF
					END_IF
					// Check for a ramp going up after finding the corner, that would be a new box
					IF packageDetectionBuffer[Index].width[1] > packageDetectionBuffer[Index + 1].width[1] AND packCalc.cornerIndexFilled[4] THEN
						IF NOT packCalc.cornerIndexFilled[5] THEN
							packCalc.cornerIndex[5] := Index;
							packCalc.cornerIndexFilled[5] := TRUE;
						END_IF
					END_IF
				ELSIF packCalc.cornerIndexFilled[3] AND NOT packCalc.cornerIndexFilled[5] THEN
					// If sensor is free and we did find the first point, this is the end
					// If the third point is already filled, we found another box instead
					// We decrement the index to save the last valid measurement instead of the first invalid one
					packCalc.cornerIndex[5] := Index - 1;
					packCalc.cornerIndexFilled[5] := TRUE;
				END_IF
			END_FOR
			
			// Finding the dimensions
			IF packCalc.cornerIndexFilled[0] AND packCalc.cornerIndexFilled[1] AND packCalc.cornerIndexFilled[2] AND
				packCalc.cornerIndexFilled[3] AND packCalc.cornerIndexFilled[4] AND packCalc.cornerIndexFilled[5] THEN
				// All corners detected
				// Width of box: sqrt ( (dx)^2 + (dy)^2 )
				// dx = trackwidth - sensor distance at mid corner - sensor distance at trailing corner
				// dy = track velocity * cycles spent from mid corner to trailing corner * cycle time
				newPack.width := SQRT( 
				(TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[1]) 
				* (TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[1]) 
				+ (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[1]) * 10) 
				* (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[1]) * 10)
				);
				
				// Length is found in a similar fashion
				newPack.width := SQRT(
				(TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[4]].width[1] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[0]) 
				* (TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[4]].width[1] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[0]) 
				+ (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[4]) * 10) 
				* (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[4]) * 10)
				);
				
				// Height is taken at the mid-corner point
				newPack.height := LASER_DEFAULT_VALUE_HEIGHT - packageDetectionBuffer[packCalc.cornerIndex[1]].height;
				
				
			ELSIF packCalc.cornerIndexFilled[0] AND NOT packCalc.cornerIndexFilled[1] AND packCalc.cornerIndexFilled[2] AND
				packCalc.cornerIndexFilled[3] AND NOT packCalc.cornerIndexFilled[4] AND packCalc.cornerIndexFilled[5] THEN
				// Midpoint(s) not found, randomly perfectly straight box?
				// Makes it easy enough
				newPack.width := TRACK_WIDTH - packageDetectionBuffer[REAL_TO_INT((packCalc.cornerIndex[0] + packCalc.cornerIndex[2]) / 2)].width[0] - packageDetectionBuffer[REAL_TO_INT((packCalc.cornerIndex[0] + packCalc.cornerIndex[2]) / 2)].width[1];
				newPack.height := 300; (* The laser in Experior doesn't want to work in vertical orientation .. *)
				newPack.length := 0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[0]) * 10;
			END_IF
			
			// Calculate volume from found WxLxH and select the package size type
			newPack.volume := newPack.height * newPack.width * newPack.length;
			IF newPack.volume >= packRanges.small.min.volume AND newPack.volume <= packRanges.small.max.volume THEN
				// Pack is inside the 'small' range
				newPack.size := PACKAGE_SMALL;
			ELSIF newPack.volume >= packRanges.medium.min.volume AND newPack.volume <= packRanges.medium.max.volume THEN
				// Pack is inside the 'medium' range
				newPack.size := PACKAGE_MEDIUM;
			ELSIF newPack.volume >= packRanges.large.min.volume AND newPack.volume <= packRanges.large.max.volume THEN
				// Pack is inside the 'large' range
				newPack.size := PACKAGE_LARGE;
			ELSE
				// Pack not in any ranges;
				newPack.size := PACKAGE_INVALID;
			END_IF
			
			// Reset the flag for new package to be loaded by robot1
			newPackReady := TRUE;
			
			// Set robot1 target position based on package height and position on track
			IF packageDetectionBuffer[packCalc.cornerIndex[1]].height > PACKAGE_PICKUP_LOW_LIMIT THEN
				IF packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] > PACKAGE_PICKUP_WIDTH_LIMIT THEN
					robot1.target := RTARGET_PICKUP_1;
				ELSE
					robot1.target := RTARGET_PICKUP_2;
				END_IF
			ELSE
				IF packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] > PACKAGE_PICKUP_WIDTH_LIMIT THEN
					robot1.target := RTARGET_PICKUP_3;
				ELSE
					robot1.target := RTARGET_PICKUP_4;
				END_IF
			END_IF
			
			// Start robot1 via the pickup state
			robot1.state := RSTATE_PICKUP;
			
			// Reset the buffer index to pseudo clear it
			bufIndex := 0;
			
			// Clear the packCalc
			FOR Index:=0 TO 5 DO
				packCalc.cornerIndex[Index] := FALSE;
				packCalc.cornerIndexFilled[Index] := FALSE;
			END_FOR
			FOR Index:=0 TO 1 DO
				packCalc.heightIndex[Index] := FALSE;
				packCalc.heightIndexFilled[Index] := FALSE;
			END_FOR
			
			
			// Change the sensor loop state
			sensorState := STATE_SENSOR_WAIT_FOR_PICKUP;
			
		STATE_SENSOR_WAIT_FOR_PICKUP:
			// Wait until robot1 has picked up the package
			IF NOT newPackReady THEN
				// Package has been cleared by the robot, restart the conveyors and feeder
				conveyors.circular.run := TRUE;
				conveyors.feed.run := TRUE;
				packFeeder.doFeed := TRUE;
				
				// Change to the waiting state
				sensorState := STATE_SENSOR_WAIT_FOR_PICKUP;
			END_IF
	END_CASE
	
	
	
	//////////////////////////
	// This is an old block of code
	//////////////////////////
	
//	// Conveyor loop
//	// Measuring packages if sensors show anything on width
//	IF (sensors.widthBlocked[0] OR
//		sensors.widthBlocked[1]) AND
//		NOT doublePackageDetected THEN
//
//		// Set the 'currently measuring' flag
//		packageInDetection := TRUE;
//		
//		// Lasers in Experior are very very broken
//		// They cannot do distance measurements unless perfectly level
//		// This was only found out after preparing for it..
//		
//		// Grab a set of data
//		//packageDetectionBuffer[bufIndex].height := MAX(sensors.height[0], sensors.height[1], sensors.height[2]);
//		packageDetectionBuffer[bufIndex].height := 300; (* Let's pretend it's always 300mm. I blame Experior. *)
//		packageDetectionBuffer[bufIndex].width := sensors.width;
//		
//		// TODO: Do a check to see if we have transitioned to measuring a new package? 
//		// Check if width has changed direction twice?? 
//		// Move to next step by using "doublePackageDetected" and ignore the second package
//		// Maybe some check to stop the feeder if conveyor is filled? 
//		
//		// Increment the buffer index, and check for overflow
//		IF bufIndex > bufSize - 1 THEN
//			// Size overflow, just set the flag for multiple packages
//			doublePackageDetected := TRUE;
//		ELSE
//			// Increment for next measurement
//			bufIndex := bufIndex + 1;
//		END_IF
//		
//	ELSIF packageInDetection OR doublePackageDetected THEN
//		// Sensors didn't detect anything after measuring, or second pack is detected
//		// Reset the flags
//		packageInDetection := FALSE;
//		doublePackageDetected := FALSE;
//		
//		// If the newPackLoaded it true and robot1 is ready for pickup, fill newPack and start robot1
//		// If not, ignore the package. The robot might not be able to reach it in time
//		// TODO: Somehow check if the circular conveyor is overfilled? 
//		IF newPackLoaded AND robot1.state = RSTATE_WAITING THEN
//			// We assume a box shape. BufIndex should be a filled measurement.
//			// Find a corner
//			FOR Index:=0 TO bufIndex - 1 DO
//				
//				// Resolution in the track direction isn't great, 0.5 m/s @ 10ms samples = 5mm 
//				
//				//// Width sensor 0
//				IF NOT packageDetectionBuffer[Index].width[0] = LASER_DEFAULT_VALUE_WIDTH THEN
//					// Valid measurement
//					// Save initial detection position in packCalc
//					IF NOT packCalc.cornerIndexFilled[0] THEN
//						packCalc.cornerIndex[0] := Index;
//						packCalc.cornerIndexFilled[0] := TRUE;
//					END_IF
//					// Sensors will always start going down, as free measurement is high limit
//					// If box is square on, they will not change
//					// If box is angled, it will ramp up until a corner, and ramp back down after. 
//					// Some detector measurement error has to be allowable, as a false positive wrecks the "algorithm"
//					// However this is simulated, so we won't 
//					IF packageDetectionBuffer[Index].width[0] < packageDetectionBuffer[Index + 1].width[0] THEN
//						// Corner found
//						IF NOT packCalc.cornerIndexFilled[1] THEN
//							packCalc.cornerIndex[1] := Index;
//							packCalc.cornerIndexFilled[1] := TRUE;
//						END_IF
//					END_IF
//					// Check for a ramp going up after finding the corner, that would be a new box
//					IF packageDetectionBuffer[Index].width[0] > packageDetectionBuffer[Index + 1].width[0] AND packCalc.cornerIndexFilled[1] THEN
//						IF NOT packCalc.cornerIndexFilled[2] THEN
//							packCalc.cornerIndex[2] := Index;
//							packCalc.cornerIndexFilled[2] := TRUE;
//						END_IF
//					END_IF
//				ELSIF packCalc.cornerIndexFilled[0] AND NOT packCalc.cornerIndexFilled[2] THEN
//					// If sensor is free and we did find the first point, this is the end
//					// If the third point is already filled, we found another box instead
//					// We decrement the index to save the last valid measurement instead of the first invalid one
//					packCalc.cornerIndex[2] := Index - 1;
//					packCalc.cornerIndexFilled[2] := TRUE;
//				END_IF
//				
//				//// Width sensor 1 (copied from width sensor 0)
//				IF NOT packageDetectionBuffer[Index].width[1] = LASER_DEFAULT_VALUE_WIDTH THEN
//					// Valid measurement
//					// Save initial detection position in packCalc
//					IF NOT packCalc.cornerIndexFilled[3] THEN
//						packCalc.cornerIndex[3] := Index;
//						packCalc.cornerIndexFilled[3] := TRUE;
//					END_IF
//					// Sensors will always start going down, as free measurement is high limit
//					// If box is square on, they will not change
//					// If box is angled, it will ramp up until a corner, and ramp back down after. 
//					// Some detector measurement error has to be allowable, as a false positive wrecks the "algorithm"
//					// However this is simulated, so we won't 
//					IF packageDetectionBuffer[Index].width[1] < packageDetectionBuffer[Index + 1].width[1] THEN
//						// Corner found
//						IF NOT packCalc.cornerIndexFilled[4] THEN
//							packCalc.cornerIndex[4] := Index;
//							packCalc.cornerIndexFilled[4] := TRUE;
//						END_IF
//					END_IF
//					// Check for a ramp going up after finding the corner, that would be a new box
//					IF packageDetectionBuffer[Index].width[1] > packageDetectionBuffer[Index + 1].width[1] AND packCalc.cornerIndexFilled[4] THEN
//						IF NOT packCalc.cornerIndexFilled[5] THEN
//							packCalc.cornerIndex[5] := Index;
//							packCalc.cornerIndexFilled[5] := TRUE;
//						END_IF
//					END_IF
//				ELSIF packCalc.cornerIndexFilled[3] AND NOT packCalc.cornerIndexFilled[5] THEN
//					// If sensor is free and we did find the first point, this is the end
//					// If the third point is already filled, we found another box instead
//					// We decrement the index to save the last valid measurement instead of the first invalid one
//					packCalc.cornerIndex[5] := Index - 1;
//					packCalc.cornerIndexFilled[5] := TRUE;
//				END_IF
//			END_FOR
//			
//			// For finding the dimensions, lets find the distance measured on the middle of each side
//			IF packCalc.cornerIndexFilled[0] AND packCalc.cornerIndexFilled[1] AND packCalc.cornerIndexFilled[2] AND
//				packCalc.cornerIndexFilled[3] AND packCalc.cornerIndexFilled[4] AND packCalc.cornerIndexFilled[5] THEN
//				// All corners detected
//				packCalc.sideMidPoint[0] := REAL_TO_INT(0.5 * INT_TO_REAL(packCalc.cornerIndex[0] + packCalc.cornerIndex[1]));
//				packCalc.sideMidPoint[1] := REAL_TO_INT(0.5 * INT_TO_REAL(packCalc.cornerIndex[1] + packCalc.cornerIndex[2]));
//				packCalc.sideMidPoint[2] := REAL_TO_INT(0.5 * INT_TO_REAL(packCalc.cornerIndex[3] + packCalc.cornerIndex[4]));
//				packCalc.sideMidPoint[3] := REAL_TO_INT(0.5 * INT_TO_REAL(packCalc.cornerIndex[4] + packCalc.cornerIndex[5]));
//				
//				// Width of box: sqrt ( (dx)^2 + (dy)^2 )
//				// dx = trackwidth - sensor distance at mid corner - sensor distance at trailing corner
//				// dy = track velocity * cycles spent from mid corner to trailing corner * cycle time
//				newPack.width := SQRT( 
//					(TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[1]) 
//					* (TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[1]) 
//					+ (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[1]) * 10) 
//					* (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[1]) * 10)
//				);
//				
//				// Length is found in a similar fashion
//				newPack.width := SQRT(
//					(TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[4]].width[1] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[0]) 
//					* (TRACK_WIDTH - packageDetectionBuffer[packCalc.cornerIndex[4]].width[1] - packageDetectionBuffer[packCalc.cornerIndex[2]].width[0]) 
//					+ (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[4]) * 10) 
//					* (0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[4]) * 10)
//				);
//				
//				// Height is taken at the mid-corner point
//				newPack.height := LASER_DEFAULT_VALUE_HEIGHT - packageDetectionBuffer[packCalc.cornerIndex[1]].height;
//				
//				
//			ELSIF packCalc.cornerIndexFilled[0] AND NOT packCalc.cornerIndexFilled[1] AND packCalc.cornerIndexFilled[2] AND
//				packCalc.cornerIndexFilled[3] AND NOT packCalc.cornerIndexFilled[4] AND packCalc.cornerIndexFilled[5] THEN
//				// Midpoint(s) not found, randomly perfectly straight box?
//				// Makes it easy enough
//				packCalc.sideMidPoint[0] := REAL_TO_INT(0.5 * INT_TO_REAL(packCalc.cornerIndex[0] + packCalc.cornerIndex[2]));
//				
//				newPack.width := TRACK_WIDTH - packageDetectionBuffer[packCalc.sideMidPoint[0]].width[0] - packageDetectionBuffer[packCalc.sideMidPoint[0]].width[1];
//				newPack.height := LASER_DEFAULT_VALUE_HEIGHT - packageDetectionBuffer[packCalc.sideMidPoint[0]].height;
//				newPack.length := 0.5 * (packCalc.cornerIndex[2] - packCalc.cornerIndex[0]) * 10;
//			END_IF
//			
//			// Calculate volume from found WxLxH and select the package size type
//			newPack.volume := newPack.height * newPack.width * newPack.length;
//			IF newPack.volume >= packRanges.small.min.volume AND newPack.volume <= packRanges.small.max.volume THEN
//				// Pack is inside the 'small' range
//				newPack.size := PACKAGE_SMALL;
//			ELSIF newPack.volume >= packRanges.medium.min.volume AND newPack.volume <= packRanges.medium.max.volume THEN
//				// Pack is inside the 'medium' range
//				newPack.size := PACKAGE_MEDIUM;
//			ELSIF newPack.volume >= packRanges.large.min.volume AND newPack.volume <= packRanges.large.max.volume THEN
//				// Pack is inside the 'large' range
//				newPack.size := PACKAGE_LARGE;
//			ELSE
//				// Pack not in any ranges;
//				newPack.size := PACKAGE_INVALID;
//			END_IF
//			
//			// Reset the flag for new package to be loaded by robot1
//			newPackReady := TRUE;
//			
//			// Set robot1 target position based on package height and position on track
//			IF packageDetectionBuffer[packCalc.cornerIndex[1]].height > PACKAGE_PICKUP_LOW_LIMIT THEN
//				IF packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] > PACKAGE_PICKUP_WIDTH_LIMIT THEN
//					robot1.target := RTARGET_PICKUP_1;
//				ELSE
//					robot1.target := RTARGET_PICKUP_2;
//				END_IF
//			ELSE
//				IF packageDetectionBuffer[packCalc.cornerIndex[1]].width[0] > PACKAGE_PICKUP_WIDTH_LIMIT THEN
//					robot1.target := RTARGET_PICKUP_3;
//				ELSE
//					robot1.target := RTARGET_PICKUP_4;
//				END_IF
//			END_IF
//			
//			// Start robot1 via the pickup state
//			robot1.state := RSTATE_PICKUP;
//			
//		END_IF
//		
//		// Pseudo-clear the buffer by resetting the index
//		bufIndex := 0;
//		
//	END_IF
	
	// Circular conveyor
//	IF newPackReady AND (robot1.state = RSTATE_WAITING OR robot1.state = RSTATE_PICKUP) THEN
//		// We can only pick up stationary packages, so wait for robot1 to clear the package
//		conveyors.circular := FALSE;
//		// Also stop the package feeder
//		packFeeder.doFeed := FALSE;
//	ELSIF newPackLoaded THEN
//		// Start the conveyor when a pack is done being grabbed
//		conveyors.circular := TRUE;
//		packFeeder.doFeed := TRUE;
//	END_IF
	
	//////////////////////////
	// This is the end of an old block of code
	//////////////////////////
	
	// Packing conveyor
	IF sensors.packageForPacker THEN
		// Stop the conveyor
		conveyors.packer.run := FALSE;
		// Start pickup once robot is ready
		IF robot2.state = RSTATE_WAITING THEN
			// Low packages get a lower pickup point
			IF packBuffer[0].height > PACKAGE_PICKUP_LOW_LIMIT THEN
				robot2.target := RTARGET_PICKUP_1;
			ELSE
				robot2.target := RTARGET_PICKUP_2;
			END_IF
			robot2.state := RSTATE_PICKUP;
		END_IF
	ELSE
		// If the above fsm is in state 3 or higher, just force the packer high
		IF sensorState > 2 THEN
			conveyors.packer.run := TRUE;
		END_IF
		
		// Update time spent moving since drop
		// robot1 checks for this time to exceed a value in the main loop
		// Experior input doesn't respond
		//IF conveyors.packer.isOn THEN
			timePacking := timePacking + t#10ms;
		//END_IF
		
		// If first time here since last activation, pop a package from buffer by shifting them
		IF sensors.packageForPackerPrevious THEN
			sensors.packageForPackerPrevious := sensors.packageForPacker;
			FOR Index:=0 TO packBufSize - 1 DO
				packBuffer[Index] := packBuffer[Index + 1];
			END_FOR
		END_IF
		
	END_IF
	
	// Discarding conveyor
	IF packDiscarded THEN
		// Reset flag
		packDiscarded := FALSE;
		
		// Run conveyor
		conveyors.discard.run := TRUE;
		
		// If timer is already running, hard reset
		IF timer_discard.IN THEN
			timer_discard.IN := FALSE;
			timer_discard();
		END_IF
		
		// Start the timer
		timer_discard.IN := TRUE;
		
	ELSIF timer_discard.Q THEN
		// Stop the timer when done
		timer_discard.IN := FALSE;
		
		// Stop the conveyor
		conveyors.discard.run := FALSE;
	END_IF
	
	// Update the timer block for discard conveyor
	timer_discard();
	
	// Feed conveyor gets the same state as the circular one
	conveyors.feed.run := conveyors.circular.run;
	
END_PROGRAM

PROGRAM _EXIT
	// Stop all of the things we can
	// Probably useless since we're dying fast
	
	conveyors.circular.run := FALSE;
	conveyors.discard.run := FALSE;
	conveyors.packer.run := FALSE;
	conveyors.feed.run := FALSE;
	robot1.state := RSTATE_E_STOP;
	robot2.state := RSTATE_E_STOP;
	
END_PROGRAM

