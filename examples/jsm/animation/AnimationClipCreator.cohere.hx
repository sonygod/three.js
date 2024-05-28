import js.three.AnimationClip;
import js.three.KeyframeTrack;
import js.three.NumberKeyframeTrack;
import js.three.VectorKeyframeTrack;
import js.three.BooleanKeyframeTrack;
import js.three.ColorKeyframeTrack;

class AnimationClipCreator {

	public static function CreateRotationAnimation( period:Float, axis:String = "x" ):AnimationClip {
		var times = [0, period];
		var values = [0, 360];
		var trackName = ".rotation[" + axis + "]";
		var track = new NumberKeyframeTrack(trackName, times, values);
		return new AnimationClip(null, period, [track]);
	}

	public static function CreateScaleAxisAnimation( period:Float, axis:String = "x" ):AnimationClip {
		var times = [0, period];
		var values = [0, 1];
		var trackName = ".scale[" + axis + "]";
		var track = new NumberKeyframeTrack(trackName, times, values);
		return new AnimationClip(null, period, [track]);
	}

	public static function CreateShakeAnimation( duration:Float, shakeScale:Float ):AnimationClip {
		var times = [];
		var values = [];
		var tmp = new js.three.Vector3();
		var i:Int;
		for (i = 0; i < duration * 10; i++) {
			times.push(i / 10);
			tmp.set(Std.random() * 2.0 - 1.0, Std.random() * 2.0 - 1.0, Std.random() * 2.0 - 1.0);
			tmp.multiply(shakeScale);
			values.push(tmp.x, tmp.y, tmp.z);
		}
		var trackName = ".position";
		var track = new VectorKeyframeTrack(trackName, times, values);
		return new AnimationClip(null, duration, [track]);
	}

	public static function CreatePulsationAnimation( duration:Float, pulseScale:Float ):AnimationClip {
		var times = [];
		var values = [];
		var tmp = new js.three.Vector3();
		var i:Int;
		for (i = 0; i < duration * 10; i++) {
			times.push(i / 10);
			var scaleFactor = Std.random() * pulseScale;
			tmp.set(scaleFactor, scaleFactor, scaleFactor);
			values.push(tmp.x, tmp.y, tmp.z);
		}
		var trackName = ".scale";
		var track = new VectorKeyframeTrack(trackName, times, values);
		return new AnimationClip(null, duration, [track]);
	}

	public static function CreateVisibilityAnimation( duration:Float ):AnimationClip {
		var times = [0, duration / 2, duration];
		var values = [true, false, true];
		var trackName = ".visible";
		var track = new BooleanKeyframeTrack(trackName, times, values);
		return new AnimationClip(null, duration, [track]);
	}

	public static function CreateMaterialColorAnimation( duration:Float, colors:Array<js.three.Color> ):AnimationClip {
		var times = [];
		var values = [];
		var timeStep = duration / colors.length;
		var i:Int;
		for (i = 0; i < colors.length; i++) {
			times.push(i * timeStep);
			var color = colors[i];
			values.push(color.r, color.g, color.b);
		}
		var trackName = ".material.color";
		var track = new ColorKeyframeTrack(trackName, times, values);
		return new AnimationClip(null, duration, [track]);
	}

}

class js.three.AnimationClip {
	public function new( name:String, duration:Float, tracks:Array<KeyframeTrack> ) {
		this.name = name;
		this.duration = duration;
		this.tracks = tracks;
	}
}

class js.three.KeyframeTrack {
	public var times:Array<Float>;
	public var values:Dynamic;
}

class js.three.NumberKeyframeTrack extends KeyframeTrack {
	public function new( name:String, times:Array<Float>, values:Array<Float> ) {
		super(name, times, values);
	}
}

class js.three.VectorKeyframeTrack extends KeyframeTrack {
	public function new( name:String, times:Array<Float>, values:Array<Float> ) {
		super(name, times, values);
	}
}

class js.three.BooleanKeyframeTrack extends KeyframeTrack {
	public function new( name:String, times:Array<Float>, values:Array<Bool> ) {
		super(name, times, values);
	}
}

class js.three.ColorKeyframeTrack extends KeyframeTrack {
	public function new( name:String, times:Array<Float>, values:Array<Float> ) {
		super(name, times, values);
	}
}