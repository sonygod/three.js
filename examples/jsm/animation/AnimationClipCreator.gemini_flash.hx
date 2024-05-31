import three.AnimationClip;
import three.BooleanKeyframeTrack;
import three.ColorKeyframeTrack;
import three.NumberKeyframeTrack;
import three.Vector3;
import three.VectorKeyframeTrack;

class AnimationClipCreator {

    public static function CreateRotationAnimation(period:Float, axis:String = 'x'):AnimationClip {

        var times = [0, period];
        var values = [0, 360];

        var trackName = '.rotation[' + axis + ']';

        var track = new NumberKeyframeTrack(trackName, times, values);

        return new AnimationClip(null, period, [track]);

    }

    public static function CreateScaleAxisAnimation(period:Float, axis:String = 'x'):AnimationClip {

        var times = [0, period];
        var values = [0, 1];

        var trackName = '.scale[' + axis + ']';

        var track = new NumberKeyframeTrack(trackName, times, values);

        return new AnimationClip(null, period, [track]);

    }

    public static function CreateShakeAnimation(duration:Float, shakeScale:Float):AnimationClip {

        var times = [];
        var values = [];
        var tmp = new Vector3();

        for (i in 0...Std.int(duration * 10)) {

            times.push(i / 10);

            tmp.set(Math.random() * 2.0 - 1.0, Math.random() * 2.0 - 1.0, Math.random() * 2.0 - 1.0)
                .multiplyScalar(shakeScale)
                .toArray(values, values.length);

        }

        var trackName = '.position';

        var track = new VectorKeyframeTrack(trackName, times, values);

        return new AnimationClip(null, duration, [track]);

    }

    public static function CreatePulsationAnimation(duration:Float, pulseScale:Float):AnimationClip {

        var times = [];
        var values = [];
        var tmp = new Vector3();

        for (i in 0...Std.int(duration * 10)) {

            times.push(i / 10);

            var scaleFactor = Math.random() * pulseScale;
            tmp.set(scaleFactor, scaleFactor, scaleFactor)
                .toArray(values, values.length);

        }

        var trackName = '.scale';

        var track = new VectorKeyframeTrack(trackName, times, values);

        return new AnimationClip(null, duration, [track]);

    }

    public static function CreateVisibilityAnimation(duration:Float):AnimationClip {

        var times = [0, duration / 2, duration];
        var values = [true, false, true];

        var trackName = '.visible';

        var track = new BooleanKeyframeTrack(trackName, times, values);

        return new AnimationClip(null, duration, [track]);

    }

    public static function CreateMaterialColorAnimation(duration:Float, colors:Array<Vector3>):AnimationClip {

        var times = [];
        var values = [];
        var timeStep = duration / colors.length;

        for (i in 0...colors.length) {

            times.push(i * timeStep);

            var color = colors[i];
            values.push(color.x, color.y, color.z);

        }

        var trackName = '.material.color';

        var track = new ColorKeyframeTrack(trackName, times, values);

        return new AnimationClip(null, duration, [track]);

    }

}