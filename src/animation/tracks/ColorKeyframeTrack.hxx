import three.js.src.animation.tracks.KeyframeTrack;

/**
 * A Track of keyframe values that represent color.
 */
class ColorKeyframeTrack extends KeyframeTrack {
    public static var ValueTypeName:String = 'color';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited

    // Note: Very basic implementation and nothing special yet.
    // However, this is the place for color space parameterization.

    public function new() {
        super();
    }
}