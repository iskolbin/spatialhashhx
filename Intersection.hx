package ;

// AABB, Circle, Ray, LineSegment, Polygon, Point

class Intersection {
	#if spatialhash_force_inline @:extern #end 
	public static inline function aabbAABB( left1: Float, top1: Float, right1: Float, bottom1: Float, left2: Float, top2: Float, right2: Float, bottom2: Float ) {	
		return left1 < right2 && left2 < right1 && top1 < bottom2 && top2 < bottom1;
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function aabbCircle( left: Float, top: Float, right: Float, bottom: Float, cx: Float, cy: Float, radius: Float ) {
		var closestX = (cx < left ? left : (cx > right ? right : cx));
		var closestY = (cy < top  ? top  : (cy > bottom? bottom: cy));
		var dx = closestX - cx;
		var dy = closestY - cy;

		return ( dx*dx + dy*dy ) <= radius * radius;
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function circleAABB( cx: Float, cy: Float, radius: Float, left: Float, top: Float, right: Float, bottom: Float ) 
		return aabbCircle( left, top, right, bottom, cx, cy, radius ); 

	#if spatialhash_force_inline @:extern #end 
	public static inline function aabbPoint( left: Float, top: Float, right: Float, bottom: Float, x: Float, y: Float ) {
		return x >= left && x <= right && y >= top && y <= bottom;
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function pointAABB( x: Float, y: Float, left: Float, top: Float, right: Float, bottom: Float ) 
		return aabbPoint( left, top, right, bottom, x, y );
	
	#if spatialhash_force_inline @:extern #end 
	public static inline function circleCircle( x1: Float, y1: Float, r1: Float, x2: Float, y2: Float, r2: Float ) {
		var dx = x1 - x2;
		var dy = y1 - y2;
		var d2 = dx*dx + dy*dy;
		return d2 <= (r1*r1+r2*r2);
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function circlePolygon( xc: Float, yc: Float, r: Float, vertices: Array<Float> ) {
		var i = 0;
		var contains = false;
		while ( i < vertices.length && !contains ) {
			contains = circlePoint( xc, yc, r, vertices[i], vertices[i+1] );
			i += 2;
		}
		return contains;
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function polygonCircle( vertices: Array<Float>, xc: Float, yc: Float, r: Float )
		return circlePolygon( xc, yc, r, vertices );

	#if spatialhash_force_inline @:extern #end 
	public static inline function circlePoint( xc: Float, yc: Float, r: Float, x: Float, y: Float ) {
		var dx = xc - x;
		var dy = yc - y;
		var d2 = dx*dx + dy*dy;
		return d2 <= r*r;
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function pointCircle( x: Float, y: Float, xc: Float, yc: Float, r: Float )
		return circlePoint( xc, yc, r, x, y );

	#if spatialhash_force_inline @:extern #end 
	public static inline function circleLineSegment( xc: Float, yc: Float, r: Float, x1: Float, y1: Float, x2: Float, y2: Float ) {
		return circlePoint( xc, yc, r, x1, y1 ) || circlePoint( xc, yc, r, x2, y2 );
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function circleRay( xc: Float, yc: Float, r: Float, x1: Float, y1: Float, x2: Float, y2: Float ) {
		return rayLineSegment( x1, y1, x2, y2, xc-r, yc, xc+r, yc ) || rayLineSegment( x1, y1, x2, y2, xc, yc-r, xc,  yc+r );
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function rayCircle( x1: Float, y1: Float, x2: Float, y2: Float, xc: Float, yc: Float, r: Float ) 
		return circleRay( xc, yc, r, x1, y1, x2, y2 );
	
	#if spatialhash_force_inline @:extern #end 
	public static inline function lineSegmentLineSegment( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float ) {
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

	#if spatialhash_force_inline @:extern #end 
	public static inline function polygonPolygon( vertices1: Array<Float>, vertices2: Array<Float> ) {
		var i = 2;
		var intersection = false;
		var x1 = vertices1[vertices1.length-2];
		var y1 = vertices1[vertices1.length-1];
		var x2 = vertices1[0];
		var y2 = vertices1[1];

		while ( true ) {
			intersection = lineSegmentPolygon( x1, y1, x2, y2, vertices2 );
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

	#if spatialhash_force_inline @:extern #end 
	public static inline function rayPolygon( x1: Float, y1: Float, x2: Float, y2: Float, vertices: Array<Float> ) {
		var i = 2;
		var intersection = false;
		var x3 = vertices[vertices.length-2];
		var y3 = vertices[vertices.length-1];
		var x4 = vertices[0];
		var y4 = vertices[1];

		while ( true ) {
			intersection = rayLineSegment( x1, y1, x2, y2, x3, y3, x4, y4 ); 
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

	#if spatialhash_force_inline @:extern #end 
	public static inline function polygonRay( vertices: Array<Float>, x1: Float, y1: Float, x2: Float, y2: Float ) 
		return rayPolygon( x1, y1, x2, y2, vertices );


	#if spatialhash_force_inline @:extern #end 
	public static inline function rayPolygonCount( x1: Float, y1: Float, x2: Float, y2: Float, vertices: Array<Float> ) {
		var i = 2;
		var x3 = vertices[vertices.length-2];
		var y3 = vertices[vertices.length-1];
		var x4 = vertices[0];
		var y4 = vertices[1];
		var count = 0;

		while ( true ) {
			var intersection = rayLineSegment( x1, y1, x2, y2, x3, y3, x4, y4 ); 
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

	#if spatialhash_force_inline @:extern #end 
	public static inline function pointPolygon( x1: Float, y1: Float, vertices: Array<Float> ) {
		var x2 = x1 == 0.0 ? 1.0 : 0.0;
		var y2 = y1 == 0.0 ? 1.0 : 0.0;
		var count = rayPolygonCount( x1, y1, x2, y2, vertices );
	 	return	count % 2 == 1;
	}

	#if spatialhash_force_inline @:extern #end 
	public static inline function polygonPoint( vertices: Array<Float>, x1: Float, y1: Float )
		return pointPolygon( x1, y1, vertices );

	#if spatialhash_force_inline @:extern #end 
	public static inline function rayRay( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float ) {
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

	#if spatialhash_force_inline @:extern #end 
	public static inline function rayLineSegment( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float ) {
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
	
	#if spatialhash_force_inline @:extern #end 
	public static inline function lineSegmentRay( x1: Float, y1: Float, x2: Float, y2: Float,  x3: Float, y3: Float, x4: Float, y4: Float )
		return rayLineSegment( x3, y3, x4, y4, x1, y1, x2, y2 );

	#if spatialhash_force_inline @:extern #end
	public static inline function lineSegmentPolygon( x1: Float, y1: Float, x2: Float, y2: Float, vertices: Array<Float> ) {
		var i = 2;
		var intersection = false;
		var x3 = vertices[vertices.length-2];
		var y3 = vertices[vertices.length-1];
		var x4 = vertices[0];
		var y4 = vertices[1];

		while ( i < vertices.length && !intersection) {
			intersection = lineSegmentLineSegment( x1, y1, x2, y2, x3, y3, x4, y4 ); 
			x3 = x4;
			y3 = y4;
			i += 2;	
			x4 = vertices[i];
			y4 = vertices[i+1];
		}

		return intersection;
	}

	#if spatialhash_force_inline @:extern #end
	public static inline function polygonLineSegment( vertices: Array<Float>, x1: Float, y1: Float, x2: Float, y2: Float ) 
		return lineSegmentPolygon( x1, y1, x2, y2, vertices );
	
	#if spatialhash_force_inline @:extern #end
	public static inline function aabbPolygon( left: Float, top: Float, right: Float, bottom: Float, vertices: Array<Float> ) {
		var c = lineSegmentPolygon( left, top, right, top, vertices );
		if ( c ) {
			c = lineSegmentPolygon( right, top, right, bottom, vertices );
			if ( c ) {
				c = lineSegmentPolygon( right, bottom, left, bottom, vertices );
				if ( c ) {
					c = lineSegmentPolygon( left, bottom, left, top, vertices );
				}
			}
		}
		return c;
	}

	#if spatialhash_force_inline @:extern #end
	public static inline function polygonAABB( vertices: Array<Float>, left: Float, top: Float, right: Float, bottom: Float )
		return aabbPolygon( left, top, right, bottom, vertices );

	#if spatialhash_force_inline @:extern #end
	public static inline function aabbLineSegment( left: Float, top: Float, right: Float, bottom: Float, x0: Float, y0: Float, x1: Float, y1: Float ) {
		var c = lineSegmentLineSegment( left, top, right, top, x0, y0, x1, y1 );
		if ( c ) {
			c = lineSegmentLineSegment( right, top, right, bottom, x0, y0, x1, y1 );
			if ( c ) {
				c = lineSegmentLineSegment( right, bottom, left, bottom, x0, y0, x1, y1 );
				if ( c ) {
					c = lineSegmentLineSegment( left, bottom, left, top, x0, y0, x1, y1 );
				}
			}
		}
		return c;
	}	

	#if spatialhash_force_inline @:extern #end
	public static inline function lineSegmentAABB( x0: Float, y0: Float, x1: Float, y1: Float, left: Float, top: Float, right: Float, bottom: Float )
		return aabbLineSegment( left, top, right, bottom, x0, y0, x1, y1 );

	#if spatialhash_force_inline @:extern #end
	public static inline function aabbRay( left: Float, top: Float, right: Float, bottom: Float, x0: Float, y0: Float, x1: Float, y1: Float ) {
		var c = rayLineSegment( left, top, right, top, x0, y0, x1, y1 );
		if ( c ) {
			c = rayLineSegment( right, top, right, bottom, x0, y0, x1, y1 );
			if ( c ) {
				c = rayLineSegment( right, bottom, left, bottom, x0, y0, x1, y1 );
				if ( c ) {
					c = rayLineSegment( left, bottom, left, top, x0, y0, x1, y1 );
				}
			}
		}
		return c;
	}

	#if spatialhash_force_inline @:extern #end
	public static inline function rayAABB( x0: Float, y0: Float, x1: Float, y1: Float, left: Float, top: Float, right: Float, bottom: Float )
		return aabbRay( left, top, right, bottom, x0, y0, x1, y1 );
}
