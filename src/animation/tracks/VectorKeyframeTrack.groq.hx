package three.animation.tracks;

import three.animation.KeyframeTrack;

/**
 * A Track of vectored keyframe values.
 */
class VectorKeyframeTrack extends KeyframeTrack {
  // Note: In Haxe, we don't need to define a separate `prototype` object
  // We can directly define the static variables and methods on the class itself

  public static inline var ValueTypeName:String = 'vector';
  // ValueBufferType is inherited
  // DefaultInterpolation is inherited
}

// Export the class
#if haxe3
@:expose
#else
@:nativeGen
#end
class VectorKeyframeTrack {}