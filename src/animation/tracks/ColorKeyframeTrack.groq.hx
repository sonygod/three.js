package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;

/**
 * A Track of keyframe values that represent color.
 */
class ColorKeyframeTrack extends KeyframeTrack {
    public static inline var ValueTypeName:String = 'color';
}

// Note: In Haxe, we don't need to use prototype to add static properties