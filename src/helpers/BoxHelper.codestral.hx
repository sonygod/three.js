import three.math.Box3;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;

class BoxHelper extends LineSegments {

    private var _box:Box3 = new Box3();

    public function new(object:Dynamic, color:Int = 0xffff00) {
        super(createGeometry(color), new LineBasicMaterial({ color: color, toneMapped: false }));

        this.object = object;
        this.type = 'BoxHelper';

        this.matrixAutoUpdate = false;

        this.update();
    }

    private function createGeometry(color:Int):BufferGeometry {
        var indices:Uint16Array = new Uint16Array([0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7]);
        var positions:Float32Array = new Float32Array(8 * 3);

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setIndex(new BufferAttribute(indices, 1));
        geometry.setAttribute('position', new BufferAttribute(positions, 3));

        return geometry;
    }

    public function update(object:Dynamic = null) {
        if (object != null) {
            trace('THREE.BoxHelper: .update() has no longer arguments.');
        }

        if (this.object != null) {
            _box.setFromObject(this.object);
        }

        if (_box.isEmpty()) return;

        var min = _box.min;
        var max = _box.max;

        var position = this.geometry.attributes.position;
        var array = position.array;

        array[0] = max.x; array[1] = max.y; array[2] = max.z;
        array[3] = min.x; array[4] = max.y; array[5] = max.z;
        array[6] = min.x; array[7] = min.y; array[8] = max.z;
        array[9] = max.x; array[10] = min.y; array[11] = max.z;
        array[12] = max.x; array[13] = max.y; array[14] = min.z;
        array[15] = min.x; array[16] = max.y; array[17] = min.z;
        array[18] = min.x; array[19] = min.y; array[20] = min.z;
        array[21] = max.x; array[22] = min.y; array[23] = min.z;

        position.needsUpdate = true;

        this.geometry.computeBoundingSphere();
    }

    public function setFromObject(object:Dynamic):BoxHelper {
        this.object = object;
        this.update();

        return this;
    }

    override function copy(source:Dynamic, recursive:Bool):BoxHelper {
        super.copy(source, recursive);

        this.object = source.object;

        return this;
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }
}