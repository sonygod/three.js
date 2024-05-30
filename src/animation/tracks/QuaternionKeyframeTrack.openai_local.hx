import threejs.animation.tracks.KeyframeTrack;
import threejs.math.interpolants.QuaternionLinearInterpolant;

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {

    public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Dynamic = null) {
        super(name, times, values, interpolation);
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic):QuaternionLinearInterpolant {
        return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
    }

}

typedef QuaternionKeyframeTrackPrototype = {
    var ValueTypeName:String;
    var InterpolantFactoryMethodSmooth:Dynamic;
}

// Prototype assignment
var QuaternionKeyframeTrackPrototype:QuaternionKeyframeTrackPrototype = {
    ValueTypeName: "quaternion",
    InterpolantFactoryMethodSmooth: null
};

// Assign prototype properties to the class
Reflect.setField(QuaternionKeyframeTrack, "prototype", QuaternionKeyframeTrackPrototype);