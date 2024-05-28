package three.helpers;

import three.math.Box3;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;

class BoxHelper extends LineSegments {
    
    var object:Dynamic;
    var type:String;

    var _box:Box3 = new Box3();

    public function new(object:Dynamic, color:Int = 0xffff00) {
        var indices:Array<Int> = [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7];
        var positions:Array<Float> = new Array<Float>(8 * 3);

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setIndex(new BufferAttribute(new Uint16Array(indices), 1));
        geometry.setAttribute('position', new BufferAttribute(new Float32Array(positions), 3));

        super(geometry, new LineBasicMaterial({ color: color, toneMapped: false }));

        this.object = object;
        this.type = 'BoxHelper';

        this.matrixAutoUpdate = false;

        this.update();
    }

    public function update(?object:Dynamic) {
        if (object != null) {
            trace('THREE.BoxHelper: .update() has no longer arguments.');
        }

        if (this.object != null) {
            _box.setFromObject(this.object);
        }

        if (_box.isEmpty()) return;

        var min:Array<Float> = _box.min;
        var max:Array<Float> = _box.max;

        var position:BufferAttribute = this.geometry.attributes.position;
        var array:Array<Float> = position.array;

        array[0] = max[0]; array[1] = max[1]; array[2] = max[2];
        array[3] = min[0]; array[4] = max[1]; array[5] = max[2];
        array[6] = min[0]; array[7] = min[1]; array[8] = max[2];
        array[9] = max[0]; array[10] = min[1]; array[11] = max[2];
        array[12] = max[0]; array[13] = max[1]; array[14] = min[2];
        array[15] = min[0]; array[16] = max[1]; array[17] = min[2];
        array[18] = min[0]; array[19] = min[1]; array[20] = min[2];
        array[21] = max[0]; array[22] = min[1]; array[23] = min[2];

        position.needsUpdate = true;

        this.geometry.computeBoundingSphere();
    }

    public function setFromObject(object:Dynamic) {
        this.object = object;
        this.update();
        return this;
    }

    public function copy(source:BoxHelper, recursive:Bool) {
        super.copy(source, recursive);
        this.object = source.object;
        return this;
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }
}