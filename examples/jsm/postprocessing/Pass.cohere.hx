import js.three.BufferGeometry;
import js.three.BufferAttribute;
import js.three.OrthographicCamera;
import js.three.Mesh;

class Pass {
    public var isPass:Bool = true;
    public var enabled:Bool = true;
    public var needsSwap:Bool = true;
    public var clear:Bool = false;
    public var renderToScreen:Bool = false;

    public function setSize() {
        // to be implemented by derived class
    }

    public function render() {
        trace('Pass: .render() must be implemented in derived pass.');
    }

    public function dispose() {
        // to be implemented by derived class
    }
}

class FullscreenTriangleGeometry extends BufferGeometry {
    public function new() {
        super();
        var position = [ -1., 3., 0., -1., -1., 0., 3., -1., 0. ];
        var uv = [ 0., 2., 0., 0., 2., 0. ];
        this.setAttribute('position', new Float32BufferAttribute(position, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uv, 2));
    }
}

class FullScreenQuad {
    private var _mesh:Mesh;

    public function new(material:Dynamic) {
        _mesh = new Mesh(new FullscreenTriangleGeometry(), material);
    }

    public function dispose() {
        _mesh.geometry.dispose();
    }

    public function render(renderer:Dynamic) {
        renderer.render(_mesh, OrthographicCamera.create(-1., 1., 1., -1., 0., 1.));
    }

    public function get_material():Dynamic {
        return _mesh.material;
    }

    public function set_material(value:Dynamic) {
        _mesh.material = value;
    }
}