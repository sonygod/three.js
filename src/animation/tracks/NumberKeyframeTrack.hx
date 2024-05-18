package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;

/**
 * A Track of numeric keyframe values.
 */
class NumberKeyframeTrack extends KeyframeTrack {
    public static inline var ValueTypeName:String = 'number';
}

// Note: In Haxe, we don't need to export classes explicitly, 
// as they are accessible from anywhere in the project.