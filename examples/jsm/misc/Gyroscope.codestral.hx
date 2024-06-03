import three.core.Object3D;
import three.math.Quaternion;
import three.math.Vector3;

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
        if (this.matrixAutoUpdate) this.updateMatrix();

        if (this.matrixWorldNeedsUpdate || force) {
            if (this.parent != null) {
                this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);

                this.matrixWorld.decompose(this._translationWorld, this._quaternionWorld, this._scaleWorld);
                this.matrix.decompose(this._translationObject, this._quaternionObject, this._scaleObject);

                this.matrixWorld.compose(this._translationWorld, this._quaternionObject, this._scaleWorld);
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