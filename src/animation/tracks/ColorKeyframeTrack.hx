package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;

/**
 * A Track of keyframe values that represent color.
 */
class ColorKeyframeTrack extends KeyframeTrack {
    public static inline var ValueTypeName:String = 'color';
}

// Note: No need to export explicitly in Haxe, as everything is public by default