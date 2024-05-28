package three.helpers;

import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.core.BufferGeometry;

class Box3Helper extends LineSegments {

    public var box:Box3;

    public function new(box:Box3, color:Int = 0xffff00) {
        var indices:Array<Int> = [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7];
        var positions:Array<Float> = [1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, 1, 1, -1, -1, 1, -1, -1, -1, -1, -1, -1, 1];

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setIndex(new BufferAttribute(new haxe.io.BytesBuffer(indices), 1));
        geometry.setAttribute('position', new Float32BufferAttribute(new haxe.io.BytesBuffer(positions), 3));

        super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

        this.box = box;
        this.type = 'Box3Helper';
        geometry.computeBoundingSphere();
    }

    override public function updateMatrixWorld(force:Bool) {
        var box:Box3 = this.box;
        if (box.isEmpty()) return;
        box.getCenter(position);
        box.getSize(scale);
        scale.multiplyScalar(0.5);
        super.updateMatrixWorld(force);
    }

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }
}