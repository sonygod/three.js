import three.math.Quaternion;
import three.constants.AdditiveAnimationBlendMode;

class AnimationUtils {

	public static function convertArray<T>(array:Array<Dynamic>, type:Class<T>, forceClone:Bool = false):Array<Dynamic> {
		if (array == null || (!forceClone && array.getClass() == type)) return array;
		if (Reflect.field(type, "BYTES_PER_ELEMENT") != null) return Type.createInstance(type, [array]);
		return Array.prototype.slice.call(array);
	}

	public static function isTypedArray(object:Dynamic):Bool {
		return Reflect.isFunction(object.buffer) && !Reflect.isFunction(object.byteLength);
	}

	public static function getKeyframeOrder(times:Array<Float>):Array<Int> {
		function compareTime(i:Int, j:Int):Int {
			return times[i] - times[j];
		}
		var n = times.length;
		var result = new Array<Int>(n);
		for (i in 0...n) result[i] = i;
		result.sort(compareTime);
		return result;
	}

	public static function sortedArray<T>(values:Array<T>, stride:Int, order:Array<Int>):Array<T> {
		var nValues = values.length;
		var result = new values.getClass()(nValues);
		for (i in 0...nValues) {
			var srcOffset = order[i] * stride;
			for (j in 0...stride) {
				result[i] = values[srcOffset + j];
			}
		}
		return result;
	}

	public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Float>, valuePropertyName:String):Void {
		var i = 1;
		var key = jsonKeys[0];
		while (key != null && Reflect.field(key, valuePropertyName) == null) {
			key = jsonKeys[i++];
		}
		if (key == null) return;
		var value = Reflect.field(key, valuePropertyName);
		if (value == null) return;
		if (Reflect.isFunction(value.toArray)) {
			do {
				value = Reflect.field(key, valuePropertyName);
				if (value != null) {
					times.push(Reflect.field(key, "time"));
					value.toArray(values, values.length);
				}
				key = jsonKeys[i++];
			} while (key != null);
		} else if (Reflect.isFunction(value.length)) {
			do {
				value = Reflect.field(key, valuePropertyName);
				if (value != null) {
					times.push(Reflect.field(key, "time"));
					values.push(value);
				}
				key = jsonKeys[i++];
			} while (key != null);
		} else {
			do {
				value = Reflect.field(key, valuePropertyName);
				if (value != null) {
					times.push(Reflect.field(key, "time"));
					values.push(value);
				}
				key = jsonKeys[i++];
			} while (key != null);
		}
	}

	public static function subclip(sourceClip:Dynamic, name:String, startFrame:Float, endFrame:Float, fps:Float = 30.):Dynamic {
		var clip = sourceClip.clone();
		clip.name = name;
		var tracks = new Array<Dynamic>();
		for (i in 0...clip.tracks.length) {
			var track = clip.tracks[i];
			var valueSize = track.getValueSize();
			var times = new Array<Float>();
			var values = new Array<Float>();
			for (j in 0...track.times.length) {
				var frame = track.times[j] * fps;
				if (frame < startFrame || frame >= endFrame) continue;
				times.push(track.times[j]);
				for (k in 0...valueSize) {
					values.push(track.values[j * valueSize + k]);
				}
			}
			if (times.length == 0) continue;
			track.times = convertArray(times, track.times.getClass());
			track.values = convertArray(values, track.values.getClass());
			tracks.push(track);
		}
		clip.tracks = tracks;
		var minStartTime = Math.POSITIVE_INFINITY;
		for (i in 0...clip.tracks.length) {
			if (minStartTime > clip.tracks[i].times[0]) {
				minStartTime = clip.tracks[i].times[0];
			}
		}
		for (i in 0...clip.tracks.length) {
			clip.tracks[i].shift(-1 * minStartTime);
		}
		clip.resetDuration();
		return clip;
	}

	public static function makeClipAdditive(targetClip:Dynamic, referenceFrame:Float = 0, referenceClip:Dynamic = null, fps:Float = 30):Dynamic {
		if (fps <= 0) fps = 30;
		var numTracks = referenceClip.tracks.length;
		var referenceTime = referenceFrame / fps;
		for (i in 0...numTracks) {
			var referenceTrack = referenceClip.tracks[i];
			var referenceTrackType = referenceTrack.ValueTypeName;
			if (referenceTrackType == "bool" || referenceTrackType == "string") continue;
			var targetTrack = targetClip.tracks.find(function(track:Dynamic):Bool {
				return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
			});
			if (targetTrack == null) continue;
			var referenceOffset = 0;
			var referenceValueSize = referenceTrack.getValueSize();
			if (Reflect.isFunction(referenceTrack.createInterpolant) && Reflect.field(referenceTrack.createInterpolant, "isInterpolantFactoryMethodGLTFCubicSpline") != null) {
				referenceOffset = referenceValueSize / 3;
			}
			var targetOffset = 0;
			var targetValueSize = targetTrack.getValueSize();
			if (Reflect.isFunction(targetTrack.createInterpolant) && Reflect.field(targetTrack.createInterpolant, "isInterpolantFactoryMethodGLTFCubicSpline") != null) {
				targetOffset = targetValueSize / 3;
			}
			var lastIndex = referenceTrack.times.length - 1;
			var referenceValue:Array<Float>;
			if (referenceTime <= referenceTrack.times[0]) {
				var startIndex = referenceOffset;
				var endIndex = referenceValueSize - referenceOffset;
				referenceValue = referenceTrack.values.slice(startIndex, endIndex);
			} else if (referenceTime >= referenceTrack.times[lastIndex]) {
				var startIndex = lastIndex * referenceValueSize + referenceOffset;
				var endIndex = startIndex + referenceValueSize - referenceOffset;
				referenceValue = referenceTrack.values.slice(startIndex, endIndex);
			} else {
				var interpolant = referenceTrack.createInterpolant();
				var startIndex = referenceOffset;
				var endIndex = referenceValueSize - referenceOffset;
				interpolant.evaluate(referenceTime);
				referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);
			}
			if (referenceTrackType == "quaternion") {
				var referenceQuat = new Quaternion().fromArray(referenceValue).normalize().conjugate();
				referenceQuat.toArray(referenceValue);
			}
			var numTimes = targetTrack.times.length;
			for (j in 0...numTimes) {
				var valueStart = j * targetValueSize + targetOffset;
				if (referenceTrackType == "quaternion") {
					Quaternion.multiplyQuaternionsFlat(targetTrack.values, valueStart, referenceValue, 0, targetTrack.values, valueStart);
				} else {
					var valueEnd = targetValueSize - targetOffset * 2;
					for (k in 0...valueEnd) {
						targetTrack.values[valueStart + k] -= referenceValue[k];
					}
				}
			}
		}
		targetClip.blendMode = AdditiveAnimationBlendMode;
		return targetClip;
	}

}