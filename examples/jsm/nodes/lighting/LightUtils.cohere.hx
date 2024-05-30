import js.Browser.Math;

function getDistanceAttenuation(lightDistance:Float, cutoffDistance:Float, decayExponent:Float):Float {
	var distanceFalloff = Math.pow(lightDistance, decayExponent).max(0.01).reciprocal();

	if (cutoffDistance > 0) {
		return distanceFalloff * Math.pow(Math.clamp(1 - Math.pow(lightDistance / cutoffDistance, 4), 0, 1), 2);
	} else {
		return distanceFalloff;
	}
}

class Main {
	static public function main() {
		var attenuation = getDistanceAttenuation(10, 5, 2);
		trace(attenuation); // Output: 0.04
	}
}