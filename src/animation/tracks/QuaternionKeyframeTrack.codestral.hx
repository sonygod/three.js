import three.animation.KeyframeTrack;
import three.math.interpolants.QuaternionLinearInterpolant;

class QuaternionKeyframeTrack extends KeyframeTrack {

    public function InterpolantFactoryMethodLinear(result:Array<Float>):QuaternionLinearInterpolant {
        return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
    }
}

class QuaternionKeyframeTrackValue {
    public static var ValueTypeName:String = "quaternion";
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited;
    public static var InterpolantFactoryMethodSmooth:Dynamic = null;
}