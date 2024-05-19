#if USE_ALPHAHASH

	/**
	 * See: https://casual-effects.com/research/Wyman2017Hashed/index.html
	 */

	const ALPHA_HASH_SCALE = 0.05; // Derived from trials only, and may be changed.

	function hash2D(value:Float2):Float {
		return Math.fract(1.0e4 * Math.sin(17.0 * value.x + 0.1 * value.y) * (0.1 + Math.abs(Math.sin(13.0 * value.y + value.x))));
	}

	function hash3D(value:Float3):Float {
		return hash2D(new Float2(hash2D(new Float2(value.x, value.y)), value.z));
	}

	function getAlphaHashThreshold(position:Float3):Float {
		// Find the discretized derivatives of our coordinates
		var maxDeriv = Math.max(
			position.length,
			position.dFdy.length
		);
		var pixScale = 1.0 / (ALPHA_HASH_SCALE * maxDeriv);

		// Find two nearest log-discretized noise scales
		var pixScales = new Float2(
			Math.exp2(Math.floor(Math.log2(pixScale))),
			Math.exp2(Math.ceil(Math.log2(pixScale)))
		);

		// Compute alpha thresholds at our two noise scales
		var alpha = new Float2(
			hash3D(new Float3(Math.floor(pixScales.x * position.x), Math.floor(pixScales.x * position.y), Math.floor(pixScales.x * position.z))),
			hash3D(new Float3(Math.floor(pixScales.y * position.x), Math.floor(pixScales.y * position.y), Math.floor(pixScales.y * position.z)))
		);

		// Factor to interpolate lerp with
		var lerpFactor = Math.fract(Math.log2(pixScale));

		// Interpolate alpha threshold from noise at two scales
		var x = (1.0 - lerpFactor) * alpha.x + lerpFactor * alpha.y;

		// Pass into CDF to compute uniformly distrib threshold
		var a = Math.min(lerpFactor, 1.0 - lerpFactor);
		var cases = new Float3(
			x * x / (2.0 * a * (1.0 - a)),
			(x - 0.5 * a) / (1.0 - a),
			1.0 - ((1.0 - x) * (1.0 - x) / (2.0 * a * (1.0 - a)))
		);

		// Find our final, uniformly distributed alpha threshold (ατ)
		var threshold = (x < (1.0 - a))
			? ((x < a) ? cases.x : cases.y)
			: cases.z;

		// Avoids ατ == 0. Could also do ατ =1-ατ
		return Math.clamp(threshold, 1.0e-6, 1.0);
	}

#end