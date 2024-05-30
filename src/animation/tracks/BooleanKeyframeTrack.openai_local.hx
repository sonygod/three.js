import three.constants.InterpolateDiscrete;
import three.animation.tracks.KeyframeTrack;

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

    // No interpolation parameter because only InterpolateDiscrete is valid.
    public function new(name:String, times:Array<Float>, values:Array<Bool>) {
        super(name, times, values);
    }

}

class Main {
    static public function main() {
        // Note: Actually this track could have an optimized / compressed
        // representation of a single value and a custom interpolant that
        // computes "firstValue ^ isOdd( index )".
    }
}