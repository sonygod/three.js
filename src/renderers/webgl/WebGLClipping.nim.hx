import three.math.Matrix3;
import three.math.Plane;

class WebGLClipping {
    var globalState:Null<Float32Array>;
    var numGlobalPlanes:Int;
    var localClippingEnabled:Bool;
    var renderingShadows:Bool;

    var plane:Plane;
    var viewNormalMatrix:Matrix3;
    var uniform:Uniform;
    var numPlanes:Int;
    var numIntersection:Int;

    public function new(properties:Properties) {
        var scope = this;

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

        this.init = function(planes, enableLocalClipping) {
            var enabled =
                planes.length !== 0 ||
                enableLocalClipping ||
                // enable state of previous frame - the clipping code has to
                // run another frame in order to reset the state:
                numGlobalPlanes !== 0 ||
                localClippingEnabled;

            localClippingEnabled = enableLocalClipping;

            numGlobalPlanes = planes.length;

            return enabled;
        };

        this.beginShadows = function() {
            renderingShadows = true;
            projectPlanes(null);
        };

        this.endShadows = function() {
            renderingShadows = false;
        };

        this.setGlobalState = function(planes, camera) {
            globalState = projectPlanes(planes, camera, 0);
        };

        this.setState = function(material, camera, useCache) {
            var planes = material.clippingPlanes,
                clipIntersection = material.clipIntersection,
                clipShadows = material.clipShadows;

            var materialProperties = properties.get(material);

            if (!localClippingEnabled || planes === null || planes.length === 0 || renderingShadows && !clipShadows) {
                // there's no local clipping

                if (renderingShadows) {
                    // there's no global clipping

                    projectPlanes(null);

                } else {
                    resetGlobalState();
                }

            } else {
                var nGlobal = renderingShadows ? 0 : numGlobalPlanes,
                    lGlobal = nGlobal * 4;

                var dstArray = materialProperties.clippingState || null;

                uniform.value = dstArray; // ensure unique state

                dstArray = projectPlanes(planes, camera, lGlobal, useCache);

                for (i in 0...lGlobal) {
                    dstArray[i] = globalState[i];
                }

                materialProperties.clippingState = dstArray;
                this.numIntersection = clipIntersection ? this.numPlanes : 0;
                this.numPlanes += nGlobal;
            }
        };

        function resetGlobalState() {
            if (uniform.value !== globalState) {
                uniform.value = globalState;
                uniform.needsUpdate = numGlobalPlanes > 0;
            }

            scope.numPlanes = numGlobalPlanes;
            scope.numIntersection = 0;
        }

        function projectPlanes(planes, camera, dstOffset, skipTransform) {
            var nPlanes = planes !== null ? planes.length : 0;
            var dstArray = null;

            if (nPlanes !== 0) {
                dstArray = uniform.value;

                if (skipTransform !== true || dstArray === null) {
                    var flatSize = dstOffset + nPlanes * 4,
                        viewMatrix = camera.matrixWorldInverse;

                    viewNormalMatrix.getNormalMatrix(viewMatrix);

                    if (dstArray === null || dstArray.length < flatSize) {
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
}