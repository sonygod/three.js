import h3d.Matrix3;
import h3d.Plane;
import h3d.Vector4;

var _plane = new Plane();

var _clippingContextVersion = 0;

class ClippingContext {
    public var version:Int;
    public var globalClippingCount:Int;
    public var localClippingCount:Int;
    public var localClippingEnabled:Bool;
    public var localClipIntersection:Bool;
    public var planes:Array<Vector4>;
    public var parentVersion:Int;
    public var viewNormalMatrix:Matrix3;

    public function new() {
        version = ++_clippingContextVersion;
        globalClippingCount = 0;
        localClippingCount = 0;
        localClippingEnabled = false;
        localClipIntersection = false;
        planes = [];
        parentVersion = 0;
        viewNormalMatrix = new Matrix3();
    }

    public function projectPlanes(source:Array<Plane>, offset:Int) {
        var l = source.length;
        for (i in 0...l) {
            _plane.copy(source[i]).applyMatrix4(viewMatrix, viewNormalMatrix);
            var v = planes[offset + i];
            var normal = _plane.normal;
            v.x = -normal.x;
            v.y = -normal.y;
            v.z = -normal.z;
            v.w = _plane.constant;
        }
    }

    public function updateGlobal(renderer, camera) {
        var rendererClippingPlanes = renderer.clippingPlanes;
        viewMatrix = camera.matrixWorldInverse;
        viewNormalMatrix.getNormalMatrix(viewMatrix);
        var update = false;
        if (rendererClippingPlanes != null && rendererClippingPlanes.length != 0) {
            var l = rendererClippingPlanes.length;
            if (l != globalClippingCount) {
                var planes = [];
                for (i in 0...l) {
                    planes.push(new Vector4());
                }
                globalClippingCount = l;
                planes = planes;
                update = true;
            }
            projectPlanes(rendererClippingPlanes, 0);
        } else if (globalClippingCount != 0) {
            globalClippingCount = 0;
            planes = [];
            update = true;
        }
        if (renderer.localClippingEnabled != localClippingEnabled) {
            localClippingEnabled = renderer.localClippingEnabled;
            update = true;
        }
        if (update) {
            version = _clippingContextVersion++;
        }
    }

    public function update(parent:ClippingContext, material) {
        var update = false;
        if (this != parent && parent.version != parentVersion) {
            globalClippingCount = if (material.isShadowNodeMaterial) {
                0;
            } else {
                parent.globalClippingCount;
            }
            localClippingEnabled = parent.localClippingEnabled;
            planes = parent.planes.slice();
            parentVersion = parent.version;
            viewMatrix = parent.viewMatrix;
            viewNormalMatrix = parent.viewNormalMatrix;
            update = true;
        }
        if (localClippingEnabled) {
            var localClippingPlanes = material.clippingPlanes;
            if (localClippingPlanes != null && localClippingPlanes.length != 0) {
                var l = localClippingPlanes.length;
                var offset = globalClippingCount;
                if (update || l != localClippingCount) {
                    planes.length = offset + l;
                    for (i in 0...l) {
                        planes[offset + i] = new Vector4();
                    }
                    localClippingCount = l;
                    update = true;
                }
                projectPlanes(localClippingPlanes, offset);
            } else if (localClippingCount != 0) {
                localClippingCount = 0;
                update = true;
            }
            if (localClipIntersection != material.clipIntersection) {
                localClipIntersection = material.clipIntersection;
                update = true;
            }
        }
        if (update) {
            version = _clippingContextVersion++;
        }
    }
}

class h3d {
    public class Matrix3 {
        public function getNormalMatrix(m:Matrix3) {
            // implementation
        }
    }

    public class Plane {
        public var normal:Vector3;
        public var constant:Float;

        public function applyMatrix4(m:Matrix4, normalMatrix:Matrix3) {
            // implementation
        }
    }

    public class Vector3 {
        public var x:Float;
        public var y:Float;
        public var z:Float;
    }

    public class Vector4 {
        public var x:Float;
        public var y:Float;
        public var z:Float;
        public var w:Float;
    }
}