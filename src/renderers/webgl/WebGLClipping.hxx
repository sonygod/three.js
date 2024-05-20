import three.math.Matrix3;
import three.math.Plane;

class WebGLClipping {

	var globalState:Null<Array<Float>>;
	var numGlobalPlanes:Int;
	var localClippingEnabled:Bool;
	var renderingShadows:Bool;

	var plane:Plane;
	var viewNormalMatrix:Matrix3;

	var uniform:{value:Null<Array<Float>>, needsUpdate:Bool};

	public var numPlanes(default, null):Int;
	public var numIntersection(default, null):Int;

	public function new(properties) {

		globalState = null;
		numGlobalPlanes = 0;
		localClippingEnabled = false;
		renderingShadows = false;

		plane = new Plane();
		viewNormalMatrix = new Matrix3();

		uniform = {value: null, needsUpdate: false};

		numPlanes = 0;
		numIntersection = 0;

	}

	public function init(planes:Array<Plane>, enableLocalClipping:Bool):Bool {

		var enabled =
			planes.length != 0 ||
			enableLocalClipping ||
			numGlobalPlanes != 0 ||
			localClippingEnabled;

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

	public function setGlobalState(planes:Array<Plane>, camera):Void {

		globalState = projectPlanes(planes, camera, 0);

	}

	public function setState(material, camera, useCache:Bool):Void {

		var planes = material.clippingPlanes;
		var clipIntersection = material.clipIntersection;
		var clipShadows = material.clipShadows;

		var materialProperties = properties.get(material);

		if (!localClippingEnabled || planes == null || planes.length == 0 || renderingShadows && !clipShadows) {

			if (renderingShadows) {

				projectPlanes(null);

			} else {

				resetGlobalState();

			}

		} else {

			var nGlobal = renderingShadows ? 0 : numGlobalPlanes;
			var lGlobal = nGlobal * 4;

			var dstArray = materialProperties.clippingState ?? null;

			uniform.value = dstArray;

			dstArray = projectPlanes(planes, camera, lGlobal, useCache);

			for (i in 0...lGlobal) {

				dstArray[i] = globalState[i];

			}

			materialProperties.clippingState = dstArray;
			numIntersection = clipIntersection ? numPlanes : 0;
			numPlanes += nGlobal;

		}

	}

	private function resetGlobalState():Void {

		if (uniform.value != globalState) {

			uniform.value = globalState;
			uniform.needsUpdate = numGlobalPlanes > 0;

		}

		numPlanes = numGlobalPlanes;
		numIntersection = 0;

	}

	private function projectPlanes(planes:Null<Array<Plane>>, camera, dstOffset:Int, skipTransform:Bool):Array<Float> {

		var nPlanes = planes != null ? planes.length : 0;
		var dstArray:Null<Array<Float>> = null;

		if (nPlanes != 0) {

			dstArray = uniform.value;

			if (skipTransform != true || dstArray == null) {

				var flatSize = dstOffset + nPlanes * 4;
				var viewMatrix = camera.matrixWorldInverse;

				viewNormalMatrix.getNormalMatrix(viewMatrix);

				if (dstArray == null || dstArray.length < flatSize) {

					dstArray = new Float32Array(flatSize);

				}

				for (i in 0...nPlanes) {

					var i4 = dstOffset + i * 4;

					plane.copy(planes[i]).applyMatrix4(viewMatrix, viewNormalMatrix);

					plane.normal.toArray(dstArray, i4);
					dstArray[i4 + 3] = plane.constant;

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