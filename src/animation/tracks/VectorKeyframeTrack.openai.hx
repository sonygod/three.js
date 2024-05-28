package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;

/**
 * A Track of vectored keyframe values.
 */
class VectorKeyframeTrack extends KeyframeTrack {
  public static inline var ValueTypeName:String = 'vector';
}

// Note: In Haxe, we don't need to explicitly declare the inheritance of ValueBufferType and DefaultInterpolation,
// as they will be inherited from the KeyframeTrack class.