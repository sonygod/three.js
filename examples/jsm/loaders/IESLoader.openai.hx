package three.js.loaders;

import haxe.io.UInt8Array;
import haxe.io.UInt16Array;
import haxe.io.Float32Array;
import three.DataTexture;
import three.FileLoader;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.Loader;
import three.MathUtils;
import three.RedFormat;
import three.UnsignedByteType;

class IESLoader extends Loader {
    var type:HalfFloatType;

    public function new(manager:Loader) {
        super(manager);
        this.type = HalfFloatType;
    }

    private function _getIESValues(iesLamp:IESLamp, type:DataType):Array<Float> {
        var width:Int = 360;
        var height:Int = 180;
        var size:Int = width * height;
        var data:Array<Float> = new Array<Float>();

        function interpolateCandelaValues(phi:Float, theta:Float):Float {
            // implementation omitted for brevity
        }

        for (i in 0...size) {
            var theta:Int = i % width;
            var phi:Int = Math.floor(i / width);

            if (iesLamp.horAngles[iesLamp.numHorAngles - 1] - iesLamp.horAngles[0] != 0 && (theta < iesLamp.horAngles[0] || theta >= iesLamp.horAngles[iesLamp.numHorAngles - 1])) {
                theta %= iesLamp.horAngles[iesLamp.numHorAngles - 1] * 2;
                if (theta > iesLamp.horAngles[iesLamp.numHorAngles - 1])
                    theta = iesLamp.horAngles[iesLamp.numHorAngles - 1] * 2 - theta;
            }

            data[phi + theta * height] = interpolateCandelaValues(phi, theta);
        }

        var result:Array<Float>;
        switch (type) {
            case UnsignedByteType:
                result = UInt8Array.from(data.map(function(v) return Math.min(v * 0xFF, 0xFF)));
            case HalfFloatType:
                result = UInt16Array.from(data.map(function(v) return DataUtils.toHalfFloat(v)));
            case FloatType:
                result = Float32Array.from(data);
            default:
                throw new Error('IESLoader: Unsupported type: $type');
        }
        return result;
    }

    override public function load(url:String, onLoad:DataTexture->Void, onProgress:Float->Void, onError:String->Void) {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setResponseType('text');
        loader.setCrossOrigin(this.crossOrigin);
        loader.setWithCredentials(this.withCredentials);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);

        loader.load(url, function(text:String) {
            onLoad(parse(text));
        }, onProgress, onError);
    }

    public function parse(text:String):DataTexture {
        var iesLamp:IESLamp = new IESLamp(text);
        var data:Array<Float> = _getIESValues(iesLamp, this.type);
        var texture:DataTexture = new DataTexture(data, 180, 1, RedFormat, this.type);
        texture.minFilter = LinearFilter;
        texture.magFilter = LinearFilter;
        texture.needsUpdate = true;
        return texture;
    }
}

class IESLamp {
    public var verAngles:Array<Float>;
    public var horAngles:Array<Float>;
    public var candelaValues:Array<Array<Float>>;
    public var tiltData:{ angles:Array<Float>, mulFactors:Array<Float>, lampToLumGeometry:Float, numAngles:Int };
    public var count:Int;
    public var lumens:Float;
    public var multiplier:Float;
    public var numVerAngles:Int;
    public var numHorAngles:Int;
    public var gonioType:Int;
    public var units:Int;
    public var width:Float;
    public var length:Float;
    public var height:Float;
    public var ballFactor:Float;
    public var blpFactor:Float;
    public var inputWatts:Float;

    public function new(text:String) {
        // implementation omitted for brevity
    }
}