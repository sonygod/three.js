class Main {
  public static function main(): Void {
    // Haxe doesn't have a direct equivalent to GLSL shaders.
    // This code will need to be adapted for use in a Haxe rendering context.

    // Here's a basic conversion of the functions, but you'll need to integrate them into your specific framework:

    static function hash2D(value: Vector2): Float {
      return Math.fract(1.0e4 * Math.sin(17.0 * value.x + 0.1 * value.y) * (0.1 + Math.abs(Math.sin(13.0 * value.y + value.x))));
    }

    static function hash3D(value: Vector3): Float {
      return hash2D(new Vector2(hash2D(new Vector2(value.x, value.y)), value.z));
    }

    static function getAlphaHashThreshold(position: Vector3): Float {
      // Find the discretized derivatives of our coordinates (implementation depends on your framework)
      var maxDeriv = Math.max(
        // length(dFdx(position.xyz)),
        // length(dFdy(position.xyz))
        0.0, // Replace with actual derivative calculations
        0.0
      );
      var pixScale = 1.0 / (0.05 * maxDeriv);

      // Find two nearest log-discretized noise scales
      var pixScales = new Vector2(
        Math.pow(2, Math.floor(Math.log(pixScale) / Math.LN2)),
        Math.pow(2, Math.ceil(Math.log(pixScale) / Math.LN2))
      );

      // Compute alpha thresholds at our two noise scales
      var alpha = new Vector2(
        hash3D(new Vector3(Math.floor(pixScales.x * position.x), Math.floor(pixScales.x * position.y), Math.floor(pixScales.x * position.z))),
        hash3D(new Vector3(Math.floor(pixScales.y * position.x), Math.floor(pixScales.y * position.y), Math.floor(pixScales.y * position.z)))
      );

      // Factor to interpolate lerp with
      var lerpFactor = Math.fract(Math.log(pixScale) / Math.LN2);

      // Interpolate alpha threshold from noise at two scales
      var x = (1.0 - lerpFactor) * alpha.x + lerpFactor * alpha.y;

      // Pass into CDF to compute uniformly distrib threshold
      var a = Math.min(lerpFactor, 1.0 - lerpFactor);
      var cases = new Vector3(
        x * x / (2.0 * a * (1.0 - a)),
        (x - 0.5 * a) / (1.0 - a),
        1.0 - ((1.0 - x) * (1.0 - x) / (2.0 * a * (1.0 - a)))
      );

      // Find our final, uniformly distributed alpha threshold (ατ)
      var threshold = (x < (1.0 - a)) ? ((x < a) ? cases.x : cases.y) : cases.z;

      // Avoids ατ == 0. Could also do ατ =1-ατ
      return Math.clamp(threshold, 1.0e-6, 1.0);
    }
  }
}

class Vector2 {
  public var x: Float;
  public var y: Float;

  public function new(x: Float, y: Float) {
    this.x = x;
    this.y = y;
  }
}

class Vector3 {
  public var x: Float;
  public var y: Float;
  public var z: Float;

  public function new(x: Float, y: Float, z: Float) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
}