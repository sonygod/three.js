package three.js.examples.jsm.postprocessing;

import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.OrthographicCamera;
import three.Mesh;

class Pass {
	var isPass:Bool = true;

	public var enabled:Bool = true;
	public var needsSwap:Bool = true;
	public var clear:Bool = false;
	public var renderToScreen:Bool = false;

	public function new() {}

	public function setSize(width:Int, height:Int) {}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Bool) {
		trace("THREE.Pass: .render() must be implemented in derived pass.");
	}

	public function dispose() {}

}

class FullscreenTriangleGeometry extends BufferGeometry {
	public function new() {
		super();
		setAttribute("position", new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
		setAttribute("uv", new Float32BufferAttribute([0, 2, 0, 0, 2, 0], 2));
	}
}

var _camera:OrthographicCamera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
var _geometry:FullscreenTriangleGeometry = new FullscreenTriangleGeometry();

class FullScreenQuad {
	var _mesh:Mesh;

	public function new(material:Dynamic) {
		_mesh = new Mesh(_geometry, material);
	}

	public function dispose() {
		_geometry.dispose();
	}

	public function render(renderer:Dynamic) {
		renderer.render(_mesh, _camera);
	}

	public var material(get, set):Dynamic;

	function get_material():Dynamic {
		return _mesh.material;
	}

	function set_material(value:Dynamic):Void {
		_mesh.material = value;
	}
}

// Export classes
extern class Export {
	public static var Pass:Class<Pass>;
	public static var FullScreenQuad:Class<FullScreenQuad>;
}