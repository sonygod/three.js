package three.js.test.unit.src.animation;

import three.js.src.animation.AnimationMixer;
import three.js.src.core.EventDispatcher;
import three.js.src.animation.AnimationClip;
import three.js.src.animation.tracks.VectorKeyframeTrack;
import three.js.src.core.Object3D;
import three.js.utils.math_constants.zero3;
import three.js.utils.math_constants.one3;
import three.js.utils.math_constants.two3;

class AnimationMixerTests {

    static function getClips(pos1:Dynamic, pos2:Dynamic, scale1:Dynamic, scale2:Dynamic, dur:Float):Array<AnimationClip> {

        var clips = [];

        var track = new VectorKeyframeTrack('.scale', [0, dur], [scale1.x, scale1.y, scale1.z, scale2.x, scale2.y, scale2.z]);
        clips.push(new AnimationClip('scale', dur, [track]));

        track = new VectorKeyframeTrack('.position', [0, dur], [pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z]);
        clips.push(new AnimationClip('position', dur, [track]));

        return clips;

    }

    public static function main():Void {

        // INHERITANCE
        var object = new AnimationMixer();
        trace((object instanceof EventDispatcher), 'AnimationMixer extends from EventDispatcher');

        // INSTANCING
        var object = new AnimationMixer();
        trace(object != null, 'Can instantiate a AnimationMixer.');

        // PROPERTIES
        // TODO: time
        // TODO: timeScale

        // PUBLIC
        // TODO: clipAction
        // TODO: existingAction

        var obj = new Object3D();
        var animMixer = new AnimationMixer(obj);
        var clips = getClips(zero3, one3, two3, one3, 1);
        var actionA = animMixer.clipAction(clips[0]);
        var actionB = animMixer.clipAction(clips[1]);

        actionA.play();
        actionB.play();
        animMixer.update(0.1);
        animMixer.stopAllAction();

        trace(!actionA.isRunning() && !actionB.isRunning(), 'All actions stopped');
        trace(obj.position.x == 0 && obj.position.y == 0 && obj.position.z == 0, 'Position reset as expected');
        trace(obj.scale.x == 1 && obj.scale.y == 1 && obj.scale.z == 1, 'Scale reset as expected');

        // TODO: update
        // TODO: setTime

        trace(obj == animMixer.getRoot(), 'Get original root object');

        // TODO: uncacheClip
        // TODO: uncacheRoot
        // TODO: uncacheAction

    }

}