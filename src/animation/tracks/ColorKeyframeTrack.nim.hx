import three.KeyframeTrack;

/**
 * A Track of keyframe values that represent color.
 */
class ColorKeyframeTrack extends KeyframeTrack {
  public var ValueTypeName(default, null) = 'color';
}

// Note: Very basic implementation and nothing special yet.
// However, this is the place for color space parameterization.

// Export the class
export {
  ColorKeyframeTrack
};