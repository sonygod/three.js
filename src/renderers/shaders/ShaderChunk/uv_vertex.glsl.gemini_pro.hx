class UvTransform {
  public var transform:hl.types.Float32Array;
  public function new(transform:hl.types.Float32Array) {
    this.transform = transform;
  }

  public function apply(uv:hl.types.Float32Array):hl.types.Float32Array {
    var transformedUv = new hl.types.Float32Array(2);
    transformedUv[0] = uv[0] * transform[0] + uv[1] * transform[1] + transform[2];
    transformedUv[1] = uv[0] * transform[3] + uv[1] * transform[4] + transform[5];
    return transformedUv;
  }
}

class Glsl {
  static public function uvTransform(uv:hl.types.Float32Array, transform:UvTransform):hl.types.Float32Array {
    return transform.apply(uv);
  }

  static public function main() {
    var vUv:hl.types.Float32Array;
    var vMapUv:hl.types.Float32Array;
    var vAlphaMapUv:hl.types.Float32Array;
    var vLightMapUv:hl.types.Float32Array;
    var vAoMapUv:hl.types.Float32Array;
    var vBumpMapUv:hl.types.Float32Array;
    var vNormalMapUv:hl.types.Float32Array;
    var vDisplacementMapUv:hl.types.Float32Array;
    var vEmissiveMapUv:hl.types.Float32Array;
    var vMetalnessMapUv:hl.types.Float32Array;
    var vRoughnessMapUv:hl.types.Float32Array;
    var vAnisotropyMapUv:hl.types.Float32Array;
    var vClearcoatMapUv:hl.types.Float32Array;
    var vClearcoatNormalMapUv:hl.types.Float32Array;
    var vClearcoatRoughnessMapUv:hl.types.Float32Array;
    var vIridescenceMapUv:hl.types.Float32Array;
    var vIridescenceThicknessMapUv:hl.types.Float32Array;
    var vSheenColorMapUv:hl.types.Float32Array;
    var vSheenRoughnessMapUv:hl.types.Float32Array;
    var vSpecularMapUv:hl.types.Float32Array;
    var vSpecularColorMapUv:hl.types.Float32Array;
    var vSpecularIntensityMapUv:hl.types.Float32Array;
    var vTransmissionMapUv:hl.types.Float32Array;
    var vThicknessMapUv:hl.types.Float32Array;

    if (Std.isOfType(uv, hl.types.Float32Array)) {
      vUv = new hl.types.Float32Array(2);
      vUv[0] = uv[0];
      vUv[1] = uv[1];
    }

    // ... other map uv calculations

    // Example:
    if (Std.isOfType(mapTransform, UvTransform)) {
      vMapUv = uvTransform(new hl.types.Float32Array([MAP_UV[0], MAP_UV[1]]), mapTransform);
    }
  }
}


**Explanation:**

1. **UvTransform Class:** A class is created to represent the UV transform matrix. It holds a `Float32Array` for the transform and provides a `apply` function to apply the transform to a given UV coordinate.

2. **Glsl Class:** This class encapsulates the GLSL-like logic. It has a `uvTransform` function that takes a UV coordinate and a `UvTransform` object and returns the transformed UV.

3. **Main Function:** The `main` function is where the UV transformations are calculated.
    * It checks for the existence of various UVs and transforms them using the `UvTransform` class and the `uvTransform` function.
    * You'll need to replace the `MAP_UV` placeholder with the actual UV coordinates for the map you are using.
    * The `Std.isOfType` checks are used to handle the conditional compilation logic from the original JavaScript code.

**How to Use:**

1. **Initialize UvTransforms:** Create `UvTransform` objects for each map you want to transform.
2. **Call Glsl.main():** Call the `Glsl.main` function to calculate the transformed UVs.
3. **Access Transformed UVs:** Access the `vUv`, `vMapUv`, etc. variables to use the transformed UV coordinates in your shader.

**Example:**


var mapTransform = new UvTransform(new hl.types.Float32Array([1, 0, 0, 0, 1, 0]));
var uv = new hl.types.Float32Array([0.5, 0.5]);

Glsl.main();

var transformedUv = Glsl.vMapUv;