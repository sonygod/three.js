class GPUShaderStage {
    static var VERTEX:Int = 1;
    static var FRAGMENT:Int = 2;
    static var COMPUTE:Int = 4;
}

class WebGPU {

    private static var isAvailable:Bool = js.Browser.navigator.gpu !== null;

    static function isAvailable():Bool {
        return isAvailable;
    }

    static function getStaticAdapter():Bool {
        return isAvailable;
    }

    static function getErrorMessage():String {
        return "Your browser does not support <a href=\"https://gpuweb.github.io/gpuweb/\" style=\"color:blue\">WebGPU</a> yet";
    }

}

export default WebGPU;