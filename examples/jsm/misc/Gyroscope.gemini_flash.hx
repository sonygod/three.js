import three.core.Object3D;
import three.math.Quaternion;
import three.math.Vector3;

class Gyroscope extends Object3D {

	private static _translationObject:Vector3 = new Vector3();
	private static _quaternionObject:Quaternion = new Quaternion();
	private static _scaleObject:Vector3 = new Vector3();

	private static _translationWorld:Vector3 = new Vector3();
	private static _quaternionWorld:Quaternion = new Quaternion();
	private static _scaleWorld:Vector3 = new Vector3();

	public function new() {
		super();
	}

	override public function updateMatrixWorld(force:Bool):Void {
		if (this.matrixAutoUpdate) {
			this.updateMatrix();
		}

		// update matrixWorld
		if (this.matrixWorldNeedsUpdate || force) {
			if (this.parent != null) {
				this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
				this.matrixWorld.decompose(Gyroscope._translationWorld, Gyroscope._quaternionWorld, Gyroscope._scaleWorld);
				this.matrix.decompose(Gyroscope._translationObject, Gyroscope._quaternionObject, Gyroscope._scaleObject);
				this.matrixWorld.compose(Gyroscope._translationWorld, Gyroscope._quaternionObject, Gyroscope._scaleWorld);
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