package ;

interface SpatialEntity<T:(SpatialEntity<T>)> {
	public var spatialId: Int;    // should be negative when created, altered by SpatialHash
	public var spatialGroup: Int; // if negative then checks with all entities
																// if equals zero then fully passive
																// if positive then checks only if mask and check holds (i.e. this.spatialGroup & other.spatialGroup != 0 )
	
	public var aabbLeft: Float;
	public var aabbRight: Float;
	public var aabbTop: Float;
	public var aabbBottom: Float;
	
	public function onBeginIntersection( e: T, spatialHash: SpatialHash<T> ): Void;
	public function onIntersection( e: T, spatialHash: SpatialHash<T> ): Void;
	public function onStopIntersection( e: T, spatialHash: SpatialHash<T> ): Void;
}
