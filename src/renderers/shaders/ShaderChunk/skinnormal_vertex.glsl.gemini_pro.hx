class SkinningShader extends Shader {
  static function main(objectNormal: Vector3, objectTangent: Vector3, skinWeight: Vector4, boneMatX: Matrix4, boneMatY: Matrix4, boneMatZ: Matrix4, boneMatW: Matrix4, bindMatrix: Matrix4, bindMatrixInverse: Matrix4): {normal: Vector3, tangent: Vector3} {
    var skinMatrix = new Matrix4(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    skinMatrix = skinMatrix.add(boneMatX.multiplyScalar(skinWeight.x));
    skinMatrix = skinMatrix.add(boneMatY.multiplyScalar(skinWeight.y));
    skinMatrix = skinMatrix.add(boneMatZ.multiplyScalar(skinWeight.z));
    skinMatrix = skinMatrix.add(boneMatW.multiplyScalar(skinWeight.w));
    skinMatrix = bindMatrixInverse.multiply(skinMatrix).multiply(bindMatrix);
    var newNormal = new Vector3(skinMatrix.multiply(new Vector4(objectNormal.x, objectNormal.y, objectNormal.z, 0)).x, skinMatrix.multiply(new Vector4(objectNormal.x, objectNormal.y, objectNormal.z, 0)).y, skinMatrix.multiply(new Vector4(objectNormal.x, objectNormal.y, objectNormal.z, 0)).z);
    var newTangent: Vector3;
    if (Std.isOfType(objectTangent, Vector3)) {
      newTangent = new Vector3(skinMatrix.multiply(new Vector4(objectTangent.x, objectTangent.y, objectTangent.z, 0)).x, skinMatrix.multiply(new Vector4(objectTangent.x, objectTangent.y, objectTangent.z, 0)).y, skinMatrix.multiply(new Vector4(objectTangent.x, objectTangent.y, objectTangent.z, 0)).z);
    } else {
      newTangent = null;
    }
    return {normal: newNormal, tangent: newTangent};
  }
}


**Explanation:**

* **Haxe Syntax:** The code is written in Haxe syntax, using classes, static methods, and data types.
* **Matrix4 and Vector3:** Haxe's `hx.math` library provides `Matrix4` and `Vector3` classes, which are used for matrix and vector operations.
* **Method Signature:** The `main` method takes the required inputs (objectNormal, objectTangent, skinWeight, bone matrices, bindMatrix, bindMatrixInverse) and returns an object containing the transformed normal and tangent vectors.
* **Matrix Operations:** The matrix operations (addition, multiplication) are implemented using the methods provided by the `Matrix4` and `Vector4` classes.
* **Conditional Tangent Transformation:** The code conditionally transforms the tangent vector only if it is a `Vector3`. This allows for optional tangent transformation.

**Usage:**


// Example usage:
var objectNormal: Vector3 = new Vector3(1, 0, 0);
var objectTangent: Vector3 = new Vector3(0, 1, 0);
var skinWeight: Vector4 = new Vector4(1, 0, 0, 0);
var boneMatX: Matrix4 = new Matrix4(); // Initialize bone matrices
var boneMatY: Matrix4 = new Matrix4();
var boneMatZ: Matrix4 = new Matrix4();
var boneMatW: Matrix4 = new Matrix4();
var bindMatrix: Matrix4 = new Matrix4(); // Initialize bind matrix
var bindMatrixInverse: Matrix4 = new Matrix4(); // Initialize inverse bind matrix

var result = SkinningShader.main(objectNormal, objectTangent, skinWeight, boneMatX, boneMatY, boneMatZ, boneMatW, bindMatrix, bindMatrixInverse);

// Access the transformed vectors:
var newNormal: Vector3 = result.normal;
var newTangent: Vector3 = result.tangent;