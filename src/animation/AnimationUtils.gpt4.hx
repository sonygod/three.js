import three.math.Quaternion;
import three.constants.AdditiveAnimationBlendMode;

// converts an array to a specific type
function convertArray(array:Dynamic, type:Dynamic, forceClone:Bool):Dynamic {
	if (array == null || (!forceClone && Type.getClass(array) == type)) return array;

	if (Reflect.hasField(type, "BYTES_PER_ELEMENT")) {
		return Type.createInstance(type, [array]); // create typed array
	}

	return array.slice(); // create Array
}

function isTypedArray(object:Dynamic):Bool {
	return (Reflect.hasField(object, "buffer") && !(Std.is(object, haxe.io.Bytes)));
}

// returns an array by which times and values can be sorted
function getKeyframeOrder(times:Array<Float>):Array<Int> {
	function compareTime(i:Int, j:Int):Int {
		return Std.int(times[i] - times[j]);
	}

	var n:Int = times.length;
	var result:Array<Int> = [];
	for (i in 0...n) result.push(i);

	result.sort(compareTime);

	return result;
}

// uses the array previously returned by 'getKeyframeOrder' to sort data
function sortedArray(values:Dynamic, stride:Int, order:Array<Int>):Dynamic {
	var nValues:Int = Reflect.field(values, "length");
	var result = Type.createInstance(Type.getClass(values), [nValues]);

	for (i in 0...order.length) {
		var srcOffset:Int = order[i] * stride;
		for (j in 0...stride) {
			result[i * stride + j] = values[srcOffset + j];
		}
	}

	return result;
}

// function for parsing AOS keyframe formats
function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String):Void {
	var i:Int = 1;
	var key:Dynamic = jsonKeys[0];

	while (key != null && Reflect.field(key, valuePropertyName) == null) {
		key = jsonKeys[i++];
	}

	if (key == null) return;

	var value = Reflect.field(key, valuePropertyName);
	if (value == null) return;

	if (Type.typeof(value) == ValueType.TArray) {
		while (key != null) {
			value = Reflect.field(key, valuePropertyName);
			if (value != null) {
				times.push(key.time);
				values.push.apply(values, value);
			}
			key = jsonKeys[i++];
		}
	} else if (Reflect.hasField(value, "toArray")) {
		while (key != null) {
			value = Reflect.field(key, valuePropertyName);
			if (value != null) {
				times.push(key.time);
				value.toArray(values, values.length);
			}
			key = jsonKeys[i++];
		}
	} else {
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

function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, fps:Int = 30):Dynamic {
	var clip = sourceClip.clone();
	clip.name = name;

	var tracks:Array<Dynamic> = [];

	for (track in clip.tracks) {
		var valueSize = track.getValueSize();
		var times:Array<Float> = [];
		var values:Array<Dynamic> = [];

		for (j in 0...track.times.length) {
			var frame = track.times[j] * fps;
			if (frame < startFrame || frame >= endFrame) continue;
			times.push(track.times[j]);
			for (k in 0...valueSize) {
				values.push(track.values[j * valueSize + k]);
			}
		}

		if (times.length == 0) continue;

		track.times = convertArray(times, Type.getClass(track.times), false);
		track.values = convertArray(values, Type.getClass(track.values), false);

		tracks.push(track);
	}

	clip.tracks = tracks;

	var minStartTime:Float = Math.POSITIVE_INFINITY;
	for (track in clip.tracks) {
		if (minStartTime > track.times[0]) {
			minStartTime = track.times[0];
		}
	}

	for (track in clip.tracks) {
		track.shift(-minStartTime);
	}

	clip.resetDuration();

	return clip;
}

function makeClipAdditive(targetClip:Dynamic, referenceFrame:Int = 0, referenceClip:Dynamic = null, fps:Int = 30):Dynamic {
	if (fps <= 0) fps = 30;
	if (referenceClip == null) referenceClip = targetClip;

	var numTracks:Int = referenceClip.tracks.length;
	var referenceTime:Float = referenceFrame / fps;

	for (i in 0...numTracks) {
		var referenceTrack = referenceClip.tracks[i];
		var referenceTrackType = referenceTrack.ValueTypeName;

		if (referenceTrackType == "bool" || referenceTrackType == "string") continue;

		var targetTrack = targetClip.tracks.find(function(track) {
			return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
		});

		if (targetTrack == null) continue;

		var referenceOffset:Int = 0;
		var referenceValueSize:Int = referenceTrack.getValueSize();

		if (Reflect.hasField(referenceTrack.createInterpolant, "isInterpolantFactoryMethodGLTFCubicSpline")) {
			referenceOffset = referenceValueSize / 3;
		}

		var targetOffset:Int = 0;
		var targetValueSize:Int = targetTrack.getValueSize();

		if (Reflect.hasField(targetTrack.createInterpolant, "isInterpolantFactoryMethodGLTFCubicSpline")) {
			targetOffset = targetValueSize / 3;
		}

		var lastIndex:Int = referenceTrack.times.length - 1;
		var referenceValue:Array<Float>;

		if (referenceTime <= referenceTrack.times[0]) {
			var startIndex:Int = referenceOffset;
			var endIndex:Int = referenceValueSize - referenceOffset;
			referenceValue = referenceTrack.values.slice(startIndex, endIndex);
		} else if (referenceTime >= referenceTrack.times[lastIndex]) {
			var startIndex:Int = lastIndex * referenceValueSize + referenceOffset;
			var endIndex:Int = startIndex + referenceValueSize - referenceOffset;
			referenceValue = referenceTrack.values.slice(startIndex, endIndex);
		} else {
			var interpolant = referenceTrack.createInterpolant();
			var startIndex:Int = referenceOffset;
			var endIndex:Int = referenceValueSize - referenceOffset;
			interpolant.evaluate(referenceTime);
			referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);
		}

		if (referenceTrackType == "quaternion") {
			var referenceQuat = new Quaternion().fromArray(referenceValue).normalize().conjugate();
			referenceQuat.toArray(referenceValue);
		}

		for (j in 0...targetTrack.times.length) {
			var valueStart:Int = j * targetValueSize + targetOffset;

			if (referenceTrackType == "quaternion") {
				Quaternion.multiplyQuaternionsFlat(targetTrack.values, valueStart, referenceValue, 0, targetTrack.values, valueStart);
			} else {
				var valueEnd:Int = targetValueSize - targetOffset * 2;
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
	public static var convertArray = convertArray;
	public static var isTypedArray = isTypedArray;
	public static var getKeyframeOrder = getKeyframeOrder;
	public static var sortedArray = sortedArray;
	public static var flattenJSON = flattenJSON;
	public static var subclip = subclip;
	public static var makeClipAdditive = makeClipAdditive;
}