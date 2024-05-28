package three.animation;

import haxe.ds.ArraySort;
import haxe.ds.Int32Array;
import haxe.ds.Float32Array;
import three.math.Quaternion;

class AnimationUtils {
    public static function convertArray(array:Array<Dynamic>, type:Dynamic, forceClone:Bool = false):Array<Dynamic> {
        if (!array || (!forceClone && array.constructor == type)) return array;

        if (Reflect.hasField(type, 'BYTES_PER_ELEMENT')) {
            return new type(array);
        }

        return array.slice();
    }

    public static function isTypedArray(object:Dynamic):Bool {
        return js.lib.ArrayBuffer.isView(object) && !(object instanceof js.lib.DataView);
    }

    public static function getKeyframeOrder(times:Array<Float>):Array<Int> {
        var compareTime = function(i:Int, j:Int):Int {
            return times[i] - times[j];
        }

        var n = times.length;
        var result = new Array<Int>();
        for (i in 0...n) result[i] = i;

        result.sort(compareTime);

        return result;
    }

    public static function sortedArray(values:Array<Dynamic>, stride:Int, order:Array<Int>):Array<Dynamic> {
        var nValues = values.length;
        var result = new Array<Dynamic>(nValues);

        for (i in 0...nValues) {
            var srcOffset = order[i] * stride;
            for (j in 0...stride) {
                result[i * stride + j] = values[srcOffset + j];
            }
        }

        return result;
    }

    public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Dynamic>, valuePropertyName:String) {
        var i = 1;
        var key = jsonKeys[0];

        while (key != null && Reflect.field(key, valuePropertyName) == null) {
            key = jsonKeys[i++];
        }

        if (key == null) return; // no data

        var value = Reflect.field(key, valuePropertyName);
        if (value == null) return; // no data

        if (Std.isOfType(value, Array)) {
            do {
                value = Reflect.field(key, valuePropertyName);

                if (value != null) {
                    times.push(key.time);
                    values.pushAll(value); // push all elements
                }

                key = jsonKeys[i++];
            } while (key != null);
        } else if (Reflect.hasField(value, 'toArray')) {
            do {
                value = Reflect.field(key, valuePropertyName);

                if (value != null) {
                    times.push(key.time);
                    value.toArray(values, values.length);
                }

                key = jsonKeys[i++];
            } while (key != null);
        } else {
            do {
                value = Reflect.field(key, valuePropertyName);

                if (value != null) {
                    times.push(key.time);
                    values.push(value);
                }

                key = jsonKeys[i++];
            } while (key != null);
        }
    }

    public static function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, fps:Int = 30):Dynamic {
        var clip = sourceClip.clone();

        clip.name = name;

        var tracks:Array<Dynamic> = [];

        for (i in 0...clip.tracks.length) {
            var track = clip.tracks[i];
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

            track.times = convertArray(times, track.times.constructor);
            track.values = convertArray(values, track.values.constructor);

            tracks.push(track);
        }

        clip.tracks = tracks;

        var minStartTime:Float = Math.POSITIVE_INFINITY;

        for (i in 0...clip.tracks.length) {
            if (minStartTime > clip.tracks[i].times[0]) {
                minStartTime = clip.tracks[i].times[0];
            }
        }

        for (i in 0...clip.tracks.length) {
            clip.tracks[i].shift(-minStartTime);
        }

        clip.resetDuration();

        return clip;
    }

    public static function makeClipAdditive(targetClip:Dynamic, referenceFrame:Int = 0, referenceClip:Dynamic = null, fps:Int = 30):Dynamic {
        if (fps <= 0) fps = 30;

        var numTracks = referenceClip.tracks.length;
        var referenceTime = referenceFrame / fps;

        for (i in 0...numTracks) {
            var referenceTrack = referenceClip.tracks[i];
            var referenceTrackType = referenceTrack.ValueTypeName;

            if (referenceTrackType == 'bool' || referenceTrackType == 'string') continue;

            var targetTrack = Lambda.find(targetClip.tracks, function(track) {
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
            var referenceValue:Dynamic;

            if (referenceTime <= referenceTrack.times[0]) {
                referenceValue = referenceTrack.values.slice(referenceOffset, referenceValueSize - referenceOffset);
            } else if (referenceTime >= referenceTrack.times[lastIndex]) {
                referenceValue = referenceTrack.values.slice(lastIndex * referenceValueSize + referenceOffset, lastIndex * referenceValueSize + referenceValueSize - referenceOffset);
            } else {
                var interpolant = referenceTrack.createInterpolant();
                interpolant.evaluate(referenceTime);
                referenceValue = interpolant.resultBuffer.slice(referenceOffset, referenceValueSize - referenceOffset);
            }

            if (referenceTrackType == 'quaternion') {
                var quaternion = new Quaternion(referenceValue).normalize().conjugate();
                quaternion.toArray(referenceValue);
            }

            var numTimes = targetTrack.times.length;
            for (j in 0...numTimes) {
                var valueStart = j * targetValueSize + targetOffset;

                if (referenceTrackType == 'quaternion') {
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