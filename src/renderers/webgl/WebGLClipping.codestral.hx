import three.math.Matrix3;
import three.math.Plane;
import three.math.Vector3;

class WebGLClipping {
    private var globalState:Array<Float> = null;
    private var numGlobalPlanes:Int = 0;
    private var localClippingEnabled:Bool = false;
    private var renderingShadows:Bool = false;

    private var plane:Plane = new Plane();
    private var viewNormalMatrix:Matrix3 = new Matrix3();

    private var _uniform:Uniform = { value: null, needsUpdate: false };

    public function new(properties:Map<Any, Dynamic>) {}

    public function get uniform():Uniform {
        return _uniform;
    }

    public var numPlanes:Int = 0;
    public var numIntersection:Int = 0;

    public function init(planes:Array<Plane>, enableLocalClipping:Bool):Bool {
        var enabled:Bool = planes.length != 0 || enableLocalClipping || numGlobalPlanes != 0 || localClippingEnabled;
        localClippingEnabled = enableLocalClipping;
        numGlobalPlanes = planes.length;
        return enabled;
    }

    public function beginShadows():Void {
        renderingShadows = true;
        projectPlanes(null);
    }

    public function endShadows():Void {
        renderingShadows = false;
    }

    public function setGlobalState(planes:Array<Plane>, camera:Camera):Void {
        globalState = projectPlanes(planes, camera, 0);
    }

    public function setState(material:Material, camera:Camera, useCache:Bool):Void {
        var planes:Array<Plane> = material.clippingPlanes;
        var clipIntersection:Bool = material.clipIntersection;
        var clipShadows:Bool = material.clipShadows;

        if (!localClippingEnabled || planes == null || planes.length == 0 || renderingShadows && !clipShadows) {
            if (renderingShadows) {
                projectPlanes(null);
            } else {
                resetGlobalState();
            }
        } else {
            var nGlobal:Int = renderingShadows ? 0 : numGlobalPlanes;
            var lGlobal:Int = nGlobal * 4;

            var dstArray:Array<Float> = material.clippingState || null;
            _uniform.value = dstArray;

            dstArray = projectPlanes(planes, camera, lGlobal, useCache);

            for (var i:Int = 0; i != lGlobal; ++i) {
                dstArray[i] = globalState[i];
            }

            material.clippingState = dstArray;
            numIntersection = clipIntersection ? numPlanes : 0;
            numPlanes += nGlobal;
        }
    }

    private function resetGlobalState():Void {
        if (_uniform.value != globalState) {
            _uniform.value = globalState;
            _uniform.needsUpdate = numGlobalPlanes > 0;
        }
        numPlanes = numGlobalPlanes;
        numIntersection = 0;
    }

    private function projectPlanes(planes:Array<Plane>, camera:Camera, dstOffset:Int, skipTransform:Bool = false):Array<Float> {
        var nPlanes:Int = planes != null ? planes.length : 0;
        var dstArray:Array<Float> = null;

        if (nPlanes != 0) {
            dstArray = _uniform.value;

            if (skipTransform != true || dstArray == null) {
                var flatSize:Int = dstOffset + nPlanes * 4;
                var viewMatrix:Matrix4 = camera.matrixWorldInverse;

                viewNormalMatrix.getNormalMatrix(viewMatrix);

                if (dstArray == null || dstArray.length < flatSize) {
                    dstArray = new Array<Float>(flatSize);
                }

                for (var i:Int = 0, i4:Int = dstOffset; i != nPlanes; ++i, i4 += 4) {
                    plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);

                    var normal:Vector3 = plane.normal;
                    dstArray[i4] = normal.x;
                    dstArray[i4 + 1] = normal.y;
                    dstArray[i4 + 2] = normal.z;
                    dstArray[i4 + 3] = plane.constant;
                }
            }

            _uniform.value = dstArray;
            _uniform.needsUpdate = true;
        }

        numPlanes = nPlanes;
        numIntersection = 0;

        return dstArray;
    }
}