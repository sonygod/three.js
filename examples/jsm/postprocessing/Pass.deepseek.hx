import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.OrthographicCamera;
import three.Mesh;

class Pass {

	public var isPass:Bool;
	public var enabled:Bool;
	public var needsSwap:Bool;
	public var clear:Bool;
	public var renderToScreen:Bool;

	public function new() {

		this.isPass = true;
		this.enabled = true;
		this.needsSwap = true;
		this.clear = false;
		this.renderToScreen = false;

	}

	public function setSize(width:Float, height:Float) {}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Dynamic) {

		trace('THREE.Pass: .render() must be implemented in derived pass.');

	}

	public function dispose() {}

}

class FullscreenTriangleGeometry extends BufferGeometry {

	public function new() {

		super();

		this.setAttribute('position', new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
		this.setAttribute('uv', new Float32BufferAttribute([0, 2, 0, 0, 2, 0], 2));

	}

}

class FullScreenQuad {

	public var _mesh:Mesh;

	public function new(material:Dynamic) {

		this._mesh = new Mesh(_geometry, material);

	}

	public function dispose() {

		this._mesh.geometry.dispose();

	}

	public function render(renderer:Dynamic) {

		renderer.render(this._mesh, _camera);

	}

	public function get_material():Dynamic {

		return this._mesh.material;

	}

	public function set_material(value:Dynamic) {

		this._mesh.material = value;

	}

}

static var _camera:OrthographicCamera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
static var _geometry:FullscreenTriangleGeometry = new FullscreenTriangleGeometry();