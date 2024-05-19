import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import three.Vector2;

/**
 * tool for "unwrapping" and debugging three.js geometries UV mapping
 *
 * Sample usage:
 *	document.body.appendChild( UVsDebug( new SphereGeometry( 10, 10, 10, 10 ) );
 *
 */

class UVsDebug {
	static function UVsDebug(geometry:Dynamic, size:Int = 1024):CanvasElement {
		// handles wrapping of uv.x > 1 only

		var abc:String = 'abc';
		var a:Vector2 = new Vector2();
		var b:Vector2 = new Vector2();

		var uvs:Array<Vector2> = [new Vector2(), new Vector2(), new Vector2()];

		var face:Array<Int> = [];

		var canvas:CanvasElement = js.Browser.document.createElement('canvas');
		var width:Int = size; // power of 2 required for wrapping
		var height:Int = size;
		canvas.width = width;
		canvas.height = height;

		var ctx:CanvasRenderingContext2D = canvas.getContext('2d');
		ctx.lineWidth = 1;
		ctx.strokeStyle = 'rgb(63, 63, 63)';
		ctx.textAlign = 'center';

		// paint background white

		ctx.fillStyle = 'rgb(255, 255, 255)';
		ctx.fillRect(0, 0, width, height);

		var index:Dynamic = geometry.index;
		var uvAttribute:Dynamic = geometry.attributes.uv;

		if (index != null) {
			// indexed geometry

			for (i in 0...index.count) {
				face[0] = index.getX(i);
				face[1] = index.getX(i + 1);
				face[2] = index.getX(i + 2);

				uvs[0].fromBufferAttribute(uvAttribute, face[0]);
				uvs[1].fromBufferAttribute(uvAttribute, face[1]);
				uvs[2].fromBufferAttribute(uvAttribute, face[2]);

				processFace(face, uvs, i / 3);
			}

		} else {
			// non-indexed geometry

			for (i in 0...uvAttribute.count) {
				face[0] = i;
				face[1] = i + 1;
				face[2] = i + 2;

				uvs[0].fromBufferAttribute(uvAttribute, face[0]);
				uvs[1].fromBufferAttribute(uvAttribute, face[1]);
				uvs[2].fromBufferAttribute(uvAttribute, face[2]);

				processFace(face, uvs, i / 3);
			}
		}

		return canvas;

		function processFace(face:Array<Int>, uvs:Array<Vector2>, index:Int) {
			// draw contour of face

			ctx.beginPath();

			a.set(0, 0);

			for (j in 0...uvs.length) {
				var uv:Vector2 = uvs[j];

				a.x += uv.x;
				a.y += uv.y;

				if (j == 0) {
					ctx.moveTo(uv.x * (width - 2) + 0.5, (1 - uv.y) * (height - 2) + 0.5);
				} else {
					ctx.lineTo(uv.x * (width - 2) + 0.5, (1 - uv.y) * (height - 2) + 0.5);
				}
			}

			ctx.closePath();
			ctx.stroke();

			// calculate center of face

			a.divideScalar(uvs.length);

			// label the face number

			ctx.font = '18px Arial';
			ctx.fillStyle = 'rgb(63, 63, 63)';
			ctx.fillText(Std.string(index), a.x * width, (1 - a.y) * height);

			if (a.x > 0.95) {
				// wrap x // 0.95 is arbitrary

				ctx.fillText(Std.string(index), (a.x % 1) * width, (1 - a.y) * height);
			}

			//

			ctx.font = '12px Arial';
			ctx.fillStyle = 'rgb(191, 191, 191)';

			// label uv edge orders

			for (j in 0...uvs.length) {
				var uv:Vector2 = uvs[j];
				b.addVectors(a, uv).divideScalar(2);

				var vnum:Int = face[j];
				ctx.fillText(abc.charAt(j) + Std.string(vnum), b.x * width, (1 - b.y) * height);

				if (b.x > 0.95) {
					// wrap x

					ctx.fillText(abc.charAt(j) + Std.string(vnum), (b.x % 1) * width, (1 - b.y) * height);
				}
			}
		}
	}

	public static function main() {
		// sample usage
		// document.body.appendChild( UVsDebug( new SphereGeometry( 10, 10, 10, 10 ) );
	}
}