package three.js.examples.jm.misc;

import three.AnimationClip;
import three.AnimationMixer;
import three.Mesh;

class MorphAnimMesh extends Mesh {

    public var type:String;

    public var mixer:AnimationMixer;
    public var activeAction:AnimationAction;

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);
        this.type = 'MorphAnimMesh';
        this.mixer = new AnimationMixer(this);
        this.activeAction = null;
    }

    public function setDirectionForward():Void {
        this.mixer.timeScale = 1.0;
    }

    public function setDirectionBackward():Void {
        this.mixer.timeScale = -1.0;
    }

    public function playAnimation(label:String, fps:Float):Void {
        if (this.activeAction != null) {
            this.activeAction.stop();
            this.activeAction = null;
        }

        var clip:AnimationClip = AnimationClip.findByName(this, label);
        if (clip != null) {
            var action:AnimationAction = this.mixer.clipAction(clip);
            action.timeScale = (clip.tracks.length * fps) / clip.duration;
            this.activeAction = action.play();
        } else {
            throw new Error('THREE.MorphAnimMesh: animations[' + label + '] undefined in .playAnimation()');
        }
    }

    public function updateAnimation(delta:Float):Void {
        this.mixer.update(delta);
    }

    override public function copy(source:Mesh, recursive:Bool):Mesh {
        super.copy(source, recursive);
        this.mixer = new AnimationMixer(this);
        return this;
    }
}