package three.js.examples.jsm.misc;

import three.*;

class Gyroscope extends Object3D {
  static var _translationObject = new Vector3();
  static var _quaternionObject = new Quaternion();
  static var _scaleObject = new Vector3();

  static var _translationWorld = new Vector3();
  static var _quaternionWorld = new Quaternion();
  static var _scaleWorld = new Vector3();

  public function new() {
    super();
  }

  override public function updateMatrixWorld(force:Bool) {
    if (matrixAutoUpdate) {
      updateMatrix();
    }

    // update matrixWorld
    if (matrixWorldNeedsUpdate || force) {
      if (parent != null) {
        matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);

        matrixWorld.decompose(_translationWorld, _quaternionWorld, _scaleWorld);
        matrix.decompose(_translationObject, _quaternionObject, _scaleObject);

        matrixWorld.compose(_translationWorld, _quaternionObject, _scaleWorld);
      } else {
        matrixWorld.copy(matrix);
      }

      matrixWorldNeedsUpdate = false;
      force = true;
    }

    // update children
    for (i in 0...children.length) {
      children[i].updateMatrixWorld(force);
    }
  }
}