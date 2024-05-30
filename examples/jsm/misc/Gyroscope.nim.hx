import three.js.examples.jsm.misc.Gyroscope;
import three.js.examples.jsm.math.Vector3;
import three.js.examples.jsm.math.Quaternion;
import three.js.examples.jsm.core.Object3D;

class Main {
    static function main() {
        var _translationObject = new Vector3();
        var _quaternionObject = new Quaternion();
        var _scaleObject = new Vector3();

        var _translationWorld = new Vector3();
        var _quaternionWorld = new Quaternion();
        var _scaleWorld = new Vector3();

        class Gyroscope extends Object3D {
            public function new() {
                super();
            }

            public function updateMatrixWorld(force:Bool) {
                if (this.matrixAutoUpdate) this.updateMatrix();

                // update matrixWorld
                if (this.matrixWorldNeedsUpdate || force) {
                    if (this.parent != null) {
                        this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
                        this.matrixWorld.decompose(_translationWorld, _quaternionWorld, _scaleWorld);
                        this.matrix.decompose(_translationObject, _quaternionObject, _scaleObject);
                        this.matrixWorld.compose(_translationWorld, _quaternionObject, _scaleWorld);
                    } else {
                        this.matrixWorld.copy(this.matrix);
                    }

                    this.matrixWorldNeedsUpdate = false;
                    force = true;
                }

                // update children
                for (i in 0...this.children.length) {
                    this.children[i].updateMatrixWorld(force);
                }
            }
        }
    }
}