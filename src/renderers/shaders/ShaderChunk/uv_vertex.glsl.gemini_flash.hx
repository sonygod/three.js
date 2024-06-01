class UVTransform {
  public var matrix:hl.types.Float32Array;

  public function new(matrix:hl.types.Float32Array) {
    this.matrix = matrix;
  }

  public function transform(uv:hl.types.Float32Array):hl.types.Float32Array {
    var vec3 = new hl.types.Float32Array([uv[0], uv[1], 1]);
    return hl.types.Float32Array.ofFloat32Array(hl.types.Float32Array.mul(this.matrix, vec3)).slice(0, 2);
  }
}

class UVUtils {

  public static function generateUV(uv:hl.types.Float32Array):hl.types.Float32Array {
    return hl.types.Float32Array.ofFloat32Array([uv[0], uv[1]]);
  }

  public static function generateUV3(uv:hl.types.Float32Array):hl.types.Float32Array {
    return hl.types.Float32Array.ofFloat32Array([uv[0], uv[1], 1]);
  }

  public static function transform(uv:hl.types.Float32Array, transform:UVTransform):hl.types.Float32Array {
    if (transform != null) {
      return transform.transform(uv);
    } else {
      return uv;
    }
  }
}

// ... other code ...

var vUv = null;
if (USE_UV || USE_ANISOTROPY) {
  vUv = UVUtils.generateUV3(uv);
}

// ... other code ...

var vMapUv = null;
if (USE_MAP) {
  vMapUv = UVUtils.transform(UVUtils.generateUV3(MAP_UV), mapTransform);
}

// ... other code ...

// ... similar code for other maps ...