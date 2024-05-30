package three.js.test.unit.src.animation;

import haxe.Timer;
import three.animation.AnimationAction;
import three.animation.AnimationClip;
import three.animation.AnimationMixer;
import three.animation.tracks.NumberKeyframeTrack;
import three.core.Object3D;

class AnimationActionTests {

    public function new() {}

    public function createAnimation():{
        root:Object3D,
        mixer:AnimationMixer,
        track:NumberKeyframeTrack,
        clip:AnimationClip,
        animationAction:AnimationAction
    } {
        var root = new Object3D();
        var mixer = new AnimationMixer(root);
        var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
        var clip = new AnimationClip('clip1', 1000, [track]);
        var animationAction = mixer.clipAction(clip);
        return { root: root, mixer: mixer, track: track, clip: clip, animationAction: animationAction };
    }

    public function createTwoAnimations():{
        root:Object3D,
        mixer:AnimationMixer,
        track:NumberKeyframeTrack,
        clip:AnimationClip,
        animationAction:AnimationAction,
        track2:NumberKeyframeTrack,
        clip2:AnimationClip,
        animationAction2:AnimationAction
    } {
        var root = new Object3D();
        var mixer = new AnimationMixer(root);
        var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
        var clip = new AnimationClip('clip1', 1000, [track]);
        var animationAction = mixer.clipAction(clip);
        var track2 = new NumberKeyframeTrack('.rotation[y]', [0, 1000], [0, 360]);
        var clip2 = new AnimationClip('clip2', 1000, [track]);
        var animationAction2 = mixer.clipAction(clip2);
        return { root: root, mixer: mixer, track: track, clip: clip, animationAction: animationAction, track2: track2, clip2: clip2, animationAction2: animationAction2 };
    }

    public function runTests():Void {
        describe('Animation', () => {
            describe('AnimationAction', () => {
                it('Instancing', () => {
                    var mixer = new AnimationMixer();
                    var clip = new AnimationClip('nonname', -1, []);
                    var animationAction = new AnimationAction(mixer, clip);
                    assert.ok(animationAction != null, 'animationAction instanciated');
                });

                todo('blendMode', () => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('loop', () => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // ... other tests ...

                it('play', () => {
                    var { mixer, animationAction } = createAnimation();
                    var animationAction2 = animationAction.play();
                    assert.equal(animationAction, animationAction2, 'AnimationAction.play can be chained.');
                    // ... other tests ...
                });
            });
        });
    }
}