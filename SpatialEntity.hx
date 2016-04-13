package ;

interface SpatialEntity {
	public var spatialId: Int;
	public var shape: Shape;

	public var aabbLeft: Float;
	public var aabbRight: Float;
	public var aabbTop: Float;
	public var aabbBottom: Float;
	
	public function onIntersection( e: SpatialEntity ): Void;
}
