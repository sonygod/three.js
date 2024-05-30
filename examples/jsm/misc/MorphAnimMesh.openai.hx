package three.js.examples.jsm.misc;

import threejs.AnimationClip;
import threejs.AnimationMixer;
import threejs.Mesh;

class MorphAnimMesh extends Mesh {
    public var type(default, null):String;
    public var mixer(default, null):AnimationMixer;
    public var activeAction(default, null):AnimationClip;

    public function new(geometry:Geometry, material:Material) {
        super(geometry, material);
        type = 'MorphAnimMesh';
        mixer = new AnimationMixer(this);
        activeAction = null;
    }

    public function setDirectionForward() {
        mixer.timeScale = 1.0;
    }

    public function setDirectionBackward() {
        mixer.timeScale = -1.0;
    }

    public function playAnimation(label:String, fps:Float) {
        if (activeAction != null) {
            activeAction.stop();
            activeAction = null;
        }
        var clip:AnimationClip = AnimationClip.findByName(this, label);
        if (clip != null) {
            var action = mixer.clipAction(clip);
            action.timeScale = (clip.tracks.length * fps) / clip.duration;
            activeAction = action.play();
        } else {
            throw new Error('THREE.MorphAnimMesh: animations[' + label + '] undefined in .playAnimation()');
        }
    }

    public function updateAnimation(delta:Float) {
        mixer.update(delta);
    }

    override public function copy(source:Mesh, recursive:Bool):Mesh {
        super.copy(source, recursive);
        mixer = new AnimationMixer(this);
        return this;
    }
}