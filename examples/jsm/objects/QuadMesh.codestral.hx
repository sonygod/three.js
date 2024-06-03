import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Mesh;
import three.OrthographicCamera;

class QuadGeometry extends BufferGeometry {
    public function new(flipY:Bool = false) {
        super();

        var uv = flipY === false ? [0, -1, 0, 1, 2, 1] : [0, 2, 0, 0, 2, 0];

        this.setAttribute('position', new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
        this.setAttribute('uv', new Float32BufferAttribute(uv, 2));
    }
}

class QuadMesh extends Mesh {
    private var _camera:OrthographicCamera;
    private var _geometry:QuadGeometry;

    public function new(material:three.Material = null) {
        _camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
        _geometry = new QuadGeometry();

        super(_geometry, material);

        this.camera = _camera;
    }

    public function renderAsync(renderer:three.WebGLRenderer):Promise<void> {
        return renderer.renderAsync(this, _camera);
    }

    public function render(renderer:three.WebGLRenderer):void {
        renderer.render(this, _camera);
    }
}

export default QuadMesh;