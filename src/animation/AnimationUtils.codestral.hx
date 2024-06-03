import three.math.Quaternion;
import three.constants.AdditiveAnimationBlendMode;

class AnimationUtils {
    // Converts an array to a specific type
    public static function convertArray(array:Array<Dynamic>, type:Dynamic, forceClone:Bool):Dynamic {
        if (!array || (!forceClone && array is type)) return array;
        if (Std.isOfType(type, Class<Int>)) return Int32Array.from(array);
        else if (Std.isOfType(type, Class<Float>)) return Float32Array.from(array);
        else return array.slice();
    }

    // Checks if the object is a typed array
    public static function isTypedArray(object:Dynamic):Bool {
        return object is Int8Array || object is Uint8Array || object is Uint8ClampedArray
            || object is Int16Array || object is Uint16Array
            || object is Int32Array || object is Uint32Array
            || object is Float32Array || object is Float64Array;
    }

    // Returns an array by which times and values can be sorted
    public static function getKeyframeOrder(times:Array<Float>):Array<Int> {
        var result:Array<Int> = [];
        for (i in 0...times.length) result.push(i);
        result.sort((a, b) -> times[a] - times[b]);
        return result;
    }

    // Uses the array previously returned by 'getKeyframeOrder' to sort data
    public static function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>):Array<Dynamic> {
        var result:Array<Dynamic> = [];
        for (i in 0...order.length) {
            var srcOffset = order[i] * stride;
            for (j in 0...stride) result.push(values[srcOffset + j]);
        }
        return result;
    }

    // Function for parsing AOS keyframe formats
    public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String):Void {
        var i:Int = 1;
        var key:Dynamic = jsonKeys[0];
        while (key != null && Reflect.hasField(key, valuePropertyName) == false) {
            key = jsonKeys[i++];
        }
        if (key == null) return; // no data
        var value:Dynamic = Reflect.field(key, valuePropertyName);
        if (value == null) return; // no data
        if (Std.isOfType(value, Class<Array<Dynamic>>)) {
            do {
                value = Reflect.field(key, valuePropertyName);
                if (value != null) {
                    times.push(Reflect.field(key, "time"));
                    values.pushAll(value);
                }
                key = jsonKeys[i++];
            } while (key != null);
        } else if (Reflect.hasField(value, "toArray")) {
            do {
                value = Reflect.field(key, valuePropertyName);
                if (value != null) {
                    times.push(Reflect.field(key, "time"));
                    value.toArray(values, values.length);
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

    public static function subclip(sourceClip:AnimationClip, name:String, startFrame:Int, endFrame:Int, fps:Float = 30.0):AnimationClip {
        var clip:AnimationClip = sourceClip.clone();
        clip.name = name;
        var tracks:Array<KeyframeTrack> = [];
        for (i in 0...clip.tracks.length) {
            var track:KeyframeTrack = clip.tracks[i];
            var valueSize:Int = track.getValueSize();
            var times:Array<Float> = [];
            var values:Array<Dynamic> = [];
            for (j in 0...track.times.length) {
                var frame:Float = track.times[j] * fps;
                if (frame < startFrame || frame >= endFrame) continue;
                times.push(track.times[j]);
                for (k in 0...valueSize) {
                    values.push(track.values[j * valueSize + k]);
                }
            }
            if (times.length == 0) continue;
            track.times = convertArray(times, track.times.constructor);
            track.values = convertArray(values, track.values.constructor);
            tracks.push(track);
        }
        clip.tracks = tracks;
        var minStartTime:Float = Float.POSITIVE_INFINITY;
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

    public static function makeClipAdditive(targetClip:AnimationClip, referenceFrame:Int = 0, referenceClip:AnimationClip = null, fps:Float = 30.0):AnimationClip {
        if (fps <= 0) fps = 30.0;
        if (referenceClip == null) referenceClip = targetClip;
        var numTracks:Int = referenceClip.tracks.length;
        var referenceTime:Float = referenceFrame / fps;
        for (i in 0...numTracks) {
            var referenceTrack:KeyframeTrack = referenceClip.tracks[i];
            var referenceTrackType:String = referenceTrack.ValueTypeName;
            if (referenceTrackType == "bool" || referenceTrackType == "string") continue;
            var targetTrack:KeyframeTrack = null;
            for (track in targetClip.tracks) {
                if (track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType) {
                    targetTrack = track;
                    break;
                }
            }
            if (targetTrack == null) continue;
            var referenceOffset:Int = 0;
            var referenceValueSize:Int = referenceTrack.getValueSize();
            if (referenceTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
                referenceOffset = referenceValueSize / 3;
            }
            var targetOffset:Int = 0;
            var targetValueSize:Int = targetTrack.getValueSize();
            if (targetTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
                targetOffset = targetValueSize / 3;
            }
            var lastIndex:Int = referenceTrack.times.length - 1;
            var referenceValue:Array<Dynamic>;
            if (referenceTime <= referenceTrack.times[0]) {
                referenceValue = referenceTrack.values.slice(referenceOffset, referenceValueSize - referenceOffset);
            } else if (referenceTime >= referenceTrack.times[lastIndex]) {
                var startIndex:Int = lastIndex * referenceValueSize + referenceOffset;
                var endIndex:Int = startIndex + referenceValueSize - referenceOffset;
                referenceValue = referenceTrack.values.slice(startIndex, endIndex);
            } else {
                var interpolant:IInterpolant = referenceTrack.createInterpolant();
                var startIndex:Int = referenceOffset;
                var endIndex:Int = referenceValueSize - referenceOffset;
                interpolant.evaluate(referenceTime);
                referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);
            }
            if (referenceTrackType == "quaternion") {
                var referenceQuat:Quaternion = new Quaternion().fromArray(referenceValue).normalize().conjugate();
                referenceQuat.toArray(referenceValue);
            }
            var numTimes:Int = targetTrack.times.length;
            for (j in 0...numTimes) {
                var valueStart:Int = j * targetValueSize + targetOffset;
                if (referenceTrackType == "quaternion") {
                    Quaternion.multiplyQuaternionsFlat(
                        targetTrack.values,
                        valueStart,
                        referenceValue,
                        0,
                        targetTrack.values,
                        valueStart
                    );
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
}