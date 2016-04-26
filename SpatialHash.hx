package ;

class SpatialHash {
	public var buckets(default,null): Map<Int,Array<SpatialEntity>>;
	public var entities(default,null): Array<SpatialEntity>;
	public var bucketSize(default,null): Float;
	public var invBs(default,null): Float;
	public var intersections(default,null): Map<Int,Array<SpatialEntity>>; 
	public var pool(default,null): Array<Array<SpatialEntity>>;

	public function new( bucketSize: Float ) {
		this.buckets = new Map<Int,Array<SpatialEntity>>();
		this.intersections = new Map<Int,Array<SpatialEntity>>();
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
			
			entities.push( e );
			e.spatialId = entities.length-1;
			doAdd( e, spatialLeft, spatialTop, spatialRight, spatialBottom );
			
			return true;
		} else {
			return false;
		}
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

			doRemove( e, spatialLeft, spatialTop, spatialRight, spatialBottom );
			removeIntersections( e );
			e.spatialId = -1;

			return true;
		}
		return false;
	}

	public function update( e: SpatialEntity, wasLeft: Float, wasTop: Float, wasRight: Float, wasBottom: Float ) {
		if ( exists( e )) {	
			var spatialLeft = Std.int(wasLeft * invBs);
			var spatialTop = Std.int(wasTop * invBs);
			var spatialRight = Std.int(wasRight * invBs);
			var spatialBottom = Std.int(wasBottom * invBs);
			var spatialLeftNew = Std.int(e.aabbLeft * invBs);
			var spatialTopNew = Std.int(e.aabbTop * invBs);
			var spatialRightNew = Std.int(e.aabbRight * invBs);
			var spatialBottomNew = Std.int(e.aabbBottom * invBs);
			var checked: Map<Int,Bool> = null;

			doRemove( e, spatialLeft, spatialTop, spatialRight, spatialBottom );
			checked = doAdd( e, spatialLeftNew, spatialTopNew, spatialRightNew, spatialBottomNew );
			updateIntersections( e, checked );
			return true;
	
		} else {
			return false;
		}
	}

	public inline function makeIndex( x, y ) {
		return (x<<16) + (1<<15) + y;
	}

	public static inline function aabbAABB( left1: Float, top1: Float, right1: Float, bottom1: Float, left2: Float, top2: Float, right2: Float, bottom2: Float ) {	
		return left1 < right2 && left2 < right1 && top1 < bottom2 && top2 < bottom1;
	}

	public static inline function checkAABBIntersection( e: SpatialEntity, o: SpatialEntity ) {
		return aabbAABB( e.aabbLeft, e.aabbTop, e.aabbRight, e.aabbBottom, o.aabbLeft, o.aabbTop, o.aabbRight, o.aabbBottom );
	}

	public static inline function checkGroupIntersection( e: SpatialEntity, o: SpatialEntity ) {
		return e.spatialGroup < 0 || o.spatialGroup < 0 || (e.spatialGroup & o.spatialGroup != 0);
	}

	public function checkPreciseIntersection( e: SpatialEntity, o: SpatialEntity ) {
		return true;
	}
	
	@:extern inline function doAdd( e: SpatialEntity, spatialLeft: Int, spatialTop: Int, spatialRight: Int, spatialBottom: Int ) {
		var checked: Map<Int, Bool> = null;
		for ( x in spatialLeft...spatialRight+1 ) {
			for ( y in spatialTop...spatialBottom+1 ) {
				checked = addSingle( e, x, y, checked );
			}
		}
		return checked;
	}
	
	@:extern inline function doRemove( e: SpatialEntity, spatialLeft: Int, spatialTop: Int, spatialRight: Int, spatialBottom: Int ) {
		for ( x in spatialLeft...spatialRight+1 ) {
			for ( y in spatialTop...spatialBottom+1 ) {
				removeSingle( e, x, y );
			}
		}
	}

	// FIXME
	@:extern inline function removeIntersections( e: SpatialEntity ) {
		var eintersections = intersections.get( e.spatialId );
		if ( eintersections != null ) {
			for ( i in 0...eintersections.length ) { 
				var o = eintersections.pop();

				e.onStopIntersection( o, this );
				o.onStopIntersection( e, this );
				
				var ointersections = intersections.get( o.spatialId );
				if ( ointersections != null ) {
					fastRemove( ointersections, e );
					if ( ointersections.length <= 0 ) {
						pool.push( ointersections );
						intersections.remove( o.spatialId );
					}
				}
			}

			pool.push( eintersections );
			intersections.remove( e.spatialId );
		}
	}

	static var BLANK_CHECKED = new Map<Int,Bool>();

	@:extern inline function updateIntersections( e: SpatialEntity, checked: Map<Int,Bool> ) {
		var eintersections = intersections.get( e.spatialId );
		
		if ( checked == null ) {
			checked = BLANK_CHECKED;
		}

		if ( eintersections != null ) {
			for ( o in eintersections ) {
				if ( !checked[o.spatialId] ) {
					fastRemove( eintersections, o );
					e.onStopIntersection( o, this );
					o.onStopIntersection( e, this );

					var ointersections = intersections.get( o.spatialId );
					if ( ointersections != null ) {
						fastRemove( ointersections, e );
						if ( ointersections.length <= 0 ) {
							pool.push( ointersections );
							intersections.remove( o.spatialId );
						}
					}
				}
			}

			if ( eintersections.length <= 0 ) {
				pool.push( eintersections );
				intersections.remove( e.spatialId );
			}
		}
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
	
	@:extern inline function addSingle( e: SpatialEntity, x: Int, y: Int, checked: Map<Int,Bool> ) {
		var idx = makeIndex( x, y );
		var bucket = buckets.get( idx );

		if ( bucket == null ) {
			bucket = newPooledBucket1( e );
			buckets.set( idx, bucket );
		}	else {
			checked = checkIntersectionsInBucket( e, bucket, checked );
			if ( bucket.indexOf( e ) < 0 ) {
				bucket.push( e );
			}
		}

		return checked;
	}

	@:extern inline function newPooledBucket(): Array<SpatialEntity> {
		return ( pool.length > 0 ) ? pool.pop() : [];
	}

	@:extern inline function newPooledBucket1( e: SpatialEntity ): Array<SpatialEntity> {
		var bucket = newPooledBucket();
		bucket.push( e );
		return bucket;
	}

	@:extern inline function checkIntersectionsInBucket( e: SpatialEntity, bucket: Array<SpatialEntity>, checked: Map<Int,Bool> ) {
		if ( checked == null ) {
			checked = [e.spatialId => true];
		}
		
		var eintersections = intersections.get( e.spatialId );
		for ( o in bucket ) {
			if ( !checked.exists(o.spatialId) ) {
				checked.set( o.spatialId, true );

				var ointersections = intersections.get( o.spatialId );
				
				if (checkGroupIntersection( e, o ) && checkAABBIntersection( e, o ) && checkPreciseIntersection( e, o )) {
					if ( ointersections == null ) {
						ointersections = newPooledBucket1( e );
						intersections.set( o.spatialId, ointersections );
					} else {
						ointersections.push( e );
					}

					if ( eintersections == null ) {
						eintersections = newPooledBucket1( o );
						intersections.set( e.spatialId, eintersections );
						e.onBeginIntersection( o, this );
						o.onBeginIntersection( e, this );
					} else {
						if ( eintersections.indexOf( o ) >= 0 ) {
							e.onIntersection( o, this );
							o.onIntersection( e, this );
						}	else {
							eintersections.push( o );
							e.onBeginIntersection( o, this );
							o.onBeginIntersection( e, this );
						}
					}
				} else {
					if ( eintersections != null ) {
						var idx = eintersections.indexOf( o );
						if ( idx >= 0 ) {
							fastRemoveAt( eintersections, idx );
							e.onStopIntersection( o, this );
							o.onStopIntersection( e, this );
						}
					}

					if ( ointersections != null ) {
						var iidx = ointersections.indexOf( e );
						if ( iidx >= 0 ) {
							fastRemoveAt( ointersections, iidx );	
							if ( ointersections.length <= 0 ) {
								intersections.remove( o.spatialId );
								pool.push( ointersections );	
							}
						}
					}
				}
			}
		}
			
		if ( eintersections != null && eintersections.length <= 0 ) {
			intersections.remove( e.spatialId );
			pool.push( eintersections );
		}

		return checked;
	}

	@:extern inline function removeSingle( e: SpatialEntity, x: Int, y: Int ) {
		var idx = makeIndex( x, y );
		var bucket = buckets.get( idx );
		if ( bucket != null ) {
			if ( bucket.length <= 1 ) {
				pool.push( bucket );
				bucket.pop();
				buckets.remove( idx );
			} else {
				fastRemove( bucket, e );
			}
		}
	}
}
