package three.js.src.renderers.webgl;

import three.math.Matrix3;
import three.math.Plane;

class WebGLClipping {
    var properties:Dynamic;

    var globalState:Array<Float>;
    var numGlobalPlanes:Int;
    var localClippingEnabled:Bool;
    var renderingShadows:Bool;

    var plane:Plane;
    var viewNormalMatrix:Matrix3;

    var uniform:{
        value:Array<Float>,
        needsUpdate:Bool
    };

    public function new(properties:Dynamic) {
        this.properties = properties;

        globalState = null;
        numGlobalPlanes = 0;
        localClippingEnabled = false;
        renderingShadows = false;

        plane = new Plane();
        viewNormalMatrix = new Matrix3();

        uniform = { value: null, needsUpdate: false };

        this.uniform = uniform;
        this.numPlanes = 0;
        this.numIntersection = 0;
    }

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

            var dstArray:Array<Float> = materialProperties.clippingState || null;

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

    function resetGlobalState():Void {
        if (uniform.value != globalState) {
            uniform.value = globalState;
            uniform.needsUpdate = numGlobalPlanes > 0;
        }

        this.numPlanes = numGlobalPlanes;
        this.numIntersection = 0;
    }

    function projectPlanes(planes:Array<Plane>, camera:Dynamic, dstOffset:Int, ?skipTransform:Bool):Array<Float> {
        var nPlanes:Int = planes != null ? planes.length : 0;
        var dstArray:Array<Float> = null;

        if (nPlanes != 0) {
            dstArray = uniform.value;

            if (skipTransform != true || dstArray == null) {
                var flatSize:Int = dstOffset + nPlanes * 4;
                var viewMatrix:Matrix4 = camera.matrixWorldInverse;

                viewNormalMatrix.getNormalMatrix(viewMatrix);

                if (dstArray == null || dstArray.length < flatSize) {
                    dstArray = new Float32Array(flatSize);
                }

                for (i in 0...nPlanes) {
                    plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);

                    plane.normal.toArray(dstArray, i * 4);
                    dstArray[i * 4 + 3] = plane.constant;
                }

                uniform.value = dstArray;
                uniform.needsUpdate = true;
            }
        }

        this.numPlanes = nPlanes;
        this.numIntersection = 0;

        return dstArray;
    }
}