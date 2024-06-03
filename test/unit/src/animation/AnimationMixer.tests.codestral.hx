import three.animation.AnimationMixer;
import three.core.EventDispatcher;
import three.animation.AnimationClip;
import three.animation.tracks.VectorKeyframeTrack;
import three.core.Object3D;
import three.math.Vector3;

class AnimationMixerTests {
    public static function main() {
        testExtending();
        testInstancing();
        testStopAllAction();
        testGetRoot();
    }

    static function getClips(pos1:Vector3, pos2:Vector3, scale1:Vector3, scale2:Vector3, dur:Float) {
        var clips:Array<AnimationClip> = [];

        var track = new VectorKeyframeTrack(".scale", [0, dur], [scale1.x, scale1.y, scale1.z, scale2.x, scale2.y, scale2.z]);
        clips.push(new AnimationClip("scale", dur, [track]));

        track = new VectorKeyframeTrack(".position", [0, dur], [pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z]);
        clips.push(new AnimationClip("position", dur, [track]));

        return clips;
    }

    static function testExtending() {
        var object = new AnimationMixer();
        trace("AnimationMixer extends from EventDispatcher: " + (object is EventDispatcher));
    }

    static function testInstancing() {
        var object = new AnimationMixer();
        trace("Can instantiate a AnimationMixer: " + (object != null));
    }

    static function testStopAllAction() {
        var obj = new Object3D();
        var animMixer = new AnimationMixer(obj);
        var clips = getClips(new Vector3(0, 0, 0), new Vector3(1, 1, 1), new Vector3(2, 2, 2), new Vector3(1, 1, 1), 1);
        var actionA = animMixer.clipAction(clips[0]);
        var actionB = animMixer.clipAction(clips[1]);

        actionA.play();
        actionB.play();
        animMixer.update(0.1);
        animMixer.stopAllAction();

        trace("All actions stopped: " + (!actionA.isRunning() && !actionB.isRunning()));
        trace("Position reset as expected: " + (obj.position.x == 0 && obj.position.y == 0 && obj.position.z == 0));
        trace("Scale reset as expected: " + (obj.scale.x == 1 && obj.scale.y == 1 && obj.scale.z == 1));
    }

    static function testGetRoot() {
        var obj = new Object3D();
        var animMixer = new AnimationMixer(obj);
        trace("Get original root object: " + (obj == animMixer.getRoot()));
    }
}