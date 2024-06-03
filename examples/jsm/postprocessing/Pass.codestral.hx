import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.OrthographicCamera;
import three.Mesh;
import three.Renderer;

class Pass {
    public var isPass:Bool = true;
    public var enabled:Bool = true;
    public var needsSwap:Bool = true;
    public var clear:Bool = false;
    public var renderToScreen:Bool = false;

    public function new() {
    }

    public function setSize(width:Int, height:Int) {
    }

    public function render(renderer:Renderer, writeBuffer:three.WebGLRenderTarget, readBuffer:three.WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {
        trace("THREE.Pass: .render() must be implemented in derived pass.");
    }

    public function dispose() {
    }
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
    private static var _geometry:FullscreenTriangleGeometry = new FullscreenTriangleGeometry();
    private static var _camera:OrthographicCamera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);

    public function new(material:three.Material) {
        this._mesh = new Mesh(FullScreenQuad._geometry, material);
    }

    public function dispose() {
        this._mesh.geometry.dispose();
    }

    public function render(renderer:Renderer) {
        renderer.render(this._mesh, FullScreenQuad._camera);
    }

    public function get_material():three.Material {
        return this._mesh.material;
    }

    public function set_material(value:three.Material) {
        this._mesh.material = value;
    }
}