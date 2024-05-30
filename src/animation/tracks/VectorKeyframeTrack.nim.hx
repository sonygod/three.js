import KeyframeTrack from '../KeyframeTrack.hx';

/**
 * A Track of vectored keyframe values.
 */
class VectorKeyframeTrack extends KeyframeTrack {
  public static var ValueTypeName:String = 'vector';
  // ValueBufferType is inherited
  // DefaultInterpolation is inherited
}

export type VectorKeyframeTrack = VectorKeyframeTrack;