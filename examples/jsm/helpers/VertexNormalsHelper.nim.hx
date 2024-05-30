import three.js.extras.core.BufferGeometry;
import three.js.extras.core.Float32BufferAttribute;
import three.js.extras.objects.LineSegments;
import three.js.extras.materials.LineBasicMaterial;
import three.js.extras.math.Matrix3;
import three.js.extras.math.Vector3;

class VertexNormalsHelper extends LineSegments {

	public var object:Dynamic;
	public var size:Float;
	public var type:String;

	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _normalMatrix:Matrix3;

	public function new( object:Dynamic, size:Float = 1, color:Int = 0xff0000 ) {

		this._v1 = new Vector3();
		this._v2 = new Vector3();
		this._normalMatrix = new Matrix3();

		var geometry:BufferGeometry = new BufferGeometry();

		var nNormals:Int = untyped object.geometry.attributes.normal.count;
		var positions:Float32BufferAttribute = new Float32BufferAttribute( nNormals * 2 * 3, 3 );

		geometry.setAttribute( 'position', positions );

		super( geometry, new LineBasicMaterial( { color: color, toneMapped: false } ) );

		this.object = object;
		this.size = size;
		this.type = 'VertexNormalsHelper';

		//

		this.matrixAutoUpdate = false;

		this.update();

	}

	public function update() {

		untyped object.updateMatrixWorld( true );

		this._normalMatrix.getNormalMatrix( this.object.matrixWorld );

		var matrixWorld:Dynamic = this.object.matrixWorld;

		var position:Float32BufferAttribute = this.geometry.attributes.position;

		//

		var objGeometry:Dynamic = this.object.geometry;

		if ( objGeometry ) {

			var objPos:Float32BufferAttribute = objGeometry.attributes.position;

			var objNorm:Float32BufferAttribute = objGeometry.attributes.normal;

			var idx:Int = 0;

			// for simplicity, ignore index and drawcalls, and render every normal

			for ( j in 0...objPos.count ) {

				this._v1.fromBufferAttribute( objPos, j ).applyMatrix4( matrixWorld );

				this._v2.fromBufferAttribute( objNorm, j );

				this._v2.applyMatrix3( this._normalMatrix ).normalize().multiplyScalar( this.size ).add( this._v1 );

				position.setXYZ( idx, this._v1.x, this._v1.y, this._v1.z );

				idx = idx + 1;

				position.setXYZ( idx, this._v2.x, this._v2.y, this._v2.z );

				idx = idx + 1;

			}

		}

		position.needsUpdate = true;

	}

	public function dispose() {

		this.geometry.dispose();
		this.material.dispose();

	}

}