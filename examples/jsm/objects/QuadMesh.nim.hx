import three.js.examples.jsm.objects.QuadGeometry;
import three.js.examples.jsm.objects.QuadMesh;
import three.js.examples.jsm.cameras.OrthographicCamera;
import three.js.examples.jsm.geometries.BufferGeometry;
import three.js.examples.jsm.attributes.Float32BufferAttribute;
import three.js.examples.jsm.core.Mesh;
import three.js.examples.jsm.renderers.WebGLRenderer;

// Helper for passes that need to fill the viewport with a single quad.

var _camera:OrthographicCamera = new OrthographicCamera( -1, 1, 1, -1, 0, 1 );

// https://github.com/mrdoob/three.js/pull/21358

class QuadGeometry extends BufferGeometry {

	public function new( flipY:Bool = false ) {

		super();

		var uv:Array<Float> = flipY === false ? [ 0, -1, 0, 1, 2, 1 ] : [ 0, 2, 0, 0, 2, 0 ];

		this.setAttribute( 'position', new Float32BufferAttribute( [ -1, 3, 0, -1, -1, 0, 3, -1, 0 ], 3 ) );
		this.setAttribute( 'uv', new Float32BufferAttribute( uv, 2 ) );

	}

}

var _geometry:QuadGeometry = new QuadGeometry();

class QuadMesh extends Mesh {

	public function new( material:Dynamic = null ) {

		super( _geometry, material );

		this.camera = _camera;

	}

	public function renderAsync( renderer:WebGLRenderer ):Future<Void> {

		return renderer.renderAsync( this, _camera );

	}

	public function render( renderer:WebGLRenderer ) {

		renderer.render( this, _camera );

	}

}

export default QuadMesh;