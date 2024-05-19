import hxmath.Quaternion;
import three.constants.AdditiveAnimationBlendMode;

// converts an array to a specific type
function convertArray<T>(array:Array<T>, type:Class<T>, forceClone:Bool):Array<T> {

	if (!array || // let 'undefined' and 'null' pass
		!forceClone && Type.getClass(array) == type) return array;

	if (Type.getClass(type).BYTES_PER_ELEMENT != null) {

		return new type(array); // create typed array

	}

	return array.copy(); // create Array

}

function isTypedArray(object:Dynamic):Bool {

	return js.lib.ArrayBuffer.isView(object) &&
		!Std.is(object, js.html.ArrayBufferView);

}

// returns an array by which times and values can be sorted
function getKeyframeOrder(times:Array<Float>):Array<Int> {

	function compareTime(i:Int, j:Int):Int {

		return Std.int(times[i] - times[j]);

	}

	final n = times.length;
	final result = new Array(n);
	for (i in 0...n) result[i] = i;

	result.sort(compareTime);

	return result;

}

// uses the array previously returned by 'getKeyframeOrder' to sort data
function sortedArray<T>(values:Array<T>, stride:Int, order:Array<Int>):Array<T> {

	final nValues = values.length;
	final result = new Array(nValues);

	for (i in 0...nValues) {

		final srcOffset = order[i] * stride;

		for (j in 0...stride) {

			result[dstOffset++] = values[srcOffset + j];

		}

	}

	return result;

}

// function for parsing AOS keyframe formats
function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Float>, valuePropertyName:String) {

	var i = 1;
	var key = jsonKeys[0];

	while (key != null && key[valuePropertyName] == null) {

		key = jsonKeys[i++];

	}

	if (key == null) return; // no data

	var value = key[valuePropertyName];
	if (value == null) return; // no data

	if (js.Lib.isArray(value)) {

		do {

			value = key[valuePropertyName];

			if (value != null) {

				times.push(key.time);
				values.push(value);

			}

			key = jsonKeys[i++];

		} while (key != null);

	} else if (Reflect.hasField(value, "toArray")) {

		// ...assume THREE.Math-ish

		do {

			value = key[valuePropertyName];

			if (value != null) {

				times.push(key.time);
				Reflect.callMethod(value, "toArray", [values, values.length]);

			}

			key = jsonKeys[i++];

		} while (key != null);

	} else {

		// otherwise push as-is

		do {

			value = key[valuePropertyName];

			if (value != null) {

				times.push(key.time);
				values.push(value);

			}

			key = jsonKeys[i++];

		} while (key != null);

	}

}

function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, ?fps:Int = 30):Dynamic {

	final clip = sourceClip.clone();

	clip.name = name;

	final tracks:Array<Dynamic> = [];

	for (i in 0...clip.tracks.length) {

		final track = clip.tracks[i];
		final valueSize = track.getValueSize();

		final times:Array<Float> = [];
		final values:Array<Float> = [];

		for (j in 0...track.times.length) {

			final frame = track.times[j] * fps;

			if (frame < startFrame || frame >= endFrame) continue;

			times.push(track.times[j]);

			for (k in 0...valueSize) {

				values.push(track.values[j * valueSize + k]);

			}

		}

		if (times.length == 0) continue;

		track.times = convertArray(times, Type.getClass(track.times));
		track.values = convertArray(values, Type.getClass(track.values));

		tracks.push(track);

	}

	clip.tracks = tracks;

	// find minimum .times value across all tracks in the trimmed clip

	var minStartTime = Math.POSITIVE_INFINITY;

	for (i in 0...clip.tracks.length) {

		if (minStartTime > clip.tracks[i].times[0]) {

			minStartTime = clip.tracks[i].times[0];

		}

	}

	// shift all tracks such that clip begins at t=0

	for (i in 0...clip.tracks.length) {

		clip.tracks[i].shift(-1 * minStartTime);

	}

	clip.resetDuration();

	return clip;

}

function makeClipAdditive(targetClip:Dynamic, ?referenceFrame:Int = 0, ?referenceClip:Dynamic = targetClip, ?fps:Int = 30):Dynamic {

	if (fps <= 0) fps = 30;

	final numTracks = referenceClip.tracks.length;
	final referenceTime = referenceFrame / fps;

	// Make each track's values relative to the values at the reference frame
	for (i in 0...numTracks) {

		final referenceTrack = referenceClip.tracks[i];
		final referenceTrackType = referenceTrack.ValueTypeName;

		// Skip this track if it's non-numeric
		if (referenceTrackType == 'bool' || referenceTrackType == 'string') continue;

		// Find the track in the target clip whose name and type matches the reference track
		final targetTrack = targetClip.tracks.find((track) -> {

			return track.name == referenceTrack.name
				&& track.ValueTypeName == referenceTrackType;

		});

		if (targetTrack == null) continue;

		var referenceOffset = 0;
		final referenceValueSize = referenceTrack.getValueSize();

		final lastIndex = referenceTrack.times.length - 1;
		var referenceValue;

		// Find the value to subtract out of the track
		if (referenceTime <= referenceTrack.times[0]) {

			// Reference frame is earlier than the first keyframe, so just use the first keyframe
			const startIndex = referenceOffset;
			const endIndex = referenceValueSize - referenceOffset;
			referenceValue = referenceTrack.values.slice(startIndex, endIndex);

		} else if (referenceTime >= referenceTrack.times[lastIndex]) {

			// Reference frame is after the last keyframe, so just use the last keyframe
			const startIndex = lastIndex * referenceValueSize + referenceOffset;
			const endIndex = startIndex + referenceValueSize - referenceOffset;
			referenceValue = referenceTrack.values.slice(startIndex, endIndex);

		} else {

			// Interpolate to the reference value
			const interpolant = referenceTrack.createInterpolant();
			const startIndex = referenceOffset;
			const endIndex = referenceValueSize - referenceOffset;
			interpolant.evaluate(referenceTime);
			referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);

		}

		// Conjugate the quaternion
		if (referenceTrackType == 'quaternion') {

			final referenceQuat = new Quaternion().fromArray(referenceValue).normalize().conjugate();
			referenceQuat.toArray(referenceValue);

		}

		// Subtract the reference value from all of the track values

		const numTimes = targetTrack.times.length;
		for (j in 0...numTimes) {

			const valueStart = j * targetTrack.getValueSize();

			if (referenceTrackType == 'quaternion') {

				// Multiply the conjugate for quaternion track types
				Quaternion.multiplyQuaternionsFlat(
					targetTrack.values,
					valueStart,
					referenceValue,
					0,
					targetTrack.values,
					valueStart
				);

			} else {

				const valueEnd = targetTrack.getValueSize();

				// Subtract each value for all other numeric track types
				for (k in 0...valueEnd) {

					targetTrack.values[valueStart + k] -= referenceValue[k];

				}

			}

		}

	}

	targetClip.blendMode = AdditiveAnimationBlendMode;

	return targetClip;

}

class AnimationUtils {
	public static function convertArray<T>(array:Array<T>, type:Class<T>, forceClone:Bool):Array<T> {
		return convertArray(array, type, forceClone);
	}

	public static function isTypedArray(object:Dynamic):Bool {
		return isTypedArray(object);
	}

	public static function getKeyframeOrder(times:Array<Float>):Array<Int> {
		return getKeyframeOrder(times);
	}

	public static function sortedArray<T>(values:Array<T>, stride:Int, order:Array<Int>):Array<T> {
		return sortedArray(values, stride, order);
	}

	public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Float>, valuePropertyName:String):Void {
		flattenJSON(jsonKeys, times, values, valuePropertyName);
	}

	public static function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, ?fps:Int = 30):Dynamic {
		return subclip(sourceClip, name, startFrame, endFrame, fps);
	}

	public static function makeClipAdditive(targetClip:Dynamic, ?referenceFrame:Int = 0, ?referenceClip:Dynamic = targetClip, ?fps:Int = 30):Dynamic {
		return makeClipAdditive(targetClip, referenceFrame, referenceClip, fps);
	}
}