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

	public static var MAX_NEAREST_STEPS = 32;

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

	#if spatialhash_force_inline @:extern #end 
	static inline function fastRemoveAt<T>( array: Array<T>, index: Int ) {
		if ( index >= 0 ) {
			if ( index != array.length - 1 && array.length > 1 ) {
				array[index] = array.pop();
			} else {
				array.pop();
			}
		}
	}

	#if spatialhash_force_inline @:extern #end 
	static inline function fastRemove<T>( array: Array<T>, item: T ) {
		var index = array.indexOf( item );
		fastRemoveAt( array, index );
	}
	
	#if spatialhash_force_inline @:extern #end
	inline function addSingleTestIntersections( e: SpatialEntity, x: Int, y: Int, intersected: Map<Int,Bool> ) {
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
				if ( !intersected.exists(o.spatialId) && checkBroadIntersection( e, o ) && checkGroupIntersection( e, o )) {
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

	#if spatialhash_force_inline @:extern #end 
	inline function addSingle( e: SpatialEntity, x: Int, y: Int ) {
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

	public static inline function checkBroadIntersection( e: SpatialEntity, o: SpatialEntity ) {
		return Intersection.aabbAABB( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, o.aabbLeft, o.aabbTop, o.aabbRight, o.aabbBottom );
	}

	public static inline function checkGroupIntersection( e: SpatialEntity, o: SpatialEntity ) {
		return e.spatialGroup < 0 || o.spatialGroup < 0 || e.spatialGroup & o.spatialGroup != 0;
	}
	
	#if spatialhash_force_inline @:extern #end 
	static inline function checkIntersectionsInBucket( e: SpatialEntity, bucket: Array<SpatialEntity>, intersected: Map<Int,Bool> ) {
		if ( intersected == null ) {
			intersected = [e.spatialId => true];
		}
		for ( o in bucket ) {
			if ( !intersected.exists(o.spatialId) && checkGroupIntersection( e, o ) && checkBroadIntersection( e, o )) {
				if ( (e.shape == AABB && o.shape == AABB) || checkShapeIntersection( e, o ) ) {
					e.onIntersection( o );
					o.onIntersection( e );
				}
			}
		}
		return intersected;
	}

	#if spatialhash_force_inline @:extern #end 
	inline function removeSingle( e: SpatialEntity, x: Int, y: Int ) {
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
				case Circle(x,y,r): Intersection.aabbCircle( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x, y, r );
				case LineSegment(x1,y1,x2,y2): Intersection.aabbLineSegment( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x1, y1, x2, y2 );
				case Point(x,y): Intersection.aabbPoint( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x, y );
				case Ray(x1,y1,x2,y2): Intersection.aabbRay( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, x1, y1, x2, y2 );
				case Polygon(vertices): Intersection.aabbPolygon( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, vertices);
			}

			case Circle(x1,y1,r1): switch(o.shape) {
				case AABB: checkShapeIntersection(o,e);
				case Circle(x2,y2,r2): Intersection.circleCircle( x1, y1, r1, x2, y2, r2 );
				case LineSegment(x20,y20,x21,y21): Intersection.circleLineSegment( x1, y1, r1, x20, y20, x21, y21 );
				case Point(x2,y2): Intersection.circlePoint( x1, y1, r1, x2, y2 );
				case Ray(x20,y20,x21,y21): Intersection.circleRay( x1, y1, r1, x20, y20, x21, y21 );
				case Polygon(vertices): Intersection.circlePolygon( x1, y1, r1, vertices );
			}

			case LineSegment(x10,y10,x11,y11): switch(o.shape) {
				case AABB|Circle(_): checkShapeIntersection(o,e);
				case LineSegment(x20,y20,x21,y21): Intersection.lineSegmentLineSegment( x10, y10, x11, y11, x20, y20, x21, y21 );
				case Point(x2,y2): false;
				case Ray(x20,y20,x21,y21): Intersection.lineSegmentRay( x10, y10, x11, y11, x20, y20, x21, y21 );
				case Polygon(vertices): Intersection.lineSegmentPolygon( x10, y10, x11, y11, vertices );
			}

			case Point(x1,y1): switch(o.shape) {
				case AABB|Circle(_)|LineSegment(_): checkShapeIntersection(o,e);
				case Point(x2,y2): x1 == y1 && x2 == y2;
				case Ray(x20,y20,x21,y21): false;
				case Polygon(vertices): Intersection.pointPolygon( x1, y1, vertices );
			}
			
			case Ray(x10,y10,x11,y11): switch(o.shape) {
				case AABB|Circle(_)|LineSegment(_)|Point(_): checkShapeIntersection(o,e);
				case Ray(x20,y20,x21,y21): Intersection.rayRay( x10, y10, x11, y11, x20, y20, x21, y21 );
				case Polygon(vertices): Intersection.rayPolygon( x10, y10, x11, y11, vertices );
			}

			case Polygon(vertices1): switch(o.shape) {
				case AABB|Circle(_)|LineSegment(_)|Point(_)|Ray(_): checkShapeIntersection(o,e);
				case Polygon(vertices2): Intersection.polygonPolygon( vertices1, vertices2 );
			}
		}	
	}
	
}
