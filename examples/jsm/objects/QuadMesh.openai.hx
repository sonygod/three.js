package three.js.examples.jsm.objects;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.js.Mesh;
import three.js.OrthographicCamera;

class QuadGeometry extends BufferGeometry {
    public function new(flipY:Bool = false) {
        super();
        var uv:Array<Float> = flipY ? [0, 2, 0, 0, 2, 0] : [0, -1, 0, 1, 2, 1];
        this.setAttribute("position", new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
        this.setAttribute("uv", new Float32BufferAttribute(uv, 2));
    }
}

class QuadMesh extends Mesh {
    public var camera:OrthographicCamera;

    public function new(material:Dynamic = null) {
        super(new QuadGeometry(), material);
        this.camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
    }

    public function renderAsync(renderer:Dynamic) {
        return renderer.renderAsync(this, camera);
    }

    public function render(renderer:Dynamic) {
        renderer.render(this, camera);
    }
}

@:keep
var _geometry:QuadGeometry = new QuadGeometry();
var _camera:OrthographicCamera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);