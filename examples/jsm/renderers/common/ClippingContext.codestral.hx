import three.math.Matrix3;
import three.math.Plane;
import three.math.Vector4;

class ClippingContext {
    var _plane:Plane = new Plane();
    static var _clippingContextVersion:Int = 0;

    public var version:Int;
    public var globalClippingCount:Int;
    public var localClippingCount:Int;
    public var localClippingEnabled:Bool;
    public var localClipIntersection:Bool;
    public var planes:Array<Vector4>;
    public var parentVersion:Int;
    public var viewNormalMatrix:Matrix3;
    public var viewMatrix:Matrix3;

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

    public function projectPlanes(source:Array<Plane>, offset:Int):Void {
        var l:Int = source.length;
        for (i in 0...l) {
            _plane.copy(source[i]).applyMatrix4(viewMatrix, viewNormalMatrix);
            var v:Vector4 = planes[offset + i];
            var normal:Vector3 = _plane.normal;
            v.x = -normal.x;
            v.y = -normal.y;
            v.z = -normal.z;
            v.w = _plane.constant;
        }
    }

    public function updateGlobal(renderer:Renderer, camera:Camera):Void {
        var rendererClippingPlanes:Array<Plane> = renderer.clippingPlanes;
        viewMatrix = camera.matrixWorldInverse;
        viewNormalMatrix.getNormalMatrix(viewMatrix);
        var update:Bool = false;

        if (rendererClippingPlanes != null && rendererClippingPlanes.length != 0) {
            var l:Int = rendererClippingPlanes.length;
            if (l != globalClippingCount) {
                var planes:Array<Vector4> = [];
                for (i in 0...l) {
                    planes.push(new Vector4());
                }
                globalClippingCount = l;
                this.planes = planes;
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

        if (update) version = _clippingContextVersion++;
    }

    public function update(parent:ClippingContext, material:Material):Void {
        var update:Bool = false;
        if (this != parent && parent.version != parentVersion) {
            globalClippingCount = material.isShadowNodeMaterial ? 0 : parent.globalClippingCount;
            localClippingEnabled = parent.localClippingEnabled;
            planes = parent.planes.slice();
            parentVersion = parent.version;
            viewMatrix = parent.viewMatrix;
            viewNormalMatrix = parent.viewNormalMatrix;
            update = true;
        }

        if (localClippingEnabled) {
            var localClippingPlanes:Array<Plane> = material.clippingPlanes;
            if (localClippingPlanes != null && localClippingPlanes.length != 0) {
                var l:Int = localClippingPlanes.length;
                var offset:Int = globalClippingCount;
                if (update || l != localClippingCount) {
                    while (planes.length < offset + l) planes.push(new Vector4());
                    planes.length = offset + l;
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

        if (update) version = _clippingContextVersion++;
    }
}