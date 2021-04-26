
TYPE
	(* Type with all sensors in scene *)
	sensorsType : STRUCT
		width : ARRAY[0..1] OF INT;
		widthBlocked : ARRAY[0..1] OF BOOL;
		height : ARRAY[0..2] OF INT;
		heightBlocked : ARRAY[0..2] OF BOOL;
		packageForPacker : BOOL;
		packageForPackerPrevious : BOOL;
	END_STRUCT;
	
	(* Type for holding a set from the package measuring sensors *)
	bufferType : STRUCT
		width : ARRAY[0..1] OF INT;
		height : INT;
	END_STRUCT;
	
	(* Type with all conveyors in scene *)
	conveyorsType : STRUCT
		circular : conveyorType;			(*  *)
		feed : conveyorType;				(*  *)
		discard : conveyorType;				(*  *)
		packer : conveyorType;				(*  *)
	END_STRUCT;
	(* Type for a specific conveyor *)
	conveyorType : STRUCT
		run : BOOL;			(*  *)
		isOn : BOOL;		(*  *)
	END_STRUCT;
	
	(* Singular robot control type *)
	robotType : STRUCT
		state : robotStateEnum;		(*  *)
		nextState : robotStateEnum; (*  *)
		target : robotTargetEnum;	(*  *)
		previousTarget : robotTargetEnum; (*  *)
		comm : robotCommunicationType; (*  *)
		grip : BOOL;				(*  *)
		isGripping : BOOL;			(*  *)
		inPosition : BOOL;			(*  *)
		isWaiting : BOOL;			(*  *)
	END_STRUCT;
	
	(* Robot state Enum *)
	robotStateEnum : (
		RSTATE_INIT, 			(*  *)
		RSTATE_FORCE_HOME,		(*  *)
		RSTATE_WAITING,		(*  *)
		RSTATE_PICKUP,		(*  *)
		RSTATE_PICKUP_R,
		RSTATE_DROP,		(*  *)
		RSTATE_DROP_R,
		RSTATE_CLEAR,
		RSTATE_E_STOP		(*  *)
	);
	(* Robot target/path Enum *)
	robotTargetEnum : (
		RTARGET_FORCE_HOME := 0,	(*  *)
		RTARGET_PICKUP_1 := 10,		(*  *)
		RTARGET_PICKUP_1_R := 11,	(*  *)
		RTARGET_PICKUP_2 := 20,		(*  *)
		RTARGET_PICKUP_2_R := 21,	(*  *)
		RTARGET_PICKUP_3 := 30,		(*  *)
		RTARGET_PICKUP_3_R := 31,	(*  *)
		RTARGET_PICKUP_4 := 40,		(*  *)
		RTARGET_PICKUP_4_R := 41,	(*  *)
		RTARGET_DROPOFF_1 := 50,	(*  *)
		RTARGET_DROPOFF_1_R := 51,	(*  *)
		RTARGET_DROPOFF_2 := 60,	(*  *)
		RTARGET_DROPOFF_2_R := 61,	(*  *)
		RTARGET_DROPOFF_3 := 70,	(*  *)
		RTARGET_DROPOFF_3_R := 71,	(*  *)
		RTARGET_CLEAR := 99			(*  *)
	);
	
	(*  *)
	sensorStateEnum : (
		STATE_SENSOR_CONVEYOR_INIT := 0,
		STATE_SENSOR_CONVEYOR_STOP := 1,
		STATE_SENSOR_CONVEYOR_START := 2,
		STATE_SENSOR_WAIT,
		STATE_SENSOR_MEASURING,
		STATE_SENSOR_CALCULATING,
		STATE_SENSOR_WAIT_FOR_PICKUP
	);
	
	(* Type for wrapping single robot comms to RobotStudio Controller *)
	robotCommunicationType : STRUCT
		targets : robotTargetType; (*  *)
		isWaiting : BOOL; (* Is waiting / ready for new action *)
		inPosition : BOOL; (* Is in the last requested position *)
		doGrip : BOOL;	(* Digital output to the gripper *)
		diGrip : BOOL; 	(* Digital input from the gripper *)
	END_STRUCT;
	
	(*  *)
	robotTargetType : STRUCT
		initHome : BOOL;	(* Communication to the robot *)
		home : BOOL;		(*  happens through booleans  *)
		pick1 : BOOL;		(*  only.                     *)
		pick2 : BOOL;		(* We've not been able to r/w *)
		pick3 : BOOL;		(*  other datatypes.          *)
		pick4 : BOOL;		(* initHome overrides to home *)
		drop1 : BOOL;		(* home with target reverses  *)
		drop2 : BOOL;		(*  the target path.          *)
		drop3 : BOOL;		(*                            *)
	END_STRUCT;
	
	(* Feeder control type *)
	packFeederType : STRUCT
		doFeed : BOOL;
		isFeeding : BOOL;
	END_STRUCT;

	(* Enum of package sizes *)
	packageSizeEnum : 
		(
		PACKAGE_INVALID,
		PACKAGE_SMALL,
		PACKAGE_MEDIUM,
		PACKAGE_LARGE
	);
	
	(* Package type *)
	packageType : STRUCT
		width : REAL;
		length : REAL;
		height : REAL;
		volume : REAL;
		size : packageSizeEnum;	(* Package size as found after measurement *)
	END_STRUCT;
	
	(* Package size limit type *)
	packageSizeRangeType : STRUCT
		min : packageType;
		max : packageType;
	END_STRUCT;
	
	(* Accepted ranges type *)
	packingRangesType : STRUCT
		small : packageSizeRangeType;
		medium : packageSizeRangeType;
		large : packageSizeRangeType;
	END_STRUCT;
	
	(* Various variables used in package calculation *)
	packCalculationType : STRUCT
		cornerIndex : ARRAY[0..5] OF INT; (* Side start/end points on either side *)
		cornerIndexFilled : ARRAY[0..5] OF BOOL; (* 0..2 is for width0, 3..5 is for width1 *)
		heightIndex : ARRAY[0..1] OF INT; (* For first and second height change *)
		heightIndexFilled : ARRAY[0..1] OF BOOL; (*  *)
	END_STRUCT;
END_TYPE
