import three.math.Matrix3;
import three.math.Plane;

class WebGLClipping {

    var scope:WebGLClipping;

    var globalState:Array<Float> = null;
    var numGlobalPlanes:Int = 0;
    var localClippingEnabled:Bool = false;
    var renderingShadows:Bool = false;

    var plane:Plane = new Plane();
    var viewNormalMatrix:Matrix3 = new Matrix3();

    var uniform:{ value:Array<Float>, needsUpdate:Bool } = { value: null, needsUpdate: false };

    public var numPlanes:Int = 0;
    public var numIntersection:Int = 0;

    public function new(properties:Dynamic) {
        scope = this;
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

        var materialProperties = properties.get(material);

        if (!localClippingEnabled || planes == null || planes.length == 0 || (renderingShadows && !clipShadows)) {
            if (renderingShadows) {
                projectPlanes(null);
            } else {
                resetGlobalState();
            }
        } else {
            var nGlobal:Int = renderingShadows ? 0 : numGlobalPlanes;
            var lGlobal:Int = nGlobal * 4;

            var dstArray:Array<Float> = materialProperties.clippingState != null ? materialProperties.clippingState : null;

            uniform.value = dstArray;
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

        scope.numPlanes = numGlobalPlanes;
        scope.numIntersection = 0;
    }

    function projectPlanes(planes:Array<Plane>, camera:Dynamic, ?dstOffset:Int, ?skipTransform:Bool):Array<Float> {
        var nPlanes:Int = planes != null ? planes.length : 0;
        var dstArray:Array<Float> = null;

        if (nPlanes != 0) {
            dstArray = uniform.value;

            if (skipTransform != true || dstArray == null) {
                var flatSize:Int = dstOffset + nPlanes * 4;
                var viewMatrix = camera.matrixWorldInverse;

                viewNormalMatrix.getNormalMatrix(viewMatrix);

                if (dstArray == null || dstArray.length < flatSize) {
                    dstArray = new Array<Float>(flatSize);
                }

                for (i in 0...nPlanes) {
                    var i4:Int = dstOffset + i * 4;
                    plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);
                    plane.normal.toArray(dstArray, i4);
                    dstArray[i4 + 3] = plane.constant;
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