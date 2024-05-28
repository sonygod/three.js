import js.js_math.Quaternion;
import js.openfl.constants.AdditiveAnimationBlendMode;

function convertArray(array:Array<Dynamic>, type:Array<Dynamic>, forceClone:Bool) : Array<Dynamic> {
	if (array == null || !forceClone && array.constructor == type)
		return array;

	if (Reflect.hasField(type, "BYTES_PER_ELEMENT")) {
		return Type.createInstance(type, [array]);
	}

	return Array.ofArray(array);
}

function isTypedArray(object:Dynamic) : Bool {
	return js.ArrayBuffer.isView(object) && !(object instanceof js.DataView);
}

function getKeyframeOrder(times:Array<Float>) : Array<Int> {
	function compareTime(i:Int, j:Int) : Int {
		return times[i] - times[j];
	}

	var n = times.length;
	var result = new Array<Int>(n);
	for (i in 0...n)
		result[i] = i;

	result.sort(compareTime);

	return result;
}

function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>) : Array<Dynamic> {
	var nValues = values.length;
	var result = new values.constructor(nValues);

	var i = 0, dstOffset = 0;
	while (dstOffset < nValues) {
		var srcOffset = order[i] * stride;

		var j = 0;
		while (j < stride) {
			result[dstOffset++] = values[srcOffset + j++];
		}

		i++;
	}

	return result;
}

function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String) : Void {
	var i = 1, key = jsonKeys[0];

	while (key != null && Reflect.field(key, valuePropertyName) == null) {
		key = jsonKeys[i++];
	}

	if (key == null)
		return;

	var value = Reflect.field(key, valuePropertyName);
	if (value == null)
		return;

	if (Type.enumIndex(value) != null) {
		while (key != null) {
			value = Reflect.field(key, valuePropertyName);

			if (value != null) {
				times.push(key.time);
				values.pushAll(value);
			}

			key = jsonKeys[i++];
		}
	} else if (Reflect.hasField(value, "toArray")) {
		// ...assume THREE.Math-ish
		while (key != null) {
			value = Reflect.field(key, valuePropertyName);

			if (value != null) {
				times.push(key.time);
				value.toArray(values, values.length);
			}

			key = jsonKeys[i++];
		}
	} else {
		// otherwise push as-is
		while (key != null) {
			value = Reflect.field(key, valuePropertyName);

			if (value != null) {
				times.push(key.time);
				values.push(value);
			}

			key = jsonKeys[i++];
		}
	}
}

function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, fps:Int = 30) : Dynamic {
	var clip = sourceClip.clone();

	clip.name = name;

	var tracks = [];

	var i = 0;
	while (i < clip.tracks.length) {
		var track = clip.tracks[i];
		var valueSize = track.getValueSize();

		var times = [];
		var values = [];

		var j = 0;
		while (j < track.times.length) {
			var frame = Std.int(track.times[j] * fps);

			if (frame < startFrame || frame >= endFrame) {
				j++;
				continue;
			}

			times.push(track.times[j]);

			var k = 0;
			while (k < valueSize) {
				values.push(track.values[j * valueSize + k]);
				k++;
			}

			j++;
		}

		if (times.length == 0) {
			i++;
			continue;
		}

		track.times = convertArray(times, track.times.constructor);
		track.values = convertArray(values, track.values.constructor);

		tracks.push(track);

		i++;
	}

	clip.tracks = tracks;

	// find minimum .times value across all tracks in the trimmed clip

	var minStartTime = Float.POSITIVE_INFINITY;

	i = 0;
	while (i < clip.tracks.length) {
		if (minStartTime > clip.tracks[i].times[0]) {
			minStartTime = clip.tracks[i].times[0];
		}

		i++;
	}

	// shift all tracks such that clip begins at t=0

	i = 0;
	while (i < clip.tracks.length) {
		clip.tracks[i].shift(-minStartTime);

		i++;
	}

	clip.resetDuration();

	return clip;
}

function makeClipAdditive(targetClip:Dynamic, referenceFrame:Int = 0, referenceClip:Dynamic = targetClip, fps:Int = 30) : Dynamic {
	if (fps <= 0)
		fps = 30;

	var numTracks = referenceClip.tracks.length;
	var referenceTime = referenceFrame / fps;

	// Make each track's values relative to the values at the reference frame
	var i = 0;
	while (i < numTracks) {
		var referenceTrack = referenceClip.tracks[i];
		var referenceTrackType = referenceTrack.ValueTypeName;

		// Skip this track if it's non-numeric
		if (referenceTrackType == "bool" || referenceTrackType == "string") {
			i++;
			continue;
		}

		// Find the track in the target clip whose name and type matches the reference track
		var targetTrack = targetClip.tracks.find(function(track:Dynamic) {
			return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
		});

		if (targetTrack == null) {
			i++;
			continue;
		}

		var referenceOffset = 0;
		var referenceValueSize = referenceTrack.getValueSize();

		if (referenceTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
			referenceOffset = referenceValueSize / 3;
		}

		var targetOffset = 0;
		var targetValueSize = targetTrack.getValueSize();

		if (targetTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
			targetOffset = targetValueSize / 3;
		}

		var lastIndex = referenceTrack.times.length - 1;
		var referenceValue:Array<Float>;

		// Find the value to subtract out of the track
		if (referenceTime <= referenceTrack.times[0]) {
			// Reference frame is earlier than the first keyframe, so just use the first keyframe
			var startIndex = referenceOffset;
			var endIndex = referenceValueSize - referenceOffset;
			referenceValue = referenceTrack.values.slice(startIndex, endIndex);
		} else if (referenceTime >= referenceTrack.times[lastIndex]) {
			// Reference frame is after the last keyframe, so just use the last keyframe
			var startIndex = lastIndex * referenceValueSize + referenceOffset;
			var endIndex = startIndex + referenceValueSize - referenceOffset;
			referenceValue = referenceTrack.values.slice(startIndex, endIndex);
		} else {
			// Interpolate to the reference value
			var interpolant = referenceTrack.createInterpolant();
			var startIndex = referenceOffset;
			var endIndex = referenceValueSize - referenceOffset;
			interpolant.evaluate(referenceTime);
			referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);
		}

		// Conjugate the quaternion
		if (referenceTrackType == "quaternion") {
			var referenceQuat = Quaternion.fromArray(referenceValue);
			referenceQuat.normalize();
			referenceQuat.conjugate();
			referenceQuat.toArray(referenceValue);
		}

		// Subtract the reference value from all of the track values

		var numTimes = targetTrack.times.length;
		var j = 0;
		while (j < numTimes) {
			var valueStart = j * targetValueSize + targetOffset;

			if (referenceTrackType == "quaternion") {
				// Multiply the conjugate for quaternion track types
				Quaternion.multiplyQuaternionsFlat(targetTrack.values, valueStart, referenceValue, 0, targetTrack.values, valueStart);
			} else {
				var valueEnd = targetValueSize - targetOffset * 2;

				// Subtract each value for all other numeric track types
				var k = 0;
				while (k < valueEnd) {
					targetTrack.values[valueStart + k] -= referenceValue[k];
					k++;
				}
			}

			j++;
		}

		i++;
	}

	targetClip.blendMode = AdditiveAnimationBlendMode;

	return targetClip;
}

class AnimationUtils {
	public static function convertArray(array:Array<Dynamic>, type:Array<Dynamic>, forceClone:Bool) : Array<Dynamic> {
		if (array == null || !forceClone && array.constructor == type)
			return array;

		if (Reflect.hasField(type, "BYTES_PER_ELEMENT")) {
			return Type.createInstance(type, [array]);
		}

		return Array.ofArray(array);
	}

	public static function isTypedArray(object:Dynamic) : Bool {
		return js.ArrayBuffer.isView(object) && !(object instanceof js.DataView);
	}

	public static function getKeyframeOrder(times:Array<Float>) : Array<Int> {
		function compareTime(i:Int, j:Int) : Int {
			return times[i] - times[j];
		}

		var n = times.length;
		var result = new Array<Int>(n);
		var i = 0;
		while (i < n) {
			result[i] = i;
			i++;
		}

		result.sort(compareTime);

		return result;
	}

	public static function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>) : Array<Dynamic> {
		var nValues = values.length;
		var result = new values.constructor(nValues);

		var i = 0, dstOffset = 0;
		while (dstOffset < nValues) {
			var srcOffset = order[i] * stride;

			var j = 0;
			while (j < stride) {
				result[dstOffset++] = values[srcOffset + j++];
			}

			i++;
		}

		return result;
	}

	public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String) : Void {
		var i = 1, key = jsonKeys[0];

		while (key != null && Reflect.field(key, valuePropertyName) == null) {
			key = jsonKeys[i++];
		}

		if (key == null)
			return;

		var value = Reflect.field(key, valuePropertyName);
		if (value == null)
			return;

		if (Type.enumIndex(value) != null) {
			while (key != null) {
				value = Reflect.field(key, valuePropertyName);

				if (value != null) {
					times.push(key.time);
					values.pushAll(value);
				}

				key = jsonKeys[i++];
			}
		} else if (Reflect.hasField(value, "toArray")) {
			// ...assume THREE.Math-ish
			while (key != null) {
				value = Reflect.field(key, valuePropertyName);

				if (value != null) {
					times.push(key.time);
					value.toArray(values, values.length);
				}

				key = jsonKeys[i++];
			}
		} else {
			// otherwise push as-is
			while (key != null) {
				value = Reflect.field(key, valuePropertyName);

				if (value != null) {
					times.push(key.time);
					values.push(value);
				}

				key = jsonKeys[i++];
			}
		}
	}

	public static function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, fps:Int = 30) : Dynamic {
		var clip = sourceClip.clone();

		clip.name = name;

		var tracks = [];

		var i = 0;
		while (i < clip.tracks.length) {
			var track = clip.tracks[i];
			var valueSize = track.getValueSize();

			var times = [];
			var values = [];

			var j = 0;
			while (j < track.times.length) {
				var frame = Std.int(track.times[j] * fps);

				if (frame < startFrame || frame >= endFrame) {
					j++;
					continue;
				}

				times.push(track.times[j]);

				var k = 0;
				while (k < valueSize) {
					values.push(track.values[j * valueSize + k]);
					k++;
				}

				j++;
			}

			if (times.length == 0) {
				i++;
				continue;
			}

			track.times = convertArray(times, track.times.constructor);
			track.values = convertArray(values, track.values.constructor);

			tracks.push(track);

			i++;
		}

		clip.tracks = tracks;

		// find minimum .times value across all tracks in the trimmed clip

		var minStartTime = Float.POSITIVE_INFINITY;

		i = 0;
		while (i < clip.tracks.length) {
			if (minStartTime > clip.tracks[i].times[0]) {
				minStartTime = clip.tracks[i].times[0];
			}

			i++;
		}

		// shift all tracks such that clip begins at t=0

		i = 0;
		while (i < clip.tracks.length) {
			clip.tracks[i].shift(-minStartTime);

			i++;
		}

		clip.resetDuration();

		return clip;
	}

	public static function makeClipAdditive(targetClip:Dynamic, referenceFrame:Int = 0, referenceClip:Dynamic = targetClip, fps:Int = 30) : Dynamic {
		if (fps <= 0)
			fps = 30;

		var numTracks = referenceClip.tracks.length;
		var referenceTime = referenceFrame / fps;

		// Make each track's values relative to the values at the reference frame
		var i = 0;
		while (i < numTracks) {
			var referenceTrack = referenceClip.tracks[i];
			var referenceTrackType = referenceTrack.ValueTypeName;

			// Skip this track if it's non-numeric
			if (referenceTrackType == "bool" || referenceTrackType == "string") {
				i++;
				continue;
			}

			// Find the track in the target clip whose name and type matches the reference track
			var targetTrack = targetClip.tracks.find(function(track:Dynamic) {
				return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
			});

			if (targetTrack == null) {
				i++;
				continue;
			}

			var referenceOffset = 0;
			var referenceValueSize = referenceTrack.getValueSize();

			if (referenceTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
				referenceOffset = referenceValueSize / 3;
			}

			var targetOffset = 0;
			var targetValueSize = targetTrack.getValueSize();

			if (targetTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
				targetOffset = targetValueSize / 3;
			}

			var lastIndex = referenceTrack.times.length - 1;
			var referenceValue:Array<Float>;

			// Find the value to subtract out of the track
			if (referenceTime <= referenceTrack.times[0]) {
				// Reference frame is earlier than the first keyframe, so just use the first keyframe
				var startIndex = referenceOffset;
				var endIndex = referenceValueSize - referenceOffset;
				referenceValue = referenceTrack.
				values.slice(startIndex, endIndex);
			} else if (referenceTime >= referenceTrack.times[lastIndex]) {
				// Reference frame is after the last keyframe, so just use the last keyframe
				var startIndex = lastIndex * referenceValueSize + referenceOffset;
				var endIndex = startIndex + referenceValueSize - referenceOffset;
				referenceValue = referenceTrack.values.slice(startIndex, endIndex);
			} else {
				// Interpolate to the reference value
				var interpolant = referenceTrack.createInterpolant();
				interpolant.evaluate(referenceTime);
				var startIndex = referenceOffset;
				var endIndex = referenceValueSize - referenceOffset;
				referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);
			}

			// Conjugate the quaternion
			if (referenceTrackType == "quaternion") {
				var referenceQuat = Quaternion.fromArray(referenceValue);
				referenceQuat.normalize();
				referenceQuat.conjugate();
				referenceQuat.toArray(referenceValue);
			}

			// Subtract the reference value from all of the track values

			var numTimes = targetTrack.times.length;
			var j = 0;
			while (j < numTimes) {
				var valueStart = j * targetValueSize + targetOffset;

				if (referenceTrackType == "quaternion") {
					// Multiply the conjugate for quaternion track types
					Quaternion.multiplyQuaternionsFlat(targetTrack.values, valueStart, referenceValue, 0, targetTrack.values, valueStart);
				} else {
					var valueEnd = targetValueSize - targetOffset * 2;
					var k = 0;
					// Subtract each value for all other numeric track types
					while (k < valueEnd) {
						targetTrack.values[valueStart + k] -= referenceValue[k];
						k++;
					}
				}

				j++;
			}

			i++;
		}

		targetClip.blendMode = AdditiveAnimationBlendMode;

		return targetClip;
	}
}

class AnimationUtils {
	public static function convertArray(array:Array<Dynamic>, type:Array<Dynamic>, forceClone:Bool) : Array<Dynamic> {
		if (array == null || !forceClone && array.constructor == type) {
			return array;
		}

		if (Reflect.hasField(type, "BYTES_PER_ELEMENT")) {
			return Type.createInstance(type, [array]);
		}

		return Array.ofArray(array);
	}

	public static function isTypedArray(object:Dynamic) : Bool {
		return js.ArrayBuffer.isView(object) && !(object instanceof js.DataView);
	}

	public static function getKeyframeOrder(times:Array<Float>) : Array<Int> {
		function compareTime(i:Int, j:Int) : Int {
			return times[i] - times[j];
		}

		var n = times.length;
		var result = new Array<Int>(n);
		var i = 0;
		while (i < n) {
			result[i] = i;
			i++;
		}

		result.sort(compareTime);

		return result;
	}

	public static function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>) : Array<Dynamic> {
		var nValues = values.length;
		var result = new values.constructor(nValues);

		var i = 0, dstOffset = 0;
		while (dstOffset < nValues) {
			var srcOffset = order[i] * stride;

			var j = 0;
			while (j < stride) {
				result[dstOffset++] = values[srcOffset + j++];
			}

			i++;
		}

		return result;
	}

	public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String) : Void {
		var i = 1, key = jsonKeys[0];

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

		if (Type.enumIndex(value) != null) {
			while (key != null) {
				value = Reflect.field(key, valuePropertyName);

				if (value != null) {
					times.push(key.time);
					values.pushAll(value);
				}

				key = jsonKeys[i++];
			}
		} else if (Reflect.hasField(value, "toArray")) {
			// ...assume THREE.Math-ish
			while (key != null) {
				value = Reflect.field(key, valuePropertyName);

				if (value != null) {
					times.push(key.time);
					value.toArray(values, values.length);
				}

				key = jsonKeys[i++];
			}
		} else {
			// otherwise push as-is
			while (key != null) {
				value = Reflect.field(key, valuePropertyName);

				if (value != null) {
					times.push(key.time);
					values.push(value);
				}

				key = jsonKeys[i++];
			}
		}
	}

	public static function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, fps:Int = 30) : Dynamic {
		var clip = sourceClip.clone();

		clip.name = name;

		var tracks = [];

		var i = 0;
		while (i < clip.tracks.length) {
			var track = clip.tracks[i];
			var valueSize = track.getValueSize();

			var times = [];
			var values = [];

			var j = 0;
			while (j < track.times.length) {
				var frame = Std.int(track.times[j] * fps);

				if (frame < startFrame || frame >= endFrame) {
					j++;
					continue;
				}

				times.push(track.times[j]);

				var k = 0;
				while (k < valueSize) {
					values.push(track.values[j * valueSize + k]);
					k++;
				}

				j++;
			}

			if (times.length == 0) {
				i++;
				continue;
			}

			track.times = convertArray(times, track.times.constructor);
			track.values = convertArray(values, track.values.constructor);

			tracks.push(track);

			i++;
		}

		clip.tracks = tracks;

		// find minimum .times value across all tracks in the trimmed clip

		var minStartTime = Float.POSITIVE_INFINITY;

		i = 0;
		while (i < clip.tracks.length) {
			if (minStartTime > clip.tracks[i].times[0]) {
				minStartTime = clip.tracks[i].times[0];
			}

			i++;
		}

		// shift all tracks such that clip begins at t=0

		i = 0;
		while (i < clip.tracks.length) {
			clip.tracks[i].shift(-minStartTime);

			i++;
		}

		clip.resetDuration();

		return clip;
	}

	public static function makeClipAdditive(targetClip:Dynamic, referenceFrame:Int = 0, referenceClip:Dynamic = targetClip, fps:Int = 30) : Dynamic {
		if (fps <= 0) {
			fps = 30;
		}

		var numTracks = referenceClip.tracks.length;
		var referenceTime = referenceFrame / fps;

		// Make each track's values relative to the values at the reference frame
		var i = 0;
		while (i < numTracks) {
			var referenceTrack = referenceClip.tracks[i];
			var referenceTrackType = referenceTrack.ValueTypeName;

			// Skip this track if it's non-numeric
			if (referenceTrackType == "bool" || referenceTrackType == "string") {
				i++;
				continue;
			}

			// Find the track in the target clip whose name and type matches the reference track
			var targetTrack = targetClip.tracks.find(function(track) {
				return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
			});

			if (targetTrack == null) {
				i++;
				continue;
			}

			var referenceOffset = 0;
			var referenceValueSize = referenceTrack.getValueSize();

			if (referenceTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
				referenceOffset = referenceValueSize / 3;
			}

			var targetOffset = 0;
			var targetValueSize = targetTrack.getValueSize();

			if (targetTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
				targetOffset = targetValueSize / 3;
			}

			var lastIndex = referenceTrack.times.length - 1;
			var referenceValue:Array<Float>;

			// Find the value to subtract out of the track
			if (referenceTime <= referenceTrack.times[0]) {
				// Reference frame is earlier than the first keyframe, so just use the first keyframe
				var startIndex = referenceOffset;
				var endIndex = referenceValueSize - referenceOffset;
				referenceValue = referenceTrack.values.slice(startIndex, endIndex);
			} else if (referenceTime >= referenceTrack.times[lastIndex]) {
				// Reference frame is after the last keyframe, so just use the last keyframe
				var startIndex = lastIndex * referenceValueSize + referenceOffset;
				var endIndex = startIndex + referenceValueSize - referenceOffset;
				referenceValue = referenceTrack.values.slice(startIndex, endIndex);
			} else {
				// Interpolate to the reference value
				var interpolant = referenceTrack.createInterpolant();
				interpolant.evaluate(referenceTime);
				var startIndex = referenceOffset;
				var endIndex = referenceValueSize - referenceOffset;
				referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);
			}

			// Conjugate the quaternion
			if (referenceTrackType == "quaternion") {
				var referenceQuat = Quaternion.fromArray(referenceValue);
				referenceQuat.normalize();
				referenceQuat.conjugate();
				referenceQuat.toArray(referenceValue);
			}

			// Subtract the reference value from all of the track values

			var numTimes = targetTrack.times.length;
			var j = 0;
			while (j < numTimes) {
				var valueStart = j * targetValueSize + targetOffset;

				if (referenceTrackType == "quaternion") {
					// Multiply the conjugate for quaternion track types
					Quaternion.multiplyQuaternionsFlat(targetTrack.values, valueStart, referenceValue, 0, targetTrack.values, valueStart);
				} else {
					var valueEnd = targetValueSize - targetOffset * 2;
					var k = 0;
					// Subtract each value for all other numeric track types
					while (k < valueEnd) {
						targetTrack.values[valueStart + k] -= referenceValue[k];
						k++;
					}
				}

				j++;
			}

			i++;
		}

		targetClip.blendMode = AdditiveAnimationBlendMode;

		return targetClip;
	}
}