import InterpolateDiscrete from '../../constants/InterpolateDiscrete';
import KeyframeTrack from '../KeyframeTrack';

class StringKeyframeTrack extends KeyframeTrack {

    public function new(name:String, times:Array<Float>, values:Array<String>) {
        super(name, times, values);
    }

}

StringKeyframeTrack.ValueTypeName = "string";
StringKeyframeTrack.ValueBufferType = Array<String>;
StringKeyframeTrack.DefaultInterpolation = InterpolateDiscrete;
StringKeyframeTrack.InterpolantFactoryMethodLinear = null;
StringKeyframeTrack.InterpolantFactoryMethodSmooth = null;