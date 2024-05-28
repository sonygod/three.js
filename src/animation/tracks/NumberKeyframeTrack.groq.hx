package three.animation.tracks;

import three.animation.KeyframeTrack;

/**
 * A Track of numeric keyframe values.
 */
class NumberKeyframeTrack extends KeyframeTrack {
    public static var ValueTypeName:String = 'number';
}

// Note: In Haxe, we don't need to define prototypes like in JavaScript. 
//       The above code is enough to achieve the same result.

// Export the class
export NumberKeyframeTrack;