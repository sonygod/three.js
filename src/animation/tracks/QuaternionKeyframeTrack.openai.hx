import three.animation.tracks.KeyframeTrack;
import three.math.interpolants.QuaternionLinearInterpolant;

class QuaternionKeyframeTrack extends KeyframeTrack {

    public function InterpolantFactoryMethodLinear(result: Dynamic): QuaternionLinearInterpolant {
        return new QuaternionLinearInterpolant(times, values, this.getValueSize(), result);
    }

    public var ValueTypeName: String = "quaternion";
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited;
    public var InterpolantFactoryMethodSmooth: Null<Dynamic> = null;

}