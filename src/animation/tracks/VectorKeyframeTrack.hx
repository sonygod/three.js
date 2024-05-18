package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;

/**
 * A Track of vectored keyframe values.
 */
class VectorKeyframeTrack extends KeyframeTrack {
    public static inline var ValueTypeName:String = 'vector';
}

// No need to export in Haxe, as it's not a concept in the language