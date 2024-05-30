import three.js.examples.jsm.cameras.OrthographicCamera;
import three.js.examples.jsm.geometries.BufferGeometry;
import three.js.examples.jsm.geometries.attributes.Float32BufferAttribute;
import three.js.examples.jsm.objects.Mesh;

class Pass {

	public var isPass:Bool = true;
	public var enabled:Bool = true;
	public var needsSwap:Bool = true;
	public var clear:Bool = false;
	public var renderToScreen:Bool = false;

	public function new() {}

	public function setSize(width:Int, height:Int) {}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Dynamic, maskActive:Dynamic) {
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

	private var _mesh:Mesh;

	public function new(material:Dynamic) {
		this._mesh = new Mesh(new FullscreenTriangleGeometry(), material);
	}

	public function dispose() {
		this._mesh.geometry.dispose();
	}

	public function render(renderer:Dynamic) {
		renderer.render(this._mesh, new OrthographicCamera(-1, 1, 1, -1, 0, 1));
	}

	public function get material():Dynamic {
		return this._mesh.material;
	}

	public function set material(value:Dynamic) {
		this._mesh.material = value;
	}
}