class SkinningShader extends Shader {

  static function main(transformed: Vector3, bindMatrix: Matrix4, bindMatrixInverse: Matrix4, skinWeight: Vector4, boneMatX: Matrix4, boneMatY: Matrix4, boneMatZ: Matrix4, boneMatW: Matrix4): Vector3 {
    #if USE_SKINNING
      var skinVertex = bindMatrix.multiply(new Vector4(transformed.x, transformed.y, transformed.z, 1.0));

      var skinned = new Vector4(0.0);
      skinned = skinned.add(boneMatX.multiply(skinVertex).multiplyScalar(skinWeight.x));
      skinned = skinned.add(boneMatY.multiply(skinVertex).multiplyScalar(skinWeight.y));
      skinned = skinned.add(boneMatZ.multiply(skinVertex).multiplyScalar(skinWeight.z));
      skinned = skinned.add(boneMatW.multiply(skinVertex).multiplyScalar(skinWeight.w));

      transformed = bindMatrixInverse.multiply(skinned).toVector3();
    #end
    return transformed;
  }
}


**Explanation:**

* **Haxe Syntax:** The code is written in Haxe syntax, using `class` for defining the shader and `static function` for the main method.
* **Conditional Compilation:** The `#if USE_SKINNING` directive is used for conditional compilation, similar to `#ifdef` in GLSL. This allows the code to be compiled only when the `USE_SKINNING` flag is defined.
* **Vector and Matrix Types:** Haxe provides built-in types for vectors (`Vector3`, `Vector4`) and matrices (`Matrix4`).
* **Matrix Operations:** The code uses the `multiply()` method to multiply matrices and vectors.
* **Scalar Multiplication:** The `multiplyScalar()` method is used to multiply a vector by a scalar value.
* **Conversion to Vector3:** The `toVector3()` method is used to convert a `Vector4` to a `Vector3` by discarding the fourth component.

**Usage:**

You can use the `SkinningShader` class in your Haxe code to apply skinning transformations to vertices. For example:


var transformed: Vector3 = new Vector3(1.0, 2.0, 3.0);
var bindMatrix: Matrix4 = ...;
var bindMatrixInverse: Matrix4 = ...;
var skinWeight: Vector4 = ...;
var boneMatX: Matrix4 = ...;
var boneMatY: Matrix4 = ...;
var boneMatZ: Matrix4 = ...;
var boneMatW: Matrix4 = ...;

var skinnedVertex: Vector3 = SkinningShader.main(transformed, bindMatrix, bindMatrixInverse, skinWeight, boneMatX, boneMatY, boneMatZ, boneMatW);