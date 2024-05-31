import threejs.animation.tracks.KeyframeTrack;
import threejs.math.interpolants.QuaternionLinearInterpolant;

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {

    public function new(times:Array<Float>, values:Array<Float>) {
        super(times, values);
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic):QuaternionLinearInterpolant {
        return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    // The following properties are defined outside the class body
    // to mimic the prototype assignment in JavaScript
    public static var ValueTypeName:String = 'quaternion';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited;
    public static var InterpolantFactoryMethodSmooth:Dynamic = null;
}

// Export the class
typedef ExportedQuaternionKeyframeTrack = QuaternionKeyframeTrack;