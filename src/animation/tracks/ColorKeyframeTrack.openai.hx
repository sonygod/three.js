package animation.tracks;

import KeyframeTrack;

/**
 * A Track of keyframe values that represent color.
 */
class ColorKeyframeTrack extends KeyframeTrack {
    public var ValueTypeName:String = 'color';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited

    // Note: Very basic implementation and nothing special yet.
    // However, this is the place for color space parameterization.
}