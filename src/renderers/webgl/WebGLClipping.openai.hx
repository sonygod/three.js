package three.js.src.renderers.webgl;

import three.math.Matrix3;
import three.math.Plane;

class WebGLClipping {

    private var scope:WebGLClipping;
    private var globalState:Float32Array;
    private var numGlobalPlanes:Int;
    private var localClippingEnabled:Bool;
    private var renderingShadows:Bool;
    private var plane:Plane;
    private var viewNormalMatrix:Matrix3;
    private var uniform:{value:Float32Array, needsUpdate:Bool};

    public function new(properties:Dynamic) {
        scope = this;
        globalState = null;
        numGlobalPlanes = 0;
        localClippingEnabled = false;
        renderingShadows = false;
        plane = new Plane();
        viewNormalMatrix = new Matrix3();
        uniform = {value: null, needsUpdate: false};
        this.uniform = uniform;
        this.numPlanes = 0;
        this.numIntersection = 0;
    }

    public function init(planes:Array<Plane>, enableLocalClipping:Bool):Bool {
        var enabled = planes.length != 0 || enableLocalClipping || numGlobalPlanes != 0 || localClippingEnabled;
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

    public function setGlobalState(planes:Array<Plane>, camera:Dynamic):Void {
        globalState = projectPlanes(planes, camera, 0);
    }

    public function setState(material:Dynamic, camera:Dynamic, useCache:Bool):Void {
        var planes:Array<Plane> = material.clippingPlanes;
        var clipIntersection:Bool = material.clipIntersection;
        var clipShadows:Bool = material.clipShadows;
        var materialProperties:Dynamic = properties.get(material);
        if (!localClippingEnabled || planes == null || planes.length == 0 || renderingShadows && !clipShadows) {
            if (renderingShadows) {
                projectPlanes(null);
            } else {
                resetGlobalState();
            }
        } else {
            var nGlobal:Int = renderingShadows ? 0 : numGlobalPlanes;
            var lGlobal:Int = nGlobal * 4;
            var dstArray:Float32Array = materialProperties.clippingState || null;
            uniform.value = dstArray; // ensure unique state
            dstArray = projectPlanes(planes, camera, lGlobal, useCache);
            for (i in 0...lGlobal) {
                dstArray[i] = globalState[i];
            }
            materialProperties.clippingState = dstArray;
            this.numIntersection = clipIntersection ? this.numPlanes : 0;
            this.numPlanes += nGlobal;
        }
    }

    private function resetGlobalState():Void {
        if (uniform.value != globalState) {
            uniform.value = globalState;
            uniform.needsUpdate = numGlobalPlanes > 0;
        }
        scope.numPlanes = numGlobalPlanes;
        scope.numIntersection = 0;
    }

    private function projectPlanes(planes:Array<Plane>, camera:Dynamic, dstOffset:Int, skipTransform:Bool):Float32Array {
        var nPlanes:Int = planes != null ? planes.length : 0;
        var dstArray:Float32Array = null;
        if (nPlanes != 0) {
            dstArray = uniform.value;
            if (skipTransform != true || dstArray == null) {
                var flatSize:Int = dstOffset + nPlanes * 4;
                var viewMatrix:Matrix3 = camera.matrixWorldInverse;
                viewNormalMatrix.getNormalMatrix(viewMatrix);
                if (dstArray == null || dstArray.length < flatSize) {
                    dstArray = new Float32Array(flatSize);
                }
                for (i in 0...nPlanes) {
                    plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);
                    plane.normal.toArray(dstArray, i * 4);
                    dstArray[i * 4 + 3] = plane.constant;
                }
            }
            uniform.value = dstArray;
            uniform.needsUpdate = true;
        }
        scope.numPlanes = nPlanes;
        scope.numIntersection = 0;
        return dstArray;
    }

}