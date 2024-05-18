package three.js.examples.jm.misc;

import threejs.Object3D;
import threejs.Quaternion;
import threejs.Vector3;

class Gyroscope extends Object3D {
    private var _translationObject:Vector3 = new Vector3();
    private var _quaternionObject:Quaternion = new Quaternion();
    private var _scaleObject:Vector3 = new Vector3();

    private var _translationWorld:Vector3 = new Vector3();
    private var _quaternionWorld:Quaternion = new Quaternion();
    private var _scaleWorld:Vector3 = new Vector3();

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