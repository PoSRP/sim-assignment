
TYPE
	(* Type with all sensors in scene *)
	sensorsType : STRUCT
		width1 : INT;
		width1Blocked : BOOL;
		width2 : INT;
		width2Blocked : BOOL;
		height1 : INT;
		height1Blocked : BOOL;
		height2 : INT;
		height2Blocked : BOOL;
		height3 : INT;
		height3Blocked : BOOL;
		packageForPacker : BOOL;
	END_STRUCT;
	
	(* Type with all conveyors in scene *)
	conveyorsType : STRUCT
		circular : BOOL;
		discard : BOOL;
		packer : BOOL;
	END_STRUCT;
	
	(* Singular robot control type *)
	robotType : STRUCT
		
	END_STRUCT;

	(* Feeder control type *)
	packFeederType : STRUCT
		doFeed : BOOL;
	END_STRUCT;

	(* Package type *)
	packageType : STRUCT
		width : REAL;
		length : REAL;
		height : REAL;
		volume : REAL;
		good : BOOL;	(* Whether package is accepted or rejected *)
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
	
END_TYPE
