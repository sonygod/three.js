Here is the converted Haxe code:
```
package three.animation;

import haxe.unit.TestCase;

class AnimationActionTests extends TestCase {
    static function createAnimation():{ root:Object3D, mixer:AnimationMixer, track:NumberKeyframeTrack, clip:AnimationClip, animationAction:AnimationAction } {
        var root = new Object3D();
        var mixer = new AnimationMixer(root);
        var track = new NumberKeyframeTrack('.rotation[x]', [0, 1000], [0, 360]);
        var clip = new AnimationClip('clip1', 1000, [track]);
        var animationAction = mixer.clipAction(clip);
        return { root: root, mixer: mixer, track: track, clip: clip, animationAction: animationAction };
    }

    static function createTwoAnimations():{ root:Object3D, mixer:AnimationMixer, track:NumberKeyframeTrack, clip:AnimationClip, animationAction:AnimationAction, track2:NumberKeyframeTrack, clip2:AnimationClip, animationAction2:AnimationAction } {
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

    public function testInstancing() {
        var mixer = new AnimationMixer();
        var clip = new AnimationClip('nonname', -1, []);
        var animationAction = new AnimationAction(mixer, clip);
        assertTrue(animationAction != null);
    }

    public function testBlendMode() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testLoop() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testTime() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testTimeScale() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testWeight() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testRepetitions() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testPaused() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testEnabled() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testClampWhenFinished() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testZeroSlopeAtStart() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testZeroSlopeAtEnd() {
        assertFalse(true, 'everything\'s gonna be alright');
    }

    public function testPlay() {
        var { mixer, animationAction } = createAnimation();
        var animationAction2 = animationAction.play();
        assertEquals(animationAction, animationAction2);
        var UserException = function() {
            this.message = 'AnimationMixer must activate AnimationAction on play.';
        };
        mixer._activateAction = function(action) {
            if (action == animationAction) {
                throw new UserException();
            }
        };
        assertThrows(function() {
            animationAction.play();
        }, UserException);
    }

    public function testStop() {
        var { mixer, animationAction } = createAnimation();
        var animationAction2 = animationAction.stop();
        assertEquals(animationAction, animationAction2);
        var UserException = function() {
            this.message = 'AnimationMixer must deactivate AnimationAction on stop.';
        };
        mixer._deactivateAction = function(action) {
            if (action == animationAction) {
                throw new UserException();
            }
        };
        assertThrows(function() {
            animationAction.stop();
        }, UserException);
    }

    public function testReset() {
        var { animationAction } = createAnimation();
        var animationAction2 = animationAction.stop();
        assertEquals(animationAction, animationAction2);
        assertEquals(animationAction2.paused, false);
        assertEquals(animationAction2.enabled, true);
        assertEquals(animationAction2.time, 0);
        assertEquals(animationAction2._loopCount, -1);
        assertNull(animationAction2._startTime);
    }

    public function testIsRunning() {
        var { animationAction } = createAnimation();
        assertFalse(animationAction.isRunning());
        animationAction.play();
        assertTrue(animationAction.isRunning());
        animationAction.stop();
        assertFalse(animationAction.isRunning());
        animationAction.play();
        animationAction.paused = true;
        assertFalse(animationAction.isRunning());
        animationAction.paused = false;
        animationAction.enabled = false;
        assertFalse(animationAction.isRunning());
        animationAction.enabled = true;
        assertTrue(animationAction.isRunning());
    }

    public function testIsScheduled() {
        var { mixer, animationAction } = createAnimation();
        assertFalse(animationAction.isScheduled());
        animationAction.play();
        assertTrue(animationAction.isScheduled());
        mixer.update(1);
        assertTrue(animationAction.isScheduled());
        animationAction.stop();
        assertFalse(animationAction.isScheduled());
    }

    public function testStartAt() {
        var { mixer, animationAction } = createAnimation();
        animationAction.startAt(2);
        animationAction.play();
        assertFalse(animationAction.isRunning());
        assertTrue(animationAction.isScheduled());
        mixer.update(1);
        assertFalse(animationAction.isRunning());
        assertTrue(animationAction.isScheduled());
        mixer.update(1);
        assertTrue(animationAction.isRunning());
        assertTrue(animationAction.isScheduled());
        animationAction.stop();
        assertFalse(animationAction.isRunning());
        assertFalse(animationAction.isScheduled());
    }

    public function testSetLoopLoopOnce() {
        var { mixer, animationAction } = createAnimation();
        animationAction.setLoop(LoopOnce);
        animationAction.play();
        assertTrue(animationAction.isRunning());
        mixer.update(500);
        assertTrue(animationAction.isRunning());
        mixer.update(500);
        assertFalse(animationAction.isRunning());
        mixer.update(500);
        assertFalse(animationAction.isRunning());
    }

    public function testSetLoopLoopRepeat() {
        var { root, mixer, animationAction } = createAnimation();
        animationAction.setLoop(LoopRepeat, 3);
        animationAction.play();
        assertTrue(animationAction.isRunning());
        mixer.update(750);
        assertEquals(root.rotation.x, 270);
        assertTrue(animationAction.isRunning());
        mixer.update(1000);
        assertEquals(root.rotation.x, 270);
        assertTrue(animationAction.isRunning());
        mixer.update(1000);
        assertEquals(root.rotation.x, 270);
        assertTrue(animationAction.isRunning());
        mixer.update(1000);
        assertEquals(root.rotation.x, 0);
        assertFalse(animationAction.isRunning());
    }

    public function testSetLoopLoopPingPong() {
        var { root, mixer, animationAction } = createAnimation();
        animationAction.setLoop(LoopPingPong, 3);
        animationAction.play();
        assertTrue(animationAction.isRunning());
        mixer.update(750);
        assertEquals(root.rotation.x, 270);
        assertTrue(animationAction.isRunning());
        mixer.update(1000);
        assertEquals(root.rotation.x, 90);
        assertTrue(animationAction.isRunning());
        mixer.update(1000);
        assertEquals(root.rotation.x, 270);
        assertTrue(animationAction.isRunning());
        mixer.update(1000);
        assertEquals(root.rotation.x, 0);
        assertFalse(animationAction.isRunning());
    }

    public function testSetEffectiveWeight() {
        var { animationAction } = createAnimation();
        assertEquals(animationAction.getEffectiveWeight(), 1);
        animationAction.setEffectiveWeight(0.3);
        assertEquals(animationAction.getEffectiveWeight(), 0.3);
    }

    public function testSetEffectiveWeightDisabled() {
        var { animationAction } = createAnimation();
        animationAction.enabled = false;
        assertEquals(animationAction.getEffectiveWeight(), 1);
        animationAction.setEffectiveWeight(0.3);
        assertEquals(animationAction.getEffectiveWeight(), 0);
    }

    public function testSetEffectiveWeightOverDuration() {
        var { root, mixer, animationAction } = createAnimation();
        animationAction.setEffectiveWeight(0.5);
        animationAction.play();
        mixer.update(500);
        assertEquals(root.rotation.x, 90);
        mixer.update(1000);
        assertEquals(root.rotation.x, 90);
    }

    public function testGetEffectiveWeight() {
        var { animationAction } = createAnimation();
        assertEquals(animationAction.getEffectiveWeight(), 1);
        animationAction.setEffectiveWeight(0.3);
        assertEquals(animationAction.getEffectiveWeight(), 0.3);
        ( { animationAction } = createAnimation() );
        animationAction.enabled = false;
        assertEquals(animationAction.getEffectiveWeight(), 1);
        animationAction.setEffectiveWeight(0.3);
        assertEquals(animationAction.getEffectiveWeight(), 0);
    }

    public function testFadeIn() {
        var { mixer, animationAction } = createAnimation();
        animationAction.fadeIn(1000);
        animationAction.play();
        assertEquals(animationAction.getEffectiveWeight(), 1);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.25);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.5);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.75);
        mixer.update(500);
        assertEquals(animationAction.getEffectiveWeight(), 1);
    }

    public function testFadeOut() {
        var { mixer, animationAction } = createAnimation();
        animationAction.fadeOut(1000);
        animationAction.play();
        assertEquals(animationAction.getEffectiveWeight(), 1);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.75);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.5);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.25);
        mixer.update(500);
        assertEquals(animationAction.getEffectiveWeight(), 0);
    }

    public function testCrossFadeFrom() {
        var { mixer, animationAction, animationAction2 } = createTwoAnimations();
        animationAction.crossFadeFrom(animationAction2, 1000, false);
        animationAction.play();
        animationAction2.play();
        assertEquals(animationAction.getEffectiveWeight(), 1);
        assertEquals(animationAction2.getEffectiveWeight(), 1);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.25);
        assertEquals(animationAction2.getEffectiveWeight(), 0.75);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.5);
        assertEquals(animationAction2.getEffectiveWeight(), 0.5);
        mixer.update(250);
        assertEquals(animationAction.getEffectiveWeight(), 0.75);
        assertEquals(animationAction2.getEffective