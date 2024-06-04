import three.core.Mesh;
import three.animation.AnimationMixer;
import three.animation.AnimationClip;

class MorphAnimMesh extends Mesh {

	public var mixer:AnimationMixer;
	public var activeAction:AnimationAction;

	public function new(geometry:three.core.Geometry, material:three.materials.Material) {
		super(geometry, material);
		this.type = 'MorphAnimMesh';
		this.mixer = new AnimationMixer(this);
		this.activeAction = null;
	}

	public function setDirectionForward() {
		this.mixer.timeScale = 1.0;
	}

	public function setDirectionBackward() {
		this.mixer.timeScale = -1.0;
	}

	public function playAnimation(label:String, fps:Float) {
		if (this.activeAction != null) {
			this.activeAction.stop();
			this.activeAction = null;
		}

		var clip = AnimationClip.findByName(this, label);
		if (clip != null) {
			var action = this.mixer.clipAction(clip);
			action.timeScale = (clip.tracks.length * fps) / clip.duration;
			this.activeAction = action.play();
		} else {
			throw new Error("THREE.MorphAnimMesh: animations[" + label + "] undefined in .playAnimation()");
		}
	}

	public function updateAnimation(delta:Float) {
		this.mixer.update(delta);
	}

	public function copy(source:Mesh, recursive:Bool):Mesh {
		super.copy(source, recursive);
		this.mixer = new AnimationMixer(this);
		return this;
	}

}