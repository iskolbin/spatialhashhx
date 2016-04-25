package ;

interface SpatialEntity {
	public var spatialId: Int;    // should be negative when created
	public var spatialGroup: Int; // if negative then checks with all entities 
																// if equals zero then fully passive
																// if positive then checks only if mask and check holds (i.e. this.spatialGroup & other.spatialGroup != 0 )
	
	public var shape: SpatialShape; // simplest is AABB -- checks run very fast

	public var aabbLeft: Float;
	public var aabbRight: Float;
	public var aabbTop: Float;
	public var aabbBottom: Float;
	
	public function onIntersection( e: SpatialEntity ): Void;
}
