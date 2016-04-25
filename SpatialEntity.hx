package ;

interface SpatialEntity {
	public var spatialId: Int;
	public var spatialGroup: Int;
	public var shape: SpatialShape;

	public var aabbLeft: Float;
	public var aabbRight: Float;
	public var aabbTop: Float;
	public var aabbBottom: Float;
	
	public function onIntersection( e: SpatialEntity ): Void;
}
