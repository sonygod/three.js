package three.animation;

import haxe.io.Bytes;
import haxe.ds.ArraySort;
import three.math.Quaternion;

class AnimationUtils {
    // converts an array to a specific type
    public static function convertArray<T>(array:Array<Dynamic>, type:Class<T>, ?forceClone:Bool):Array<T> {
        if (!array || (!forceClone && Std.isOfType(array, type))) return array;

        if (type == Array<Dynamic> || type == Array<Int> || type == Array<Float>) {
            return array.copy();
        } else if (type == Bytes) {
            return Bytes.ofArray(array);
        } else {
            throw new Error("Unsupported type");
        }
    }

    // returns true if the object is a typed array
    public static function isTypedArray(object:Dynamic):Bool {
        return Std.isOfType(object, Array<Dynamic>) && (!Std.isOfType(object, Bytes));
    }

    // returns an array by which times and values can be sorted
    public static function getKeyframeOrder(times:Array<Float>):Array<Int> {
        var n:Int = times.length;
        var result:Array<Int> = [for (i in 0...n) i];
        result.sort(function(i:Int, j:Int):Int {
            return times[i] - times[j];
        });
        return result;
    }

    // uses the array previously returned by 'getKeyframeOrder' to sort data
    public static function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>):Array<Dynamic> {
        var nValues:Int = values.length;
        var result:Array<Dynamic> = new Array<Dynamic>(nValues);
        for (i in 0...nValues) {
            var dstOffset:Int = i;
            var srcOffset:Int = order[i] * stride;
            for (j in 0...stride) {
                result[dstOffset++] = values[srcOffset + j];
            }
        }
        return result;
    }

    // function for parsing AOS keyframe formats
    public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String):Void {
        var i:Int = 1;
        var key:Dynamic = jsonKeys[0];
        while (key != null && key[valuePropertyName] == null) {
            key = jsonKeys[i++];
        }
        if (key == null) return; // no data
        var value:Dynamic = key[valuePropertyName];
        if (value == null) return; // no data
        if (Std.isOfType(value, Array<Dynamic>)) {
            do {
                value = key[valuePropertyName];
                if (value != null) {
                    times.push(key.time);
                    values.push.apply(values, value); // push all elements
                }
                key = jsonKeys[i++];
            } while (key != null);
        } else if (Reflect.hasField(value, "toArray")) {
            do {
                value = key[valuePropertyName];
                if (value != null) {
                    times.push(key.time);
                    value.toArray(values, values.length);
                }
                key = jsonKeys[i++];
            } while (key != null);
        } else {
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

    // subclip function
    public static function subclip(sourceClip:Clip, name:String, startFrame:Float, endFrame:Float, fps:Float = 30):Clip {
        var clip:Clip = sourceClip.clone();
        clip.name = name;
        var tracks:Array<Track> = [];
        for (track in clip.tracks) {
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
            track.times = convertArray(times, track.times);
            track.values = convertArray(values, track.values);
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

    // makeClipAdditive function
    public static function makeClipAdditive(targetClip:Clip, referenceFrame:Float = 0, referenceClip:Clip = null, fps:Float = 30):Clip {
        if (fps <= 0) fps = 30;
        if (referenceClip == null) referenceClip = targetClip;
        var referenceTime:Float = referenceFrame / fps;
        var numTracks:Int = referenceClip.tracks.length;
        for (i in 0...numTracks) {
            var referenceTrack:Track = referenceClip.tracks[i];
            var referenceTrackType:String = referenceTrack.ValueTypeName;
            if (referenceTrackType == "bool" || referenceTrackType == "string") continue;
            var targetTrack:Track = targetClip.tracks.find(function(track:Track) {
                return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
            });
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
                // Reference frame is earlier than the first keyframe, so just use the first keyframe
                var startIndex:Int = referenceOffset;
                var endIndex:Int = referenceValueSize - referenceOffset;
                referenceValue = referenceTrack.values.slice(startIndex, endIndex);
            } else if (referenceTime >= referenceTrack.times[lastIndex]) {
                // Reference frame is after the last keyframe, so just use the last keyframe
                startIndex = lastIndex * referenceValueSize + referenceOffset;
                endIndex = startIndex + referenceValueSize - referenceOffset;
                referenceValue = referenceTrack.values.slice(startIndex, endIndex);
            } else {
                // Interpolate to the reference value
                var interpolant:Interpolant = referenceTrack.createInterpolant();
                startIndex = referenceOffset;
                endIndex = referenceValueSize - referenceOffset;
                interpolant.evaluate(referenceTime);
                referenceValue = interpolant.resultBuffer.slice(startIndex, endIndex);
            }
            if (referenceTrackType == "quaternion") {
                var referenceQuat:Quaternion = new Quaternion().fromArray(referenceValue).normalize().conjugate();
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
}