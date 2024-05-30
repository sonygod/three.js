import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.DynamicDrawUsage;
import three.Matrix4;
import three.Mesh;
import three.MeshStandardMaterial;
import three.Vector3;

class TubePainter {

	static var BUFFER_SIZE:Int = 1000000 * 3;

	var positions:BufferAttribute = new BufferAttribute( new Float32Array( BUFFER_SIZE ), 3 );
	positions.usage = DynamicDrawUsage.DynamicDraw;

	var normals:BufferAttribute = new BufferAttribute( new Float32Array( BUFFER_SIZE ), 3 );
	normals.usage = DynamicDrawUsage.DynamicDraw;

	var colors:BufferAttribute = new BufferAttribute( new Float32Array( BUFFER_SIZE ), 3 );
	colors.usage = DynamicDrawUsage.DynamicDraw;

	var geometry:BufferGeometry = new BufferGeometry();
	geometry.setAttribute( 'position', positions );
	geometry.setAttribute( 'normal', normals );
	geometry.setAttribute( 'color', colors );
	geometry.drawRange.count = 0;

	var material:MeshStandardMaterial = new MeshStandardMaterial( {
		vertexColors: true
	} );

	var mesh:Mesh = new Mesh( geometry, material );
	mesh.frustumCulled = false;

	//

	static function getPoints( size:Float ) {

		var PI2:Float = Math.PI * 2;

		var sides:Int = 10;
		var array:Array<Vector3> = [];
		var radius:Float = 0.01 * size;

		for ( i in 0...sides ) {

			var angle:Float = ( i / sides ) * PI2;
			array.push( new Vector3( Math.sin( angle ) * radius, Math.cos( angle ) * radius, 0 ) );

		}

		return array;

	}

	//

	var vector1:Vector3 = new Vector3();
	var vector2:Vector3 = new Vector3();
	var vector3:Vector3 = new Vector3();
	var vector4:Vector3 = new Vector3();

	var color:Color = new Color( 0xffffff );
	var size:Float = 1;

	function stroke( position1:Vector3, position2:Vector3, matrix1:Matrix4, matrix2:Matrix4 ) {

		if ( position1.distanceToSquared( position2 ) === 0 ) return;

		var count:Int = geometry.drawRange.count;

		var points:Array<Vector3> = getPoints( size );

		for ( i in 0...points.length ) {

			var vertex1:Vector3 = points[ i ];
			var vertex2:Vector3 = points[ ( i + 1 ) % points.length ];

			// positions

			vector1.copy( vertex1 ).applyMatrix4( matrix2 ).add( position2 );
			vector2.copy( vertex2 ).applyMatrix4( matrix2 ).add( position2 );
			vector3.copy( vertex2 ).applyMatrix4( matrix1 ).add( position1 );
			vector4.copy( vertex1 ).applyMatrix4( matrix1 ).add( position1 );

			vector1.toArray( positions.array, ( count + 0 ) * 3 );
			vector2.toArray( positions.array, ( count + 1 ) * 3 );
			vector4.toArray( positions.array, ( count + 2 ) * 3 );

			vector2.toArray( positions.array, ( count + 3 ) * 3 );
			vector3.toArray( positions.array, ( count + 4 ) * 3 );
			vector4.toArray( positions.array, ( count + 5 ) * 3 );

			// normals

			vector1.copy( vertex1 ).applyMatrix4( matrix2 ).normalize();
			vector2.copy( vertex2 ).applyMatrix4( matrix2 ).normalize();
			vector3.copy( vertex2 ).applyMatrix4( matrix1 ).normalize();
			vector4.copy( vertex1 ).applyMatrix4( matrix1 ).normalize();

			vector1.toArray( normals.array, ( count + 0 ) * 3 );
			vector2.toArray( normals.array, ( count + 1 ) * 3 );
			vector4.toArray( normals.array, ( count + 2 ) * 3 );

			vector2.toArray( normals.array, ( count + 3 ) * 3 );
			vector3.toArray( normals.array, ( count + 4 ) * 3 );
			vector4.toArray( normals.array, ( count + 5 ) * 3 );

			// colors

			color.toArray( colors.array, ( count + 0 ) * 3 );
			color.toArray( colors.array, ( count + 1 ) * 3 );
			color.toArray( colors.array, ( count + 2 ) * 3 );

			color.toArray( colors.array, ( count + 3 ) * 3 );
			color.toArray( colors.array, ( count + 4 ) * 3 );
			color.toArray( colors.array, ( count + 5 ) * 3 );

			count += 6;

		}

		geometry.drawRange.count = count;

	}

	//

	var up:Vector3 = new Vector3( 0, 1, 0 );

	var point1:Vector3 = new Vector3();
	var point2:Vector3 = new Vector3();

	var matrix1:Matrix4 = new Matrix4();
	var matrix2:Matrix4 = new Matrix4();

	function moveTo( position:Vector3 ) {

		point1.copy( position );
		matrix1.lookAt( point2, point1, up );

		point2.copy( position );
		matrix2.copy( matrix1 );

	}

	function lineTo( position:Vector3 ) {

		point1.copy( position );
		matrix1.lookAt( point2, point1, up );

		stroke( point1, point2, matrix1, matrix2 );

		point2.copy( point1 );
		matrix2.copy( matrix1 );

	}

	function setSize( value:Float ) {

		size = value;

	}

	//

	var count:Int = 0;

	function update() {

		var start:Int = count;
		var end:Int = geometry.drawRange.count;

		if ( start === end ) return;

		positions.addUpdateRange( start * 3, ( end - start ) * 3 );
		positions.needsUpdate = true;

		normals.addUpdateRange( start * 3, ( end - start ) * 3 );
		normals.needsUpdate = true;

		colors.addUpdateRange( start * 3, ( end - start ) * 3 );
		colors.needsUpdate = true;

		count = geometry.drawRange.count;

	}

	public function new() {

	}

}