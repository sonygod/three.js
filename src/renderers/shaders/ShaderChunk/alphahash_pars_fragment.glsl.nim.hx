package three.js.src.renderers.shaders.ShaderChunk;

#if USE_ALPHAHASH

/**
 * See: https://casual-effects.com/research/Wyman2017Hashed/index.html
 */

const ALPHA_HASH_SCALE:Float = 0.05; // Derived from trials only, and may be changed.

function hash2D(value:three.js.src.math.Vector2):Float {

	return Math.fract(1.0e4 * Math.sin(17.0 * value.x + 0.1 * value.y) * (0.1 + Math.abs(Math.sin(13.0 * value.y + value.x))));

}

function hash3D(value:three.js.src.math.Vector3):Float {

	return hash2D(new three.js.src.math.Vector2(hash2D(value.xy), value.z));

}

function getAlphaHashThreshold(position:three.js.src.math.Vector3):Float {

	// Find the discretized derivatives of our coordinates
	var maxDeriv:Float = Math.max(
		Math.length(Math.dFdx(position.xyz)),
		Math.length(Math.dFdy(position.xyz))
	);
	var pixScale:Float = 1.0 / (ALPHA_HASH_SCALE * maxDeriv);

	// Find two nearest log-discretized noise scales
	var pixScales:three.js.src.math.Vector2 = new three.js.src.math.Vector2(
		Math.exp2(Math.floor(Math.log2(pixScale))),
		Math.exp2(Math.ceil(Math.log2(pixScale)))
	);

	// Compute alpha thresholds at our two noise scales
	var alpha:three.js.src.math.Vector2 = new three.js.src.math.Vector2(
		hash3D(new three.js.src.math.Vector3(Math.floor(pixScales.x * position.x), Math.floor(pixScales.x * position.y), Math.floor(pixScales.x * position.z))),
		hash3D(new three.js.src.math.Vector3(Math.floor(pixScales.y * position.x), Math.floor(pixScales.y * position.y), Math.floor(pixScales.y * position.z)))
	);

	// Factor to interpolate lerp with
	var lerpFactor:Float = Math.fract(Math.log2(pixScale));

	// Interpolate alpha threshold from noise at two scales
	var x:Float = (1.0 - lerpFactor) * alpha.x + lerpFactor * alpha.y;

	// Pass into CDF to compute uniformly distrib threshold
	var a:Float = Math.min(lerpFactor, 1.0 - lerpFactor);
	var cases:three.js.src.math.Vector3 = new three.js.src.math.Vector3(
		x * x / (2.0 * a * (1.0 - a)),
		(x - 0.5 * a) / (1.0 - a),
		1.0 - ((1.0 - x) * (1.0 - x) / (2.0 * a * (1.0 - a)))
	);

	// Find our final, uniformly distributed alpha threshold (ατ)
	var threshold:Float = (x < (1.0 - a))
		? ((x < a) ? cases.x : cases.y)
		: cases.z;

	// Avoids ατ == 0. Could also do ατ =1-ατ
	return Math.clamp(threshold, 1.0e-6, 1.0);

}

#end