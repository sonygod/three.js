import three.animation.AnimationAction;
import three.animation.AnimationClip;
import three.animation.AnimationMixer;
import three.animation.tracks.NumberKeyframeTrack;
import three.core.Object3D;
import three.constants.LoopOnce;
import three.constants.LoopRepeat;
import three.constants.LoopPingPong;

class AnimationTests {
    public static function createAnimation():Dynamic {
        var root = new Object3D();
        var mixer = new AnimationMixer(root);
        var track = new NumberKeyframeTrack(".rotation[x]", [0, 1000], [0, 360]);
        var clip = new AnimationClip("clip1", 1000, [track]);
        var animationAction = mixer.clipAction(clip);
        return {
            root: root,
            mixer: mixer,
            track: track,
            clip: clip,
            animationAction: animationAction
        };
    }

    public static function createTwoAnimations():Dynamic {
        var root = new Object3D();
        var mixer = new AnimationMixer(root);
        var track = new NumberKeyframeTrack(".rotation[x]", [0, 1000], [0, 360]);
        var clip = new AnimationClip("clip1", 1000, [track]);
        var animationAction = mixer.clipAction(clip);
        var track2 = new NumberKeyframeTrack(".rotation[y]", [0, 1000], [0, 360]);
        var clip2 = new AnimationClip("clip2", 1000, [track]);
        var animationAction2 = mixer.clipAction(clip2);
        return {
            root: root,
            mixer: mixer,
            track: track,
            clip: clip,
            animationAction: animationAction,
            track2: track2,
            clip2: clip2,
            animationAction2: animationAction2
        };
    }

    public static function main() {
        var animationData = createAnimation();
        var animationAction:AnimationAction = animationData.animationAction;
        // Perform your animation tests here
    }
}