package three.js.src.renderers.shaders.ShaderChunk;

#if USE_ALPHAHASH

/**
 * See: https://casual-effects.com/research/Wyman2017Hashed/index.html
 */

final ALPHA_HASH_SCALE: Float = 0.05; // Derived from trials only, and may be changed.

inline function hash2D(value: Vec2): Float {
    return fract(1.0e4 * Math.sin(17.0 * value.x + 0.1 * value.y) * (0.1 + Math.abs(Math.sin(13.0 * value.y + value.x))));
}

inline function hash3D(value: Vec3): Float {
    return hash2D(new Vec2(hash2D(value.xy), value.z));
}

inline function getAlphaHashThreshold(position: Vec3): Float {

    // Find the discretized derivatives of our coordinates
    var maxDeriv: Float = Math.max(
        length(dFdx(position.xyz)),
        length(dFdy(position.xyz))
    );
    var pixScale: Float = 1.0 / (ALPHA_HASH_SCALE * maxDeriv);

    // Find two nearest log-discretized noise scales
    var pixScales: Vec2 = new Vec2(
        Math.exp2(Math.floor(Math.log2(pixScale))),
        Math.exp2(Math.ceil(Math.log2(pixScale)))
    );

    // Compute alpha thresholds at our two noise scales
    var alpha: Vec2 = new Vec2(
        hash3D(Math.floor(pixScales.x * position.xyz)),
        hash3D(Math.floor(pixScales.y * position.xyz))
    );

    // Factor to interpolate lerp with
    var lerpFactor: Float = fract(Math.log2(pixScale));

    // Interpolate alpha threshold from noise at two scales
    var x: Float = (1.0 - lerpFactor) * alpha.x + lerpFactor * alpha.y;

    // Pass into CDF to compute uniformly distrib threshold
    var a: Float = Math.min(lerpFactor, 1.0 - lerpFactor);
    var cases: Vec3 = new Vec3(
        x * x / (2.0 * a * (1.0 - a)),
        (x - 0.5 * a) / (1.0 - a),
        1.0 - ((1.0 - x) * (1.0 - x) / (2.0 * a * (1.0 - a)))
    );

    // Find our final, uniformly distributed alpha threshold (ατ)
    var threshold: Float = (x < (1.0 - a))
        ? ((x < a) ? cases.x : cases.y)
        : cases.z;

    // Avoids ατ == 0. Could also do ατ =1-ατ
    return Math.clamp(threshold, 1.0e-6, 1.0);
}

#end