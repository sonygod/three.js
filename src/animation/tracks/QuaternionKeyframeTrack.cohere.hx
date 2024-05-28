import KeyframeTrack from '../KeyframeTrack.hx';
import QuaternionLinearInterpolant from '../../math/interpolants/QuaternionLinearInterpolant.hx';

class QuaternionKeyframeTrack extends KeyframeTrack {
    public function InterpolantFactoryMethodLinear(result:Dynamic):Dynamic {
        return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
    }
}

static public var ValueTypeName:String = 'quaternion';
// ValueBufferType is inherited
// DefaultInterpolation is inherited;
static public var InterpolantFactoryMethodSmooth:Dynamic = undefined;