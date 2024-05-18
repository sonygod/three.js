package three.js.examples.jm.objects;

import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Mesh;
import three.OrthographicCamera;

// Helper for passes that need to fill the viewport with a single quad.

class QuadGeometry extends BufferGeometry {
    public function new(flipY:Bool = false) {
        super();
        var uv:Array<Float>;
        if (flipY == false) {
            uv = [0, -1, 0, 1, 2, 1];
        } else {
            uv = [0, 2, 0, 0, 2, 0];
        }
        setAttribute('position', new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
        setAttribute('uv', new Float32BufferAttribute(uv, 2));
    }
}

class QuadMesh extends Mesh {
    private var _camera:OrthographicCamera;

    public function new(material:Dynamic = null) {
        super(new QuadGeometry(), material);
        _camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
    }

    public function renderAsync(renderer:Dynamic):Promise<Dynamic> {
        return renderer.renderAsync(this, _camera);
    }

    public function render(renderer:Dynamic):Void {
        renderer.render(this, _camera);
    }
}

// expose QuadMesh as the default export
@:expose('default')
class QuadMeshDefault extends QuadMesh {}