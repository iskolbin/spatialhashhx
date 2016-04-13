"use strict";

var canvas = document.getElementById("canvas");
var ctx = canvas.getContext("2d");
var start = 0;
var w = canvas.width;
var h = canvas.height;
var INTERVAL = 1.0/60.0;
var N = 10000;
var R = 2;
var PI2 = 2 * Math.PI;
var es = new Float32Array(N*4);
var ew = 2;
var eh = 2;
var BUCKET_SIZE = 16;
var debug = false;

var spatialHash = new SpatialHash( BUCKET_SIZE );

canvas.style = "background: #000;";

function onIntersection( self, other ) {
	
}

function init() {
	for ( var i = 0; i < N; i++ ) {
		var x = ( Math.random()*w >> 0 );
		var y = ( Math.random()*h >> 0 );
		var e = {
			spatialId: -1,
			shape: Shape.AABB,
			aabbLeft: x,
			aabbRight: x + ew,
			aabbTop: y,
			aabbBottom: y + eh,
			vx: 100*Math.random()-50,
			vy: 100*Math.random()-50,
			onIntersection: function( other ) {
				//ctx.fillStyle = "#f00";
				//ctx.fillRect( other.aabbLeft - 5, other.aabbTop - 5, other.aabbRight - other.aabbLeft + 5, other.aabbBottom - other.aabbTop + 5 )
				let tmpvx = e.vx;
				let tmpvy = e.vy;
				e.vx = other.vx;
				e.vy = other.vy;
				other.vx = tmpvx;
				other.vy = tmpvy;
			},
		}
		spatialHash.add( e );
	}
}


function clear(mode) {
	ctx.fillStyle = "rgba(0,0,0,0.1)";
	ctx.fillRect(0,0,w,h);
	//ctx.clearRect(0,0,w,h);
}

function render() {
	ctx.fillStyle = "#fff";
	//ctx.beginPath();
	for ( var i = 0; i < spatialHash.entities.length; i++ ) {
		var e = spatialHash.entities[i];
		ctx.fillRect( e.aabbLeft, e.aabbTop, e.aabbRight - e.aabbLeft, e.aabbBottom - e.aabbTop );
	}

	if ( debug ) {
		ctx.font = "8px Arial";
		for ( var x = 0; x < w / BUCKET_SIZE; x++ ) {
			for ( var y = 0; y < h / BUCKET_SIZE; y++ ) {
				var bucket = spatialHash.buckets.h[(x<<15)+y];
				if ( bucket ) {
					ctx.fillStyle = "rgba(255,0,0,0.3)";
					ctx.fillRect(x * BUCKET_SIZE, y*BUCKET_SIZE, BUCKET_SIZE, BUCKET_SIZE );
					ctx.fillStyle = "#fff";
					ctx.fillText(bucket.length , x*BUCKET_SIZE, y*BUCKET_SIZE );
				}
			}
		}
	}
	//ctx.stroke();
}

function update(dt) {
	var g = 9.81*dt;
	for ( var i = 0; i < N; i++ ) {
		var e = spatialHash.entities[i];
		var x = e.aabbLeft;
		var y = e.aabbTop;
		var vx = e.vx;
		var vy = e.vy;
		
		if ((x <= 0 && vx < 0) || (x >= w && vx > 0)) {
			vx = -vx;
			e.vx = vx;
		}
		
		if ((y <= 0 && vy < 0) || (y >= h && vy > 0)) {
			vy = -vy;
			e.vy = vy;
		}

		spatialHash.addPos( e, vx*dt, vy*dt );
		
		e.vy = vy + g;
	}	
}

function step(timestamp) {
	if ( !start ) {
		start = timestamp;
		render();
	} else {
		var dt = 0.001 * (timestamp - start);
		if ( dt > INTERVAL ) {
			start = timestamp;
			clear("fade");
			update(dt);
			render();
		}
	}
	window.requestAnimationFrame(step);
}

init();

window.requestAnimationFrame(step);
