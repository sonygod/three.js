import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Int8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;
import js.html.TypedArray;

class Quaternion {
  // implement Quaternion class if needed
}

enum AdditiveAnimationBlendMode {
  // define AdditiveAnimationBlendMode enum if needed
}

class AnimationUtils {
  public static function convertArray<T>(array:Array<T>, type:Class<T>, forceClone:Bool):Array<T> {
    if (array == null || (!forceClone && Type.getClass(array) == type)) return array;
    if (Std.is(type, Float32Array) || Std.is(type, Int16Array) || Std.is(type, Int32Array) ||
        Std.is(type, Int8Array) || Std.is(type, Uint16Array) || Std.is(type, Uint32Array) ||
        Std.is(type, Uint8Array) || Std.is(type, Uint8ClampedArray)) {
      return new type(array);
    }
    return array.copy();
  }

  public static function isTypedArray<T>(object:T):Bool {
    return js.Lib.isPrimitive(object) && ArrayBuffer.isView(cast object, dynamic) &&
      !Std.is(object, DataView);
  }

  public static function getKeyframeOrder(times:Array<Float>):Array<Int> {
    function compareTime(i:Int, j:Int):Int {
      return Std.int(times[i] - times[j]);
    }

    var n = times.length;
    var result = new Array<Int>(n);
    for (i in 0...n) result[i] = i;

    result.sort(compareTime);
    return result;
  }

  public static function sortedArray<T>(values:Array<T>, stride:Int, order:Array<Int>):Array<T> {
    var nValues = values.length;
    var result = new Array<T>(nValues);

    for (i in 0...nValues) {
      var dstOffset = 0;
      var srcOffset = order[i] * stride;

      for (j in 0...stride) {
        result[dstOffset++] = values[srcOffset + j];
      }
    }

    return result;
  }

  public static function flattenJSON(jsonKeys:Array<Dynamic>, times:Array<Float>, values:Array<Float>, valuePropertyName:String):Void {
    var i = 1;
    var key = jsonKeys[0];

    while (key != null && key[valuePropertyName] == null) {
      key = jsonKeys[i++];
    }

    if (key == null) return;

    var value = key[valuePropertyName];
    if (value == null) return;

    if (Std.is(value, Array<Float>)) {
      do {
        value = key[valuePropertyName];
        if (value != null) {
          times.push(key.time);
          values.push(value);
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

  public static function subclip(sourceClip:Dynamic, name:String, startFrame:Int, endFrame:Int, fps:Int = 30):Dynamic {
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

      track.times = convertArray(times, Type.getClass(track.times), false);
      track.values = convertArray(values, Type.getClass(track.values), false);
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

  public static function makeClipAdditive(targetClip:Dynamic, referenceFrame:Int = 0, referenceClip:Dynamic = null, fps:Int = 30):Dynamic {
    if (fps <= 0) fps = 30;

    var numTracks = referenceClip.tracks.length;
    var referenceTime = referenceFrame / fps;

    for (i in 0...numTracks) {
      var referenceTrack = referenceClip.tracks[i];
      var referenceTrackType = referenceTrack.ValueTypeName;

      if (referenceTrackType == "bool" || referenceTrackType == "string") continue;

      var targetTrack = targetClip.tracks.find(function(track) {
        return track.name == referenceTrack.name && track.ValueTypeName == referenceTrackType;
      });

      if (targetTrack == null) continue;

      var referenceOffset = 0;
      var referenceValueSize = referenceTrack.getValueSize();

      if (Reflect.field(referenceTrack.createInterpolant, "isInterpolantFactoryMethodGLTFCubicSpline")) {
        referenceOffset = Std.int(referenceValueSize / 3);
      }

      var targetOffset = 0;
      var targetValueSize = targetTrack.getValueSize();

      if (Reflect.field(targetTrack.createInterpolant, "isInterpolantFactoryMethodGLTFCubicSpline")) {
        targetOffset = Std.int(targetValueSize / 3);
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

      if (referenceTrackType == "quaternion") {
        var referenceQuat = new Quaternion().fromArray(referenceValue).normalize().conjugate();
        referenceQuat.toArray(referenceValue);
      }

      var numTimes = targetTrack.times.length;
      for (j in 0...numTimes) {
        var valueStart = j * targetValueSize + targetOffset;

        if (referenceTrackType == "quaternion") {
          Quaternion.multiplyQuaternionsFlat(
            targetTrack.values, valueStart, referenceValue, 0, targetTrack.values, valueStart);
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