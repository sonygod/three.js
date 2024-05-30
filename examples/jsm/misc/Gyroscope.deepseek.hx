import three.Object3D;
import three.Quaternion;
import three.Vector3;

class Gyroscope extends Object3D {

    private static var _translationObject:Vector3 = new Vector3();
    private static var _quaternionObject:Quaternion = new Quaternion();
    private static var _scaleObject:Vector3 = new Vector3();

    private static var _translationWorld:Vector3 = new Vector3();
    private static var _quaternionWorld:Quaternion = new Quaternion();
    private static var _scaleWorld:Vector3 = new Vector3();

    public function new() {
        super();
    }

    public function updateMatrixWorld(force:Bool):Void {

        if (this.matrixAutoUpdate) this.updateMatrix();

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

        for (i in 0...this.children.length) {

            this.children[i].updateMatrixWorld(force);

        }

    }

}