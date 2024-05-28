package three.js.animation;

import three.AnimationClip;
import three.BooleanKeyframeTrack;
import three.ColorKeyframeTrack;
import three.NumberKeyframeTrack;
import three.Vector3;
import three.VectorKeyframeTrack;

class AnimationClipCreator {
  public static function createRotationAnimation(period:Float, axis:String = 'x'):AnimationClip {
    var times:Array<Float> = [0, period];
    var values:Array<Float> = [0, 360];
    var trackName:String = '.rotation[' + axis + ']';
    var track:NumberKeyframeTrack = new NumberKeyframeTrack(trackName, times, values);
    return new AnimationClip(null, period, [track]);
  }

  public static function createScaleAxisAnimation(period:Float, axis:String = 'x'):AnimationClip {
    var times:Array<Float> = [0, period];
    var values:Array<Float> = [0, 1];
    var trackName:String = '.scale[' + axis + ']';
    var track:NumberKeyframeTrack = new NumberKeyframeTrack(trackName, times, values);
    return new AnimationClip(null, period, [track]);
  }

  public static function createShakeAnimation(duration:Float, shakeScale:Float):AnimationClip {
    var times:Array<Float> = [];
    var values:Array<Float> = [];
    var tmp:Vector3 = new Vector3();
    for (i in 0...Math.floor(duration * 10)) {
      times.push(i / 10);
      tmp.set(Math.random() * 2.0 - 1.0, Math.random() * 2.0 - 1.0, Math.random() * 2.0 - 1.0);
      tmp.multiplyScalar(shakeScale);
      values = tmp.toArray(values);
    }
    var trackName:String = '.position';
    var track:VectorKeyframeTrack = new VectorKeyframeTrack(trackName, times, values);
    return new AnimationClip(null, duration, [track]);
  }

  public static function createPulsationAnimation(duration:Float, pulseScale:Float):AnimationClip {
    var times:Array<Float> = [];
    var values:Array<Float> = [];
    var tmp:Vector3 = new Vector3();
    for (i in 0...Math.floor(duration * 10)) {
      times.push(i / 10);
      var scaleFactor:Float = Math.random() * pulseScale;
      tmp.set(scaleFactor, scaleFactor, scaleFactor);
      values = tmp.toArray(values);
    }
    var trackName:String = '.scale';
    var track:VectorKeyframeTrack = new VectorKeyframeTrack(trackName, times, values);
    return new AnimationClip(null, duration, [track]);
  }

  public static function createVisibilityAnimation(duration:Float):AnimationClip {
    var times:Array<Float> = [0, duration / 2, duration];
    var values:Array<Bool> = [true, false, true];
    var trackName:String = '.visible';
    var track:BooleanKeyframeTrack = new BooleanKeyframeTrack(trackName, times, values);
    return new AnimationClip(null, duration, [track]);
  }

  public static function createMaterialColorAnimation(duration:Float, colors:Array<{r:Float, g:Float, b:Float}>):AnimationClip {
    var times:Array<Float> = [];
    var values:Array<Float> = [];
    var timeStep:Float = duration / colors.length;
    for (i in 0...colors.length) {
      times.push(i * timeStep);
      var color:{r:Float, g:Float, b:Float} = colors[i];
      values.push(color.r, color.g, color.b);
    }
    var trackName:String = '.material.color';
    var track:ColorKeyframeTrack = new ColorKeyframeTrack(trackName, times, values);
    return new AnimationClip(null, duration, [track]);
  }
}