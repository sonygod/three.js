@:include('three.js/examples/jsm/nodes/functions/BSDF/BRDF_Lambert.js')
@:expose

class BRDF_LambertExtern {
    public static function call(inputs:Dynamic):Dynamic {
        return js.Boot.callDynamicIn(BRDF_Lambert, null, [inputs]);
    }
}


In this Haxe code, we're including the JavaScript file and exposing its contents to Haxe. We're then defining a class `BRDF_LambertExtern` with a static method `call` that can be used to call the JavaScript function `BRDF_Lambert`. The `inputs` argument is a `Dynamic` type, which means it can be any JavaScript value. The return type is also `Dynamic`, which means it can be any JavaScript value.

You can use this class in your Haxe code like this:


var inputs = ... // some JavaScript value
var result = BRDF_LambertExtern.call(inputs);