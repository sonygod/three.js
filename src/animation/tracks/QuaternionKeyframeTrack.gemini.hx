```haxe
import three.animation.KeyframeTrack;
import three.math.interpolants.QuaternionLinearInterpolant;

class QuaternionKeyframeTrack extends KeyframeTrack {

	public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Int = DefaultInterpolation) {
		super(name, times, values, interpolation);
	}

	override public function InterpolantFactoryMethodLinear(result:Dynamic):QuaternionLinearInterpolant {
		return new QuaternionLinearInterpolant(this.times, this.values, getValueSize(), result);
	}

	override public function getValueSize():Int {
		return 4;
	}

	override public function ValueTypeName():String {
		return "quaternion";
	}

	public var InterpolantFactoryMethodSmooth:Dynamic = null;
}
```

**Explanation:**

1. **Import statements:** We import the necessary classes from the `three` package.
2. **Constructor:** We define a constructor that takes the track name, times, values, and optional interpolation type as arguments.
3. **`InterpolantFactoryMethodLinear`:** This method returns a `QuaternionLinearInterpolant` instance using the provided times, values, and the size of each quaternion value (4).
4. **`getValueSize`:** This method returns 4 as the size of a quaternion.
5. **`ValueTypeName`:** This property returns the string "quaternion".
6. **`InterpolantFactoryMethodSmooth`:** This property is set to `null` as we don't need a smooth interpolation method for quaternions.

This Haxe code now defines a `QuaternionKeyframeTrack` class equivalent to the original JavaScript code. It provides the same functionality for creating and interpolating quaternion keyframe tracks.
