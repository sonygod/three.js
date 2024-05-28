import js.Quaternion;
import js.AdditiveAnimationBlendMode;

class AnimationUtils {
    static function convertArray(array:Dynamic, type:Class<Dynamic>, forceClone:Bool):Dynamic {
        if (!array || !forceClone && Std.is(array, type)) return array;
        if (Std.is(type.BYTES_PER_ELEMENT, Number)) return new type(array);
        return array.slice();
    }

    static function isTypedArray(object:Dynamic):Bool {
        return js.ArrayBuffer.isView(object) && !(object instanceof js.DataView);
    }

    static function getKeyframeOrder(times:Array<Float>):Array<Int> {
        function compareTime(i:Int, j:Int):Int {
            return times[i] - times[j];
        }
        var n = times.length;
        var result = new Array();
        for (i in 0...n) result.push(i);
        result.sort(compareTime);
        return result;
    }

    static function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>):Array<Dynamic> {
        var nValues = values.length;
        var result = new values.constructor(nValues);
        for (i in 0...nValues) {
            var srcOffset = order[i] * stride;
            for (j in 0...stride) {
                result[dstOffset++] = values[srcOffset + j];
            }
        }
        return result;
    }

    static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String):Void {
        var i = 1;
        var key = jsonKeys[0];
        while (key != null && key[valuePropertyName] == null) {
            key = jsonKeys[i++];
        }
        if (key == null) return;
        var value = key[valuePropertyName];
        if (value == null) return;
        if (Std.is(value, Array)) {
            do {
                value = key[valuePropertyName];
                if (value != null) {
                    times.push(key.time);
                    values.push.apply(values, value);
                }
                key = jsonKeys[i++];
            } while (key != null);
        } else if (Std.is(value.toArray, Function)) {
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

    static function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, fps:Int = 30):Dynamic {
        var clip = sourceClip.clone();
        clip.name = name;
        var tracks = [];
        for (i in 0...clip.tracks.length) {
            var track = clip.tracks[i];
            var valueSize = track.getValueSize();
            var times = [];
            var values = [];
            for (j in 0...track.times.length) {
                var frame = track.times[j] * fps;
                if (frame < startFrame || frame >= endFrame) continue;
                times.push(track.times[j]);
                for (k in 0...valueSize) {
                    values.push(track.values[j * valueSize + k]);
                }
            }
            if (times.length == 0) continue;
            track.times = AnimationUtils.convertArray(times, track.times.constructor);
            track.values = AnimationUtils.convertArray(values, track.values.constructor);
            tracks.push(track);
        }
        clip.tracks = tracks;
        var minStartTime = Infinity;
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

    static function makeClipAdditive(targetClip:Dynamic, referenceFrame:Int = 0, referenceClip:Dynamic = targetClip, fps:Int = 30):Dynamic {
        if (fps <= 0) fps = 30;
        var numTracks = referenceClip.tracks.length;
        var referenceTime = referenceFrame / fps;
        for (i in 0...numTracks) {
            var referenceTrack = referenceClip.tracks[i];
            var referenceTrackType = referenceTrack.ValueTypeName;
            if (referenceTrackType == 'bool' || referenceTrackType == 'string') continue;
            var targetTrack = targetClip.tracks.find(function(track) {
                return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
            });
            if (targetTrack == null) continue;
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
            var referenceValue;
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
            if (referenceTrackType == 'quaternion') {
                var referenceQuat = new Quaternion().fromArray(referenceValue).normalize().conjugate();
                referenceQuat.toArray(referenceValue);
            }
            var numTimes = targetTrack.times.length;
            for (j in 0...numTimes) {
                var valueStart = j * targetValueSize + targetOffset;
                if (referenceTrackType == 'quaternion') {
                    Quaternion.multiplyQuaternionsFlat(
                        targetTrack.values,
                        valueStart,
                        referenceValue,
                        0,
                        targetTrack.values,
                        valueStart
                    );
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