import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Mesh;
import three.OrthographicCamera;

class QuadGeometry extends BufferGeometry {

	public function new(flipY:Bool = false) {
		super();

		var uv = if (flipY) [0, 2, 0, 0, 2, 0] else [0, -1, 0, 1, 2, 1];

		this.setAttribute('position', new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
		this.setAttribute('uv', new Float32BufferAttribute(uv, 2));
	}
}

class QuadMesh extends Mesh {

	public var camera:OrthographicCamera;

	public function new(material:Dynamic = null) {
		super(_geometry, material);
		this.camera = _camera;
	}

	public function renderAsync(renderer:Dynamic):Dynamic {
		return renderer.renderAsync(this, _camera);
	}

	public function render(renderer:Dynamic):Void {
		renderer.render(this, _camera);
	}
}

static var _camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
static var _geometry = new QuadGeometry();

@:keep var QuadMesh = QuadMesh;