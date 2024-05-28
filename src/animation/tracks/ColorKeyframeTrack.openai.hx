package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;

/**
 * A Track of keyframe values that represent color.
 */
class ColorKeyframeTrack extends KeyframeTrack {
    public static inline var ValueTypeName:String = 'color';
}

// No need to export in Haxe, as everything is public by default.

// Note: Just like in JavaScript, this is a very basic implementation and nothing special yet.
// However, this is the place for color space parameterization.