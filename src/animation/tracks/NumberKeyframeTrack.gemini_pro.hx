import KeyframeTrack from "../KeyframeTrack";

/**
 * A Track of numeric keyframe values.
 */
class NumberKeyframeTrack extends KeyframeTrack {
  static ValueTypeName: String = "number";
  // ValueBufferType is inherited
  // DefaultInterpolation is inherited
}

export default NumberKeyframeTrack;