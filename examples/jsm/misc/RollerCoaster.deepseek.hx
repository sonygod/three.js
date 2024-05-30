import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.Quaternion;
import three.Raycaster;
import three.SRGBColorSpace;
import three.Vector3;

class RollerCoasterGeometry extends BufferGeometry {

	public function new(curve:Curve, divisions:Int) {

		super();

		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var colors:Array<Float> = [];

		var color1:Array<Float> = [ 1, 1, 1 ];
		var color2:Array<Float> = [ 1, 1, 0 ];

		var up:Vector3 = new Vector3( 0, 1, 0 );
		var forward:Vector3 = new Vector3();
		var right:Vector3 = new Vector3();

		var quaternion:Quaternion = new Quaternion();
		var prevQuaternion:Quaternion = new Quaternion();
		prevQuaternion.setFromAxisAngle( up, Math.PI / 2 );

		var point:Vector3 = new Vector3();
		var prevPoint:Vector3 = new Vector3();
		prevPoint.copy( curve.getPointAt( 0 ) );

		// shapes

		var step:Array<Vector3> = [
			new Vector3( - 0.225, 0, 0 ),
			new Vector3( 0, - 0.050, 0 ),
			new Vector3( 0, - 0.175, 0 ),

			new Vector3( 0, - 0.050, 0 ),
			new Vector3( 0.225, 0, 0 ),
			new Vector3( 0, - 0.175, 0 )
		];

		var PI2:Float = Math.PI * 2;

		var sides:Int = 5;
		var tube1:Array<Vector3> = [];

		for (i in 0...sides) {

			var angle:Float = (i / sides) * PI2;
			tube1.push( new Vector3( Math.sin( angle ) * 0.06, Math.cos( angle ) * 0.06, 0 ) );

		}

		sides = 6;
		var tube2:Array<Vector3> = [];

		for (i in 0...sides) {

			var angle:Float = (i / sides) * PI2;
			tube2.push( new Vector3( Math.sin( angle ) * 0.025, Math.cos( angle ) * 0.025, 0 ) );

		}

		var vector:Vector3 = new Vector3();
		var normal:Vector3 = new Vector3();

		function drawShape(shape:Array<Vector3>, color:Array<Float>) {

			normal.set( 0, 0, - 1 ).applyQuaternion( quaternion );

			for (j in 0...shape.length) {

				vector.copy( shape[j] ).applyQuaternion( quaternion );
				vector.add( point );

				vertices.push( vector.x, vector.y, vector.z );
				normals.push( normal.x, normal.y, normal.z );
				colors.push( color[0], color[1], color[2] );

			}

			normal.set( 0, 0, 1 ).applyQuaternion( quaternion );

			for (j in shape.length-1...0) {

				vector.copy( shape[j] ).applyQuaternion( quaternion );
				vector.add( point );

				vertices.push( vector.x, vector.y, vector.z );
				normals.push( normal.x, normal.y, normal.z );
				colors.push( color[0], color[1], color[2] );

			}

		}

		var vector1:Vector3 = new Vector3();
		var vector2:Vector3 = new Vector3();
		var vector3:Vector3 = new Vector3();
		var vector4:Vector3 = new Vector3();

		var normal1:Vector3 = new Vector3();
		var normal2:Vector3 = new Vector3();
		var normal3:Vector3 = new Vector3();
		var normal4:Vector3 = new Vector3();

		function extrudeShape(shape:Array<Vector3>, offset:Vector3, color:Array<Float>) {

			for (j in 0...shape.length) {

				var point1:Vector3 = shape[j];
				var point2:Vector3 = shape[(j + 1) % shape.length];

				vector1.copy( point1 ).add( offset );
				vector1.applyQuaternion( quaternion );
				vector1.add( point );

				vector2.copy( point2 ).add( offset );
				vector2.applyQuaternion( quaternion );
				vector2.add( point );

				vector3.copy( point2 ).add( offset );
				vector3.applyQuaternion( prevQuaternion );
				vector3.add( prevPoint );

				vector4.copy( point1 ).add( offset );
				vector4.applyQuaternion( prevQuaternion );
				vector4.add( prevPoint );

				vertices.push( vector1.x, vector1.y, vector1.z );
				vertices.push( vector2.x, vector2.y, vector2.z );
				vertices.push( vector4.x, vector4.y, vector4.z );

				vertices.push( vector2.x, vector2.y, vector2.z );
				vertices.push( vector3.x, vector3.y, vector3.z );
				vertices.push( vector4.x, vector4.y, vector4.z );

				//

				normal1.copy( point1 );
				normal1.applyQuaternion( quaternion );
				normal1.normalize();

				normal2.copy( point2 );
				normal2.applyQuaternion( quaternion );
				normal2.normalize();

				normal3.copy( point2 );
				normal3.applyQuaternion( prevQuaternion );
				normal3.normalize();

				normal4.copy( point1 );
				normal4.applyQuaternion( prevQuaternion );
				normal4.normalize();

				normals.push( normal1.x, normal1.y, normal1.z );
				normals.push( normal2.x, normal2.y, normal2.z );
				normals.push( normal4.x, normal4.y, normal4.z );

				normals.push( normal2.x, normal2.y, normal2.z );
				normals.push( normal3.x, normal3.y, normal3.z );
				normals.push( normal4.x, normal4.y, normal4.z );

				colors.push( color[0], color[1], color[2] );
				colors.push( color[0], color[1], color[2] );
				colors.push( color[0], color[1], color[2] );

				colors.push( color[0], color[1], color[2] );
				colors.push( color[0], color[1], color[2] );
				colors.push( color[0], color[1], color[2] );

			}

		}

		var offset:Vector3 = new Vector3();

		for (i in 1...divisions) {

			point.copy( curve.getPointAt(i / divisions) );

			up.set( 0, 1, 0 );

			forward.subVectors( point, prevPoint ).normalize();
			right.crossVectors( up, forward ).normalize();
			up.crossVectors( forward, right );

			var angle:Float = Math.atan2( forward.x, forward.z );

			quaternion.setFromAxisAngle( up, angle );

			if (i % 2 === 0) {

				drawShape( step, color2 );

			}

			extrudeShape( tube1, offset.set( 0, - 0.125, 0 ), color2 );
			extrudeShape( tube2, offset.set( 0.2, 0, 0 ), color1 );
			extrudeShape( tube2, offset.set( - 0.2, 0, 0 ), color1 );

			prevPoint.copy( point );
			prevQuaternion.copy( quaternion );

		}

		// console.log( vertices.length );

		this.setAttribute( 'position', new BufferAttribute( new Float32Array( vertices ), 3 ) );
		this.setAttribute( 'normal', new BufferAttribute( new Float32Array( normals ), 3 ) );
		this.setAttribute( 'color', new BufferAttribute( new Float32Array( colors ), 3 ) );

	}

}

// The rest of the classes are similar to the RollerCoasterGeometry class and can be converted in a similar way.