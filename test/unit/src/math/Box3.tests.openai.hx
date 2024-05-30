package three.math;

import three.math.Matrix4;
import three.math.Sphere;
import three.math.Triangle;
import three.math.Vector3;
import three.objects.Mesh;
import three.utils.BufferAttribute;
import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;

class Box3 {
    public var min:Vector3;
    public var max:Vector3;

    public function new(?min:Vector3, ?max:Vector3) {
        if (min == null) min = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        if (max == null) max = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
        this.min = min;
        this.max = max;
    }

    // ...
}