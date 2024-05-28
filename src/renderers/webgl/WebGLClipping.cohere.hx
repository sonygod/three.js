import js.Browser.window;
import js.WebGL.WebGLRenderingContext;
import js.WebGL.WebGLProgram;
import js.WebGL.WebGLShader;
import js.WebGL.WebGLUniformLocation;

class WebGLClipping {
    public var globalState:Array<Float>;
    public var numGlobalPlanes:Int;
    public var localClippingEnabled:Bool;
    public var renderingShadows:Bool;
    public var plane:js.math.Plane;
    public var viewNormalMatrix:js.math.Matrix3;
    public var uniform: { value: Array<Float>, needsUpdate: Bool };
    public var numPlanes:Int;
    public var numIntersection:Int;

    public function new() {
        globalState = null;
        numGlobalPlanes = 0;
        localClippingEnabled = false;
        renderingShadows = false;
        plane = js.math.Plane_Impl_.create();
        viewNormalMatrix = js.math.Matrix3_Impl_.create();
        uniform = { value: null, needsUpdate: false };
        numPlanes = 0;
        numIntersection = 0;
    }

    public function init(planes:Array<js.math.Plane>, enableLocalClipping:Bool):Bool {
        var enabled = planes.length != 0 || enableLocalClipping || numGlobalPlanes != 0 || localClippingEnabled;
        localClippingEnabled = enableLocalClipping;
        numGlobalPlanes = planes.length;
        return enabled;
    }

    public function beginShadows() {
        renderingShadows = true;
        projectPlanes(null);
    }

    public function endShadows() {
        renderingShadows = false;
    }

    public function setGlobalState(planes:Array<js.math.Plane>, camera:Dynamic) {
        globalState = projectPlanes(planes, camera, 0);
    }

    public function setState(material:Dynamic, camera:Dynamic, useCache:Bool) {
        var planes = material.clippingPlanes;
        var clipIntersection = material.clipIntersection;
        var clipShadows = material.clipShadows;
        var materialProperties = properties.get(material);
        if (!localClippingEnabled || planes == null || planes.length == 0 || (renderingShadows && !clipShadows)) {
            if (renderingShadows) {
                projectPlanes(null);
            } else {
                resetGlobalState();
            }
        } else {
            var nGlobal = renderingShadows ? 0 : numGlobalPlanes;
            var lGlobal = nGlobal * 4;
            var dstArray = materialProperties.clippingState != null ? materialProperties.clippingState : null;
            uniform.value = dstArray;
            dstArray = projectPlanes(planes, camera, lGlobal, useCache);
            var i4 = 0;
            for (i in 0...nGlobal) {
                dstArray[i4] = globalState[i4];
                dstArray[i4 + 1] = globalState[i4 + 1];
                dstArray[i4 + 2] = globalState[i4 + 2];
                dstArray[i4 + 3] = globalState[i4 + 3];
                i4 += 4;
            }
            materialProperties.clippingState = dstArray;
            numIntersection = if (clipIntersection) numPlanes else 0;
            numPlanes += nGlobal;
        }
    }

    function resetGlobalState() {
        if (uniform.value != globalState) {
            uniform.value = globalState;
            uniform.needsUpdate = numGlobalPlanes > 0;
        }
        numPlanes = numGlobalPlanes;
        numIntersection = 0;
    }

    function projectPlanes(planes:Array<js.math.Plane>, camera:Dynamic, dstOffset:Int, skipTransform:Bool):Array<Float> {
        var nPlanes = if (planes != null) planes.length else 0;
        var dstArray:Array<Float>;
        if (nPlanes != 0) {
            dstArray = uniform.value;
            if (skipTransform != true || dstArray == null) {
                var flatSize = dstOffset + nPlanes * 4;
                var viewMatrix = camera.matrixWorldInverse;
                viewNormalMatrix.getNormalMatrix(viewMatrix);
                if (dstArray == null || dstArray.length < flatSize) {
                    dstArray = new Float32Array(flatSize);
                }
                var i4 = dstOffset;
                for (i in 0...nPlanes) {
                    plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);
                    dstArray[i4] = plane.normal.x;
                    dstArray[i4 + 1] = plane.normal.y;
                    dstArray[i4 + 2] = plane.normal.z;
                    dstArray[i4 + 3] = plane.constant;
                    i4 += 4;
                }
            }
            uniform.value = dstArray;
            uniform.needsUpdate = true;
        }
        numPlanes = nPlanes;
        numIntersection = 0;
        return dstArray;
    }
}