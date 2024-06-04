import three.animation.AnimationClip;
import three.animation.tracks.BooleanKeyframeTrack;
import three.animation.tracks.ColorKeyframeTrack;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.tracks.VectorKeyframeTrack;
import three.math.Vector3;

class AnimationClipCreator {

	static function CreateRotationAnimation(period:Float, axis:String = "x"):AnimationClip {

		var times:Array<Float> = [0, period];
		var values:Array<Float> = [0, 360];

		var trackName = ".rotation[" + axis + "]";

		var track = new NumberKeyframeTrack(trackName, times, values);

		return new AnimationClip(null, period, [track]);

	}

	static function CreateScaleAxisAnimation(period:Float, axis:String = "x"):AnimationClip {

		var times:Array<Float> = [0, period];
		var values:Array<Float> = [0, 1];

		var trackName = ".scale[" + axis + "]";

		var track = new NumberKeyframeTrack(trackName, times, values);

		return new AnimationClip(null, period, [track]);

	}

	static function CreateShakeAnimation(duration:Float, shakeScale:Float):AnimationClip {

		var times:Array<Float> = [];
		var values:Array<Float> = [];
		var tmp = new Vector3();

		for (i in 0...duration * 10) {

			times.push(i / 10);

			tmp.set(Math.random() * 2.0 - 1.0, Math.random() * 2.0 - 1.0, Math.random() * 2.0 - 1.0).
				multiply(shakeScale).
				toArray(values, values.length);

		}

		var trackName = ".position";

		var track = new VectorKeyframeTrack(trackName, times, values);

		return new AnimationClip(null, duration, [track]);

	}

	static function CreatePulsationAnimation(duration:Float, pulseScale:Float):AnimationClip {

		var times:Array<Float> = [];
		var values:Array<Float> = [];
		var tmp = new Vector3();

		for (i in 0...duration * 10) {

			times.push(i / 10);

			var scaleFactor = Math.random() * pulseScale;
			tmp.set(scaleFactor, scaleFactor, scaleFactor).
				toArray(values, values.length);

		}

		var trackName = ".scale";

		var track = new VectorKeyframeTrack(trackName, times, values);

		return new AnimationClip(null, duration, [track]);

	}

	static function CreateVisibilityAnimation(duration:Float):AnimationClip {

		var times:Array<Float> = [0, duration / 2, duration];
		var values:Array<Bool> = [true, false, true];

		var trackName = ".visible";

		var track = new BooleanKeyframeTrack(trackName, times, values);

		return new AnimationClip(null, duration, [track]);

	}

	static function CreateMaterialColorAnimation(duration:Float, colors:Array<three.math.Color>):AnimationClip {

		var times:Array<Float> = [];
		var values:Array<Float> = [];
		var timeStep = duration / colors.length;

		for (i in 0...colors.length) {

			times.push(i * timeStep);

			var color = colors[i];
			values.push(color.r, color.g, color.b);

		}

		var trackName = ".material.color";

		var track = new ColorKeyframeTrack(trackName, times, values);

		return new AnimationClip(null, duration, [track]);

	}

}