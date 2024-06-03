#ifdef USE_ALPHAHASH

// Derived from trials only, and may be changed.
static var ALPHA_HASH_SCALE:Float = 0.05;

static function hash2D(value:FloatArray):Float {
    return Math.abs(Math.sin(17.0 * value[0] + 0.1 * value[1]) * (0.1 + Math.abs(Math.sin(13.0 * value[1] + value[0]))) % 1);
}

static function hash3D(value:FloatArray):Float {
    return hash2D([hash2D([value[0], value[1]]), value[2]]);
}

static function getAlphaHashThreshold(position:FloatArray):Float {
    // Find the discretized derivatives of our coordinates
    var maxDeriv:Float = Math.max(
        Math.sqrt(Math.pow(position[0], 2) + Math.pow(position[1], 2) + Math.pow(position[2], 2)),
        Math.sqrt(Math.pow(position[0], 2) + Math.pow(position[1], 2) + Math.pow(position[2], 2))
    );
    var pixScale:Float = 1.0 / (ALPHA_HASH_SCALE * maxDeriv);

    // Find two nearest log-discretized noise scales
    var pixScales:FloatArray = [
        Math.pow(2, Math.floor(Math.log2(pixScale))),
        Math.pow(2, Math.ceil(Math.log2(pixScale)))
    ];

    // Compute alpha thresholds at our two noise scales
    var alpha:FloatArray = [
        hash3D([Math.floor(pixScales[0] * position[0]), Math.floor(pixScales[0] * position[1]), Math.floor(pixScales[0] * position[2])]),
        hash3D([Math.floor(pixScales[1] * position[0]), Math.floor(pixScales[1] * position[1]), Math.floor(pixScales[1] * position[2])])
    ];

    // Factor to interpolate lerp with
    var lerpFactor:Float = Math.log2(pixScale) % 1;

    // Interpolate alpha threshold from noise at two scales
    var x:Float = (1.0 - lerpFactor) * alpha[0] + lerpFactor * alpha[1];

    // Pass into CDF to compute uniformly distrib threshold
    var a:Float = Math.min(lerpFactor, 1.0 - lerpFactor);
    var cases:FloatArray = [
        x * x / (2.0 * a * (1.0 - a)),
        (x - 0.5 * a) / (1.0 - a),
        1.0 - ((1.0 - x) * (1.0 - x) / (2.0 * a * (1.0 - a)))
    ];

    // Find our final, uniformly distributed alpha threshold (ατ)
    var threshold:Float = (x < (1.0 - a))
        ? ((x < a) ? cases[0] : cases[1])
        : cases[2];

    // Avoids ατ == 0. Could also do ατ =1-ατ
    return Math.min(Math.max(threshold, 1.0e-6), 1.0);
}

#end