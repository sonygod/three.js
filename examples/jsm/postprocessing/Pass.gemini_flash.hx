import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.cameras.OrthographicCamera;
import three.objects.Mesh;

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

	public function setSize(?width:Int, ?height:Int):Void {
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Bool):Void {
		trace("THREE.Pass: .render() must be implemented in derived pass.");
	}

	public function dispose():Void {
	}
}

// Helper for passes that need to fill the viewport with a single quad.

var _camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);

// https://github.com/mrdoob/three.js/pull/21358

class FullscreenTriangleGeometry extends BufferGeometry {

	public function new() {
		super();
		this.setAttribute("position", new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
		this.setAttribute("uv", new Float32BufferAttribute([0, 2, 0, 0, 2, 0], 2));
	}
}

var _geometry = new FullscreenTriangleGeometry();

class FullScreenQuad {

	private var _mesh:Mesh;

	public function new(material:Dynamic) {
		this._mesh = new Mesh(_geometry, material);
	}

	public function dispose():Void {
		this._mesh.geometry.dispose();
	}

	public function render(renderer:Dynamic):Void {
		renderer.render(this._mesh, _camera);
	}

	public function get material():Dynamic {
		return this._mesh.material;
	}

	public function set material(value:Dynamic):Void {
		this._mesh.material = value;
	}
}

class Main {
	static function main() {
		var pass = new Pass();
		var quad = new FullScreenQuad(null);
	}
}