package ;

enum Shape {
	AABB;
	Circle( x: Float, y: Float, radius: Float);
	Point( x: Float, y: Float );
	LineSegment( x1: Float, y1: Float, x2: Float, y2: Float );
	Ray( x1: Float, y1: Float, x2: Float, y2: Float );
	Polygon( vertices: Array<Float> );
}
