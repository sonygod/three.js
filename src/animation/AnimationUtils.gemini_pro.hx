import js.lib.Array;
import js.html.DataView;
import js.lib.ArrayBuffer;
import js.lib.Float32Array;
import js.lib.Float64Array;
import js.lib.Int8Array;
import js.lib.Int16Array;
import js.lib.Int32Array;
import js.lib.Uint8Array;
import js.lib.Uint16Array;
import js.lib.Uint32Array;
import js.lib.Uint8ClampedArray;
import js.html.Quaternion;
import js.lib.Math;

class AnimationUtils {

	static function convertArray<T>(array:Array<T>, type:Dynamic, forceClone:Bool):Array<T> {

		if (array == null || (!forceClone && array.constructor == type)) {
			return array;
		}

		if (Reflect.hasField(type, "BYTES_PER_ELEMENT")) {
			return Type.createInstance(type, [array]);
		}

		return Array.prototype.slice.call(array);
	}

	static function isTypedArray(object:Dynamic):Bool {

		return ArrayBuffer.isView(object) && !(object is DataView);
	}

	static function getKeyframeOrder(times:Array<Float>):Array<Int> {

		function compareTime(i:Int, j:Int):Int {
			return times[i] - times[j];
		}

		var n = times.length;
		var result = new Array<Int>(n);
		for (i in 0...n) result[i] = i;
		result.sort(compareTime);
		return result;
	}

	static function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>):Array<Dynamic> {

		var nValues = values.length;
		var result = new values.constructor(nValues);

		var dstOffset = 0;
		for (i in 0...order.length) {

			var srcOffset = order[i] * stride;
			for (j in 0...stride) {
				result[dstOffset++] = values[srcOffset + j];
			}
		}
		return result;
	}

	static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String) {

		var i = 1;
		var key = jsonKeys[0];
		while (key != null && Reflect.field(key, valuePropertyName) == null) {
			key = jsonKeys[i++];
		}
		if (key == null) {
			return;
		}
		var value = Reflect.field(key, valuePropertyName);
		if (value == null) {
			return;
		}
		if (Array.isOf(value)) {
			do {
				value = Reflect.field(key, valuePropertyName);
				if (value != null) {
					times.push(Reflect.field(key, "time"));
					values.push(value);
				}
				key = jsonKeys[i++];
			} while (key != null);
		} else if (Reflect.hasField(value, "toArray")) {

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

	static function subclip(sourceClip:Dynamic, name:String, startFrame:Float, endFrame:Float, fps:Float = 30.0):Dynamic {

		var clip = sourceClip.clone();
		clip.name = name;
		var tracks = new Array<Dynamic>();

		for (i in 0...clip.tracks.length) {
			var track = clip.tracks[i];
			var valueSize = track.getValueSize();
			var times = new Array<Float>();
			var values = new Array<Dynamic>();

			for (j in 0...track.times.length) {
				var frame = track.times[j] * fps;
				if (frame < startFrame || frame >= endFrame) continue;
				times.push(track.times[j]);
				for (k in 0...valueSize) {
					values.push(track.values[j * valueSize + k]);
				}
			}
			if (times.length == 0) continue;
			track.times = convertArray(times, track.times.constructor, true);
			track.values = convertArray(values, track.values.constructor, true);
			tracks.push(track);
		}
		clip.tracks = tracks;

		var minStartTime = Math.POSITIVE_INFINITY;
		for (i in 0...clip.tracks.length) {
			if (minStartTime > clip.tracks[i].times[0]) minStartTime = clip.tracks[i].times[0];
		}

		for (i in 0...clip.tracks.length) {
			clip.tracks[i].shift(-minStartTime);
		}
		clip.resetDuration();
		return clip;
	}

	static function makeClipAdditive(targetClip:Dynamic, referenceFrame:Float = 0, referenceClip:Dynamic = targetClip, fps:Float = 30.0):Dynamic {

		if (fps <= 0) fps = 30.0;
		var numTracks = referenceClip.tracks.length;
		var referenceTime = referenceFrame / fps;

		for (i in 0...numTracks) {

			var referenceTrack = referenceClip.tracks[i];
			var referenceTrackType = referenceTrack.ValueTypeName;
			if (referenceTrackType == "bool" || referenceTrackType == "string") continue;

			var targetTrack = targetClip.tracks.find(function(track:Dynamic) {
				return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
			});
			if (targetTrack == null) continue;

			var referenceOffset = 0;
			var referenceValueSize = referenceTrack.getValueSize();

			var targetOffset = 0;
			var targetValueSize = targetTrack.getValueSize();
			var lastIndex = referenceTrack.times.length - 1;
			var referenceValue:Dynamic;

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
		targetClip.blendMode = "AdditiveAnimationBlendMode";
		return targetClip;
	}
}