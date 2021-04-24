
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
		circular : BOOL;			(*  *)
		discard : BOOL;				(*  *)
		packer : BOOL;				(*  *)
	END_STRUCT;
	
	(* Singular robot control type *)
	robotType : STRUCT
		state : robotStateEnum;		(*  *)
		target : robotTargetEnum;	(*  *)
		comm : robotCommunicationType; (*  *)
		grip : BOOL;				(*  *)
		isGripping : BOOL;			(*  *)
		inPosition : BOOL;			(*  *)
		isWaiting : BOOL;			(*  *)
	END_STRUCT;
	
	(* Robot state Enum *)
	robotStateEnum : (
		RSTATE_INIT := 0, 			(*  *)
		RSTATE_TO_HOME := 4,		(*  *)
		RSTATE_WAITING := 5,		(*  *)
		RSTATE_PICKUP := 10,		(*  *)
		RSTATE_HOME_DROPOFF := 14,	(*  *)
		RSTATE_DROPOFF := 15,		(*  *)
		RSTATE_E_STOP := 100		(*  *)
	);
	(* Robot target Enum *)
	robotTargetEnum : (
		RTARGET_FORCE_HOME := 0,	(*  *)
		RTARGET_HOME_POS := 1,		(*  *)
		RTARGET_PICKUP_1 := 10,		(*  *)
		RTARGET_PICKUP_2 := 20,		(*  *)
		RTARGET_PICKUP_3 := 30,		(*  *)
		RTARGET_PICKUP_4 := 40,		(*  *)
		RTARGET_DROPOFF_1 := 50,	(*  *)
		RTARGET_DROPOFF_2 := 60,	(*  *)
		RTARGET_DROPOFF_3 := 70,	(*  *)
		RTARGET_CLEAR := 99			(*  *)
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
		home : BOOL;		(*  happens throug booleans   *)
		pick1 : BOOL;		(*  only.                     *)
		pick2 : BOOL;		(* We've not been able to r/w *)
		pick3 : BOOL;		(*  other datatypes.          *)
		pick4 : BOOL;		(* initHome overrides to home *)
		drop1 : BOOL;		(* home with target reverses  *)
		drop2 : BOOL;		(* the target path.           *)
		drop3 : BOOL;		(*                            *)
	END_STRUCT;
	
	(* Feeder control type *)
	packFeederType : STRUCT
		doFeed : BOOL;
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
		sideMidPoint : ARRAY[0..3] OF INT; (* 0..1 for width0, 2..3 for width1 *)
		heightIndex : ARRAY[0..1] OF INT; (* For first and second height change *)
		heightIndexFilled : ARRAY[0..1] OF BOOL; (*  *)
	END_STRUCT;
	
	point3DType : STRUCT
		x : REAL;
		y : REAL;
		z : REAL;
	END_STRUCT;
	
END_TYPE
