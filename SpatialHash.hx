package ;

class SpatialHash {
	public var buckets(default,null): Map<Int,Array<SpatialEntity>>;
	public var entities(default,null): Array<SpatialEntity>;
	public var bucketSize(default,null): Float;
	public var invBs(default,null): Float;
	public var pool(default,null): Array<Array<SpatialEntity>>;

	public function new( bucketSize: Float ) {
		this.buckets = new Map<Int,Array<SpatialEntity>>();
		this.entities = [];
		this.bucketSize = bucketSize;
		this.invBs = 1.0 / bucketSize;
		this.pool = [];
	}

	public inline function exists( e: SpatialEntity ) {
		return e.spatialId >= 0 && entities[e.spatialId] == e;
	}

	public function add( e: SpatialEntity ) {
		if ( !exists( e )) {
			var spatialLeft = Std.int(e.aabbLeft * invBs);
			var spatialTop = Std.int(e.aabbTop * invBs);
			var spatialBottom = Std.int(e.aabbBottom * invBs);
			var spatialRight = Std.int(e.aabbRight * invBs);
			var intersected: Map<Int,Bool> = null;

			entities.push( e );
			e.spatialId = entities.length-1;

			if ( spatialRight != spatialLeft || spatialTop != spatialBottom ) {
				for ( x in spatialLeft...spatialRight+1 ) {
					for ( y in spatialTop...spatialBottom+1 ) {
						intersected = addSingleTestIntersections( e, x, y, intersected );
					}
				}
			} else {
				addSingleTestIntersections( e, spatialLeft, spatialTop, null );
			}

			return true;
		}
		return false;
	}

	public function remove( e: SpatialEntity ) {	
		if ( exists( e )) {
			var spatialLeft = Std.int(e.aabbLeft * invBs);
			var spatialTop = Std.int(e.aabbTop * invBs);
			var spatialBottom = Std.int(e.aabbBottom * invBs);
			var spatialRight = Std.int(e.aabbRight * invBs);
			var spatialIndex = e.spatialId;

			if ( spatialIndex != entities.length - 1 && entities.length > 1 ) {
				var movedEntity = entities.pop();
				entities[spatialIndex] = movedEntity;
				movedEntity.spatialId = spatialIndex;
			} else {
				entities.pop();
			}

			if ( spatialRight != spatialLeft || spatialTop != spatialBottom ) {
				for ( x in spatialLeft...spatialRight+1 ) {
					for ( y in spatialTop...spatialBottom+1 ) {
						removeSingle( e, x, y );
					}
				}
			} else {
				removeSingle( e, spatialLeft, spatialTop );
			}
			e.spatialId = -1;
			return true;
		}
		return false;
	}
	
	public static inline function min( a: Int, b: Int ) return (a <= b) ? a : b;
	
	public static inline function max( a: Int, b: Int ) return (a >= b) ? a : b;

	public function move( e: SpatialEntity, left: Float, top: Float, right: Float, bottom: Float ) {
		if ( exists( e )) {
			var spatialLeft = Std.int(e.aabbLeft * invBs);
			var spatialTop = Std.int(e.aabbTop * invBs);
			var spatialRight = Std.int(e.aabbRight * invBs);
			var spatialBottom = Std.int(e.aabbBottom * invBs);
			
			var spatialLeftNew = Std.int(left * invBs);
			var spatialTopNew = Std.int(top * invBs);
			var spatialRightNew = Std.int(right * invBs);
			var spatialBottomNew = Std.int(bottom * invBs);
			
			var intersected: Map<Int,Bool> = null;

			if ( spatialLeft != spatialLeftNew || spatialTop != spatialTopNew || spatialRight != spatialRightNew || spatialBottom != spatialBottomNew ) {		
				if ( spatialRight != spatialLeft || spatialTop != spatialBottom ) {
					for ( x in spatialLeft...spatialRight+1 ) {
						for ( y in spatialTop...spatialBottom+1 ) {
							removeSingle( e, x, y );
						}
					}
				} else {
					removeSingle( e, spatialLeft, spatialTop );
				}
			
				if ( spatialRightNew != spatialLeftNew || spatialTopNew != spatialBottomNew ) {				
					for ( x in spatialLeftNew...spatialRightNew+1 ) {
						for ( y in spatialTopNew...spatialBottomNew+1 ) {
							intersected = addSingleTestIntersections( e, x, y, intersected );
						}
					}
				}	 else {
					addSingle( e, spatialLeftNew, spatialTopNew );
				}
			}

			e.aabbLeft = left;
			e.aabbTop = top;
			e.aabbRight = right;
			e.aabbBottom = bottom;

			return true;
		}
		return false;
	}
	
	public inline function setPos( e: SpatialEntity, left: Float, top: Float ) {
		addPos( e, left - e.aabbLeft, top - e.aabbTop );
	}

	public inline function addPos( e: SpatialEntity, dleft: Float, dtop: Float ) {
		addAABB( e, dleft, dtop, dleft, dtop );
	}

	public inline function setSize( e: SpatialEntity, width: Float, height: Float ) {
		addSize( e, e.aabbRight - e.aabbLeft + width, e.aabbBottom - e.aabbTop + height );
	}

	public inline function addSize( e: SpatialEntity, dwidth: Float, dheight: Float ) {
		addAABB( e, 0, 0, dwidth, dheight );
	}

	public inline function setAABB( e: SpatialEntity, left: Float, top: Float, right: Float, bottom: Float ) {
		move( e, left, top, right, bottom );
	}

	public inline function addAABB( e: SpatialEntity, dleft: Float, dtop: Float, dright: Float, dbottom: Float ) {
		setAABB( e, e.aabbLeft + dleft, e.aabbTop + dtop, e.aabbRight + dright, e.aabbBottom + dbottom );
	}

	public inline static var MAX_NEAREST_STEPS = 64;

	public function getNearest( e: SpatialEntity, except: Map<Int,Bool> ) {
		if ( exists(e) && entities.length > 1 ) {
			var spatialLeft = Std.int( e.aabbLeft * invBs );
			var spatialTop = Std.int( e.aabbTop * invBs );
			var bucket = buckets.get( makeIndex( spatialLeft, spatialTop ));
			
			if ( bucket.length > 1 ) {
				for ( e_ in bucket ) {
					if (e_ != e && (except==null || !except.exists(e_.spatialId))) {
						return e_;
					}
				}
			} else {
				for ( i in 0...MAX_NEAREST_STEPS ) {
					for ( x in spatialLeft-i...spatialLeft+i+1 ) {
						for ( y in spatialTop-i...spatialTop+i+1) {
							bucket = buckets.get( makeIndex( x, y ));
							if ( bucket != null ) {
								for ( e_ in bucket ) {
									if (e_ != e && except==null || !except.exists(e_.spatialId)) {
										return e_;
									}
								}
							}
						}
					}
				}
			}
		}
		return null;
	}

	public inline function makeIndex( x, y ) {
		return (x<<16) + (1<<15) + y;
	}

	@:extern static inline function fastRemoveAt<T>( array: Array<T>, index: Int ) {
		if ( index >= 0 ) {
			if ( index != array.length - 1 && array.length > 1 ) {
				array[index] = array.pop();
			} else {
				array.pop();
			}
		}
	}

	@:extern static inline function fastRemove<T>( array: Array<T>, item: T ) {
		var index = array.indexOf( item );
		fastRemoveAt( array, index );
	}
	
	@:extern inline function addSingleTestIntersections( e: SpatialEntity, x: Int, y: Int, intersected: Map<Int,Bool> ) {
		var idx = makeIndex( x, y );
		var bucket = buckets.get( idx );

		if ( bucket == null ) {
			if ( pool.length > 0 ) {
				bucket = pool.pop();
				bucket.push( e );
				buckets.set( idx, bucket );
			} else {
				buckets.set( idx, [e] );
			}
		}	else {
			if ( intersected == null ) {
				intersected = [e.spatialId => true];
			}
			for ( o in bucket ) {
				if ( !intersected.exists(o.spatialId) && checkAABBIntersection( e, o )) {
					if ( (e.shape == AABB && o.shape == AABB) || checkShapeIntersection( e, o ) ) {
						e.onIntersection( o );
						o.onIntersection( e );
					}
				}
			}

			intersected = checkIntersectionsInBucket( e, bucket, intersected );

			if ( bucket.indexOf( e ) < 0 ) {
				bucket.push( e );
			}
		}

		return intersected;
	}

	@:extern inline function addSingle( e: SpatialEntity, x: Int, y: Int ) {
		var idx = makeIndex( x, y );
		var bucket = buckets.get( idx );

		if ( bucket == null ) {
			if ( pool.length > 0 ) {
				bucket = pool.pop();
				bucket.push( e );
				buckets.set( idx, bucket );
			} else {
				buckets.set( idx, [e] );
			}
		} else {
			if ( bucket.indexOf( e ) < 0 ) {
				bucket.push( e );
			}
		}
	}

	@:extern inline function checkIntersectionsInBucket( e: SpatialEntity, bucket: Array<SpatialEntity>, intersected: Map<Int,Bool> ) {
		if ( intersected == null ) {
			intersected = [e.spatialId => true];
		}
		for ( o in bucket ) {
			if ( !intersected.exists(o.spatialId) && checkAABBIntersection( e, o )) {
				if ( (e.shape == AABB && o.shape == AABB) || checkShapeIntersection( e, o ) ) {
					e.onIntersection( o );
					o.onIntersection( e );
				}
			}
		}
		return intersected;
	}

	@:extern inline function removeSingle( e: SpatialEntity, x: Int, y: Int ) {
		var idx = makeIndex( x, y );
		var bucket = buckets.get( idx );
		if ( bucket.length <= 1 ) {
			pool.push( bucket );
			bucket.pop();
			buckets.remove( idx );
		} else {
			fastRemove( bucket, e );
		}
	}

	static function checkShapeIntersection( e: SpatialEntity, o: SpatialEntity ) {
		return switch (e.shape) {
			case AABB: switch(o.shape) {
				case AABB: true;
				case Circle(x,y,r): checkAABBCircle( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x, y, r );
				case LineSegment(x1,y1,x2,y2): checkAABBLineSegment( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x1, y1, x2, y2 );
				case Point(x,y): checkAABBPoint( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x, y );
				case Ray(x1,y1,x2,y2): checkAABBRay( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x1, y1, x2, y2 );
				case Polygon(vertices): checkAABBPolygon( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, vertices);
			}

			case Circle(x1,y1,r1): switch(o.shape) {
				case AABB: checkShapeIntersection(o,e);
				case Circle(x2,y2,r2): checkCircleCircle( x1, y1, r1, x2, y2, r2 );
				case LineSegment(x20,y20,x21,y21): checkCircleLineSegment( x1, y1, r1, x20, y20, x21, y21 );
				case Point(x2,y2): checkCirclePoint( x1, y1, r1, x2, y2 );
				case Ray(x20,y20,x21,y21): checkCircleRay( x1, y1, r1, x20, y20, x21, y21 );
				case Polygon(vertices): checkCirclePolygon( x1, y1, r1, vertices );
			}

			case LineSegment(x10,y10,x11,y11): switch(o.shape) {
				case AABB|Circle(_): checkShapeIntersection(o,e);
				case LineSegment(x20,y20,x21,y21): checkLineSegmentLineSegment( x10, y10, x11, y11, x20, y20, x21, y21 );
				case Point(x2,y2): false;
				case Ray(x20,y20,x21,y21): checkLineSegmentRay( x10, y10, x11, y11, x20, y20, x21, y21 );
				case Polygon(vertices): checkLineSegmentPolygon( x10, y10, x11, y11, vertices );
			}

			case Point(x1,y1): switch(o.shape) {
				case AABB|Circle(_)|LineSegment(_): checkShapeIntersection(o,e);
				case Point(x2,y2): x1 == y1 && x2 == y2;
				case Ray(x20,y20,x21,y21): false;
				case Polygon(vertices): checkPointPolygon( x1, y1, vertices );
			}
			
			case Ray(x10,y10,x11,y11): switch(o.shape) {
				case AABB|Circle(_)|LineSegment(_)|Point(_): checkShapeIntersection(o,e);
				case Ray(x20,y20,x21,y21): checkRayRay( x10, y10, x11, y11, x20, y20, x21, y21 );
				case Polygon(vertices): checkRayPolygon( x10, y10, x11, y11, vertices );
			}

			case Polygon(vertices1): switch(o.shape) {
				case AABB|Circle(_)|LineSegment(_)|Point(_)|Ray(_): checkShapeIntersection(o,e);
				case Polygon(vertices2): checkPolygonPolygon( vertices1, vertices2 );
			}
		}	
	}

	public static inline function checkAABBIntersection( e: SpatialEntity, o: SpatialEntity ) {
		return e.aabbLeft < o.aabbRight && 
			o.aabbLeft < e.aabbRight &&
			e.aabbTop < o.aabbBottom &&
			o.aabbTop < e.aabbBottom;
	}

	@:extern static inline function checkAABBCircle( left: Float, top: Float, right: Float, bottom: Float, cx: Float, cy: Float, radius: Float ) {
		var closestX = (cx < left ? left : (cx > right ? right : cx));
		var closestY = (cy < top  ? top  : (cy > bottom? bottom: cy));
		var dx = closestX - cx;
		var dy = closestY - cy;

		return ( dx*dx + dy*dy ) <= radius * radius;
	}

	@:extern static inline function checkCircleCircle( x1: Float, y1: Float, r1: Float, x2: Float, y2: Float, r2: Float ) {
		var dx = x1 - x2;
		var dy = y1 - y2;
		var d2 = dx*dx + dy*dy;
		return d2 <= (r1*r1+r2*r2);
	}

	@:extern static inline function checkCirclePolygon( xc: Float, yc: Float, r: Float, vertices: Array<Float> ) {
		var i = 0;
		var contains = false;
		while ( i < vertices.length && !contains ) {
			contains = checkCirclePoint( xc, yc, r, vertices[i], vertices[i+1] );
			i += 2;
		}
		return contains;
	}
	
	@:extern static inline function checkAABBPoint( left: Float, top: Float, right: Float, bottom: Float, x: Float, y: Float ) {
		return x >= left && x <= right && y >= top && y <= bottom;
	}
		
	@:extern static inline function checkCirclePoint( xc: Float, yc: Float, r: Float, x: Float, y: Float ) {
		var dx = xc - x;
		var dy = yc - y;
		var d2 = dx*dx + dy*dy;
		return d2 <= r*r;
	}

	@:extern static inline function checkCircleLineSegment( xc: Float, yc: Float, r: Float, x1: Float, y1: Float, x2: Float, y2: Float ) {
		var c1 = checkCirclePoint( xc, yc, r, x1, y1 );
		var c2 = checkCirclePoint( xc, yc, r, x2, y2 );
		return (c1 && !c2) || (!c1 && c2);
	}

	@:extern static inline function checkCircleRay( xc: Float, yc: Float, r: Float, x1: Float, y1: Float, x2: Float, y2: Float ) {
		var c1 = checkCirclePoint( xc, yc, r, x1, y1 );
		var c2 = checkCirclePoint( xc, yc, r, x2, y2 );
		return c1 || c2;
	}

	@:extern static inline function checkLineSegmentLineSegment( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float ) {
		var y2y1 = y2 - y1;
		var x2x1 = x2 - x1;
		var y4y3 = y4 - y3;
		var x4x3 = x4 - x3;
		var intersection = false;

		// Make sure the lines aren't parallel
		if ( y2y1/x2x1 != y4y3/x4x3 ) {
			var k1 = (y2 - y1) / (x2 - x1);
			var b1 = y1 - k1 * x1;
			var k2 = (y4 - y3) / (x4 - x3);
			var b2 = y3 - k2 * x3;
			var x0 = (b2 - b1) / (k2 - k1);
			var y0 = b1 + k1*x0;
			intersection = ((x2 > x1 && x0 >= x1 && x0 <= x2)||(x2 < x1 && x0 <= x1 && x0 >= x2)) && 
				((y2 > y1 && y0 >= y1 && y0 <= y2)||(y2 < y1 && y0 <= y1 && y0 >= y2)) &&
				((x4 > x3 && x0 >= x3 && x0 <= x4)||(x4 < x3 && x0 <= x3 && x0 >= x4)) && 
				((y4 > y3 && y0 >= y3 && y0 <= y4)||(y4 < y3 && y0 <= y3 && y0 >= y4));
		}

		return intersection;
	}
	
	@:extern static inline function checkPolygonPolygon( vertices1: Array<Float>, vertices2: Array<Float> ) {
		var i = 2;
		var intersection = false;
		var x1 = vertices1[vertices1.length-2];
		var y1 = vertices1[vertices1.length-1];
		var x2 = vertices1[0];
		var y2 = vertices1[1];

		while ( true ) {
			intersection = checkLineSegmentPolygon( x1, y1, x2, y2, vertices2 );
			if ( intersection ) break;
			i += 2;
			if ( i >= vertices1.length ) break;
			x1 = x2;
			y1 = y2;
			x2 = vertices1[i];
			y2 = vertices1[i+1];
		}

		return intersection;
	}

	@:extern static inline function checkRayPolygon( x1: Float, y1: Float, x2: Float, y2: Float, vertices: Array<Float> ) {
		var i = 2;
		var intersection = false;
		var x3 = vertices[vertices.length-2];
		var y3 = vertices[vertices.length-1];
		var x4 = vertices[0];
		var y4 = vertices[1];

		while ( true ) {
			intersection = checkRayLineSegment( x1, y1, x2, y2, x3, y3, x4, y4 ); 
			if ( intersection ) break;
			i += 2;
			if ( i >= vertices.length ) break;
			x3 = x4;
			y3 = y4;
			x4 = vertices[i];
			y4 = vertices[i+1];
		}

		return intersection;
	}

	@:extern static inline function getRayPolygonCount( x1: Float, y1: Float, x2: Float, y2: Float, vertices: Array<Float> ) {
		var i = 2;
		var x3 = vertices[vertices.length-2];
		var y3 = vertices[vertices.length-1];
		var x4 = vertices[0];
		var y4 = vertices[1];
		var count = 0;

		while ( true ) {
			var intersection = checkRayLineSegment( x1, y1, x2, y2, x3, y3, x4, y4 ); 
			if ( intersection ) {
				count++;
			}
			i += 2;	
			if ( i >= vertices.length ) break;
			x3 = x4;
			y3 = y4;
			x4 = vertices[i];
			y4 = vertices[i+1];
		}

		return count;
	}

	@:extern static inline function checkPointPolygon( x1: Float, y1: Float, vertices: Array<Float> ) {
		var x2 = x1 == 0.0 ? 1.0 : 0.0;
		var y2 = y1 == 0.0 ? 1.0 : 0.0;
		var count = getRayPolygonCount( x1, y1, x2, y2, vertices );
	 	return	count % 2 == 1;
	}
	
	@:extern static inline function checkRayRay( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float ) {
		var y2y1 = y2 - y1;
		var x2x1 = x2 - x1;
		var y4y3 = y4 - y3;
		var x4x3 = x4 - x3;
		var intersection = false;

		// Make sure the lines aren't parallel
		if ( y2y1/x2x1 != y4y3/x4x3 ) {
			var k1 = (y2 - y1) / (x2 - x1);
			var b1 = y1 - k1 * x1;
			var k2 = (y4 - y3) / (x4 - x3);
			var b2 = y3 - k2 * x3;
			var x0 = (b2 - b1) / (k2 - k1);
			var y0 = b1 + k1*x0;
			intersection = ((x2 > x1 && x0 >= x1)||(x2 < x1 && x0 <= x1)) && 
				((y2 > y1 && y0 >= y1)||(y2 < y1 && y0 <= y1)) &&
				((x4 > x3 && x0 >= x3)||(x4 < x3 && x0 <= x3)) && 
				((y4 > y3 && y0 >= y3)||(y4 < y3 && y0 <= y3));
		}

		return intersection;
	}

	@:extern static inline function checkRayLineSegment( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float ) {
		var y2y1 = y2 - y1;
		var x2x1 = x2 - x1;
		var y4y3 = y4 - y3;
		var x4x3 = x4 - x3;
		var intersection = false;

		// Make sure the lines aren't parallel
		if ( y2y1/x2x1 != y4y3/x4x3 ) {
			var d = x2x1*y4y3 - y2y1*x4x3;
			if ( d != 0.0 ) {
				var y1y3 = y1 - y3;
				var x1x3 = x1 - x3;
				var r = y1y3*x4x3 - x1x3*y4y3;
				var s = y1y3*x2x1 - x1x3*y2y1;
				intersection = ( d > 0.0 ) ? (r >= 0.0 && s >= 0.0 && s <= d) : (r <= 0.0 && s <= 0.0 && s >= d);
			}
		}
		
		return intersection;
	}

	@:extern static inline function checkLineSegmentRay( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float ) {
		return checkRayLineSegment( x3, y3, x4, y4, x1, y1, x2, y2 );
	}
	/*
		if ((y2_ - y1_) / (x2_ - x1_) != (y4_ - y3_) / (x4_ - x3_)) {
			d = (((x2_ - x1_) * (y4_ - y3_)) - (y2_ - y1_) * (x4_ - x3_));
			if ( d != 0.0 ) {
				r = (((y1_ - y3_) * (x4_ - x3_)) - (x1_ - x3_) * (y4_ - y3_)) / d;
				s = (((y1_ - y3_) * (x2_ - x1_)) - (x1_ - x3_) * (y2_ - y1_)) / d;
				if ( r >= 0 && s >= 0 && s <= 1) {
					return true;	
					//result.InsertSolution(x1_ + r * (x2_ - x1_), y1_ + r * (y2_ - y1_));
				}
			}
		}
		return false; 
	}*/

	@:extern static inline function checkLineSegmentPolygon( x1: Float, y1: Float, x2: Float, y2: Float, vertices: Array<Float> ) {
		var i = 2;
		var intersection = false;
		var x3 = vertices[vertices.length-2];
		var y3 = vertices[vertices.length-1];
		var x4 = vertices[0];
		var y4 = vertices[1];

		while ( i < vertices.length && !intersection) {
			intersection = checkLineSegmentLineSegment( x1, y1, x2, y2, x3, y3, x4, y4 ); 
			x3 = x4;
			y3 = y4;
			i += 2;	
			x4 = vertices[i];
			y4 = vertices[i+1];
		}

		return intersection;
	}

	@:extern static inline function checkAABBPolygon( left: Float, top: Float, right: Float, bottom: Float, vertices: Array<Float> ) {
		var c = checkLineSegmentPolygon( left, top, right, top, vertices );
		if ( c ) {
			c = checkLineSegmentPolygon( right, top, right, bottom, vertices );
			if ( c ) {
				c = checkLineSegmentPolygon( right, bottom, left, bottom, vertices );
				if ( c ) {
					c = checkLineSegmentPolygon( left, bottom, left, top, vertices );
				}
			}
		}
		return c;
	}
	
	@:extern static inline function checkAABBLineSegment( left: Float, top: Float, right: Float, bottom: Float, x0: Float, y0: Float, x1: Float, y1: Float ) {
		var c = checkLineSegmentLineSegment( left, top, right, top, x0, y0, x1, y1 );
		if ( c ) {
			c = checkLineSegmentLineSegment( right, top, right, bottom, x0, y0, x1, y1 );
			if ( c ) {
				c = checkLineSegmentLineSegment( right, bottom, left, bottom, x0, y0, x1, y1 );
				if ( c ) {
					c = checkLineSegmentLineSegment( left, bottom, left, top, x0, y0, x1, y1 );
				}
			}
		}
		return c;
	}	

	@:extern static inline function checkAABBRay( left: Float, top: Float, right: Float, bottom: Float, x0: Float, y0: Float, x1: Float, y1: Float ) {
		var c = checkRayLineSegment( left, top, right, top, x0, y0, x1, y1 );
		if ( c ) {
			c = checkRayLineSegment( right, top, right, bottom, x0, y0, x1, y1 );
			if ( c ) {
				c = checkRayLineSegment( right, bottom, left, bottom, x0, y0, x1, y1 );
				if ( c ) {
					c = checkRayLineSegment( left, bottom, left, top, x0, y0, x1, y1 );
				}
			}
		}
		return c;
	}	
}
