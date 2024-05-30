import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.Mesh;
import js.three.OrthographicCamera;

class QuadGeometry extends BufferGeometry {
    public function new(flipY:Bool = false) {
        super();
        var uv:Array<Float> = if (flipY) [0, 2, 0, 0, 2, 0] else [0, -1, 0, 1, 2, 1];
        setAttribute('position', new Float32BufferAttribute([-1, 3, 0, -1, -1, 0, 3, -1, 0], 3));
        setAttribute('uv', new Float32BufferAttribute(uv, 2));
    }
}

class QuadMesh extends Mesh {
    public var camera:OrthographicCamera;

    public function new(material:Dynamic = null) {
        super(new QuadGeometry(), material);
        camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
    }

    public function renderAsync(renderer:Dynamic):Dynamic {
        return renderer.renderAsync(this, camera);
    }

    public function render(renderer:Dynamic):Void {
        renderer.render(this, camera);
    }
}

class Main {
    static public function main() {
        var quadMesh = new QuadMesh();
        // Use quadMesh...
    }
}