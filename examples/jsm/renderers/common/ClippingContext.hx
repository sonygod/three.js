Here is the converted Haxe code:
```
package three.js.examples.javascript.renderers.common;

import three.Matrix3;
import three.Plane;
import three.Vector4;

class ClippingContext {
    private static var _clippingContextVersion:Int = 0;
    private static var _plane:Plane = new Plane();

    public var version:Int;
    public var globalClippingCount:Int;
    public var localClippingCount:Int;
    public var localClippingEnabled:Bool;
    public var localClipIntersection:Bool;
    public var planes:Array<Vector4>;
    public var parentVersion:Int;
    public var viewMatrix:Matrix3;
    public var viewNormalMatrix:Matrix3;

    public function new() {
        version = _clippingContextVersion++;
        globalClippingCount = 0;
        localClippingCount = 0;
        localClippingEnabled = false;
        localClipIntersection = false;
        planes = [];
        parentVersion = 0;
        viewNormalMatrix = new Matrix3();
    }

    public function projectPlanes(source:Array<Plane>, offset:Int) {
        var l:Int = source.length;
        var planes:Array<Vector4> = this.planes;

        for (i in 0...l) {
            _plane.copy(source[i]).applyMatrix4(this.viewMatrix, this.viewNormalMatrix);
            var v:Vector4 = planes[offset + i];
            var normal:Vector4 = _plane.normal;
            v.x = -normal.x;
            v.y = -normal.y;
            v.z = -normal.z;
            v.w = _plane.constant;
        }
    }

    public function updateGlobal(renderer:Dynamic, camera:Dynamic) {
        var rendererClippingPlanes:Array<Plane> = renderer.clippingPlanes;
        viewMatrix = camera.matrixWorldInverse;
        viewNormalMatrix.getNormalMatrix(viewMatrix);

        var update:Bool = false;

        if (rendererClippingPlanes != null && rendererClippingPlanes.length > 0) {
            var l:Int = rendererClippingPlanes.length;

            if (l != globalClippingCount) {
                planes = [];
                for (i in 0...l) {
                    planes.push(new Vector4());
                }
                globalClippingCount = l;
                update = true;
            }

            projectPlanes(rendererClippingPlanes, 0);
        } else if (globalClippingCount > 0) {
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

    public function update(parent:ClippingContext, material:Dynamic) {
        var update:Bool = false;

        if (this != parent && parent.version != parentVersion) {
            globalClippingCount = material.isShadowNodeMaterial ? 0 : parent.globalClippingCount;
            localClippingEnabled = parent.localClippingEnabled;
            planes = parent.planes.copy();
            parentVersion = parent.version;
            viewMatrix = parent.viewMatrix;
            viewNormalMatrix = parent.viewNormalMatrix;

            update = true;
        }

        if (localClippingEnabled) {
            var localClippingPlanes:Array<Plane> = material.clippingPlanes;

            if (localClippingPlanes != null && localClippingPlanes.length > 0) {
                var l:Int = localClippingPlanes.length;
                var offset:Int = globalClippingCount;

                if (update || l != localClippingCount) {
                    planes.length = offset + l;

                    for (i in 0...l) {
                        planes[offset + i] = new Vector4();
                    }

                    localClippingCount = l;
                    update = true;
                }

                projectPlanes(localClippingPlanes, offset);
            } else if (localClippingCount > 0) {
                localClippingCount = 0;
                update = true;
            }

            if (material.clipIntersection != localClipIntersection) {
                localClipIntersection = material.clipIntersection;
                update = true;
            }
        }

        if (update) version = _clippingContextVersion++;
    }
}
```
Note that I've kept the same naming conventions and formatting as the original JavaScript code. I've also assumed that the `three` library is already imported and available in the Haxe environment.