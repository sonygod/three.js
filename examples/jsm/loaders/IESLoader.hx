package three.js.examples.jsm.loaders;

import three.DataTexture;
import three.FileLoader;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.Loader;
import three.MathUtils;
import three.RedFormat;
import three.UnsignedByteType;
import three.DataUtils;

class IESLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
        this.type = HalfFloatType;
    }

    private function _getIESValues(iesLamp:IESLamp, type:Dynamic):Array<Float> {
        var width:Int = 360;
        var height:Int = 180;
        var size:Int = width * height;

        var data:Array<Float> = new Array<Float>(size);

        function interpolateCandelaValues(phi:Float, theta:Float):Float {
            var phiIndex:Int = 0, thetaIndex:Int = 0;
            var startTheta:Float = 0, endTheta:Float = 0, startPhi:Float = 0, endPhi:Float = 0;

            for (i in 0...iesLamp.numHorAngles - 1) {
                if (theta < iesLamp.horAngles[i + 1] || i == iesLamp.numHorAngles - 2) {
                    thetaIndex = i;
                    startTheta = iesLamp.horAngles[i];
                    endTheta = iesLamp.horAngles[i + 1];
                    break;
                }
            }

            for (i in 0...iesLamp.numVerAngles - 1) {
                if (phi < iesLamp.verAngles[i + 1] || i == iesLamp.numVerAngles - 2) {
                    phiIndex = i;
                    startPhi = iesLamp.verAngles[i];
                    endPhi = iesLamp.verAngles[i + 1];
                    break;
                }
            }

            var deltaTheta:Float = endTheta - startTheta;
            var deltaPhi:Float = endPhi - startPhi;

            if (deltaPhi == 0) // Outside range
                return 0;

            var t1:Float = deltaTheta == 0 ? 0 : (theta - startTheta) / deltaTheta;
            var t2:Float = (phi - startPhi) / deltaPhi;

            var nextThetaIndex:Int = deltaTheta == 0 ? thetaIndex : thetaIndex + 1;

            var v1:Float = MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex], iesLamp.candelaValues[nextThetaIndex][phiIndex], t1);
            var v2:Float = MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex + 1], iesLamp.candelaValues[nextThetaIndex][phiIndex + 1], t1);
            var v:Float = MathUtils.lerp(v1, v2, t2);

            return v;
        }

        var startTheta:Float = iesLamp.horAngles[0], endTheta:Float = iesLamp.horAngles[iesLamp.numHorAngles - 1];

        for (i in 0...size) {
            var theta:Int = i % width;
            var phi:Int = Math.floor(i / width);

            if (endTheta - startTheta != 0 && (theta < startTheta || theta >= endTheta)) { // Handle symmetry for hor angles
                theta %= endTheta * 2;

                if (theta > endTheta)
                    theta = endTheta * 2 - theta;
            }

            data[phi + theta * height] = interpolateCandelaValues(phi, theta);
        }

        var result:Dynamic = null;

        if (type == UnsignedByteType) result = haxe.io.Float32Array.fromArray(data.map(v -> Math.min(v * 0xFF, 0xFF)));
        else if (type == HalfFloatType) result = haxe.io.Float16Array.fromArray(data.map(v -> DataUtils.toHalfFloat(v)));
        else if (type == FloatType) result = haxe.io.Float32Array.fromArray(data);
        else trace('IESLoader: Unsupported type:', type);

        return result;
    }

    public function load(url:String, onLoad:(texture:DataTexture)->Void, onProgress:(progress:Int)->Void, onError:(error:Dynamic)->Void) {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setResponseType('text');
        loader.setCrossOrigin(this.crossOrigin);
        loader.setWithCredentials(this.withCredentials);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);

        loader.load(url, function(text:String) {
            onLoad(this.parse(text));
        }, onProgress, onError);
    }

    public function parse(text:String):DataTexture {
        var type:Dynamic = this.type;
        var iesLamp:IESLamp = new IESLamp(text);
        var data:Array<Float> = _getIESValues(iesLamp, type);

        var texture:DataTexture = new DataTexture(data, 180, 1, RedFormat, type);
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
    public var tiltData:Dynamic;
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
        var _self:IESLamp = this;
        var textArray:Array<String> = text.split('\n');
        var lineNumber:Int = 0;
        var line:String;

        _self.verAngles = [];
        _self.horAngles = [];
        _self.candelaValues = [];
        _self.tiltData = { angles: [], mulFactors: [] };

        function textToArray(text:String):Array<String> {
            text = text.replace(~/^\s+|\s+$/g, ''); // remove leading or trailing spaces
            text = text.replace(/,/g, ' '); // replace commas with spaces
            text = text.replace(/\s\s+/g, ' '); // replace white space/tabs etc by single whitespace

            return text.split(' ');
        }

        function readArray(count:Int, array:Array<Float>) {
            while (true) {
                line = textArray[lineNumber++];
                var lineData:Array<String> = textToArray(line);

                for (i in 0...lineData.length) {
                    array.push(Std.parseFloat(lineData[i]));
                }

                if (array.length == count)
                    break;
            }
        }

        function readTilt() {
            line = textArray[lineNumber++];
            var lineData:Array<String> = textToArray(line);

            _self.tiltData.lampToLumGeometry = Std.parseFloat(lineData[0]);

            line = textArray[lineNumber++];
            lineData = textToArray(line);

            _self.tiltData.numAngles = Std.parseInt(lineData[0]);

            readArray(_self.tiltData.numAngles, _self.tiltData.angles);
            readArray(_self.tiltData.numAngles, _self.tiltData.mulFactors);
        }

        function readLampValues() {
            var values:Array<Float> = [];
            readArray(10, values);

            _self.count = Std.parseInt(values[0]);
            _self.lumens = Std.parseFloat(values[1]);
            _self.multiplier = Std.parseFloat(values[2]);
            _self.numVerAngles = Std.parseInt(values[3]);
            _self.numHorAngles = Std.parseInt(values[4]);
            _self.gonioType = Std.parseInt(values[5]);
            _self.units = Std.parseInt(values[6]);
            _self.width = Std.parseFloat(values[7]);
            _self.length = Std.parseFloat(values[8]);
            _self.height = Std.parseFloat(values[9]);
        }

        function readLampFactors() {
            var values:Array<Float> = [];
            readArray(3, values);

            _self.ballFactor = Std.parseFloat(values[0]);
            _self.blpFactor = Std.parseFloat(values[1]);
            _self.inputWatts = Std.parseFloat(values[2]);
        }

        while (true) {
            line = textArray[lineNumber++];

            if (line.indexOf('TILT') != -1) {
                break;
            }
        }

        if (!line.indexOf('NONE') == -1) {
            if (line.indexOf('INCLUDE') != -1) {
                readTilt();
            } else {
                // TODO:: Read tilt data from a file
            }
        }

        readLampValues();

        readLampFactors();

        // Initialize candela value array
        for (i in 0..._self.numHorAngles) {
            _self.candelaValues.push([]);
        }

        // Parse Angles
        readArray(_self.numVerAngles, _self.verAngles);
        readArray(_self.numHorAngles, _self.horAngles);

        // Parse Candela values
        for (i in 0..._self.numHorAngles) {
            readArray(_self.numVerAngles, _self.candelaValues[i]);
        }

        // Calculate actual candela values, and normalize.
        for (i in 0..._self.numHorAngles) {
            for (j in 0..._self.numVerAngles) {
                _self.candelaValues[i][j] *= _self.candelaValues[i][j] * _self.multiplier
                    * _self.ballFactor * _self.blpFactor;
            }
        }

        var maxVal:Float = -1;
        for (i in 0..._self.numHorAngles) {
            for (j in 0..._self.numVerAngles) {
                var value:Float = _self.candelaValues[i][j];
                maxVal = maxVal < value ? value : maxVal;
            }
        }

        var bNormalize:Bool = true;
        if (bNormalize && maxVal > 0) {
            for (i in 0..._self.numHorAngles) {
                for (j in 0..._self.numVerAngles) {
                    _self.candelaValues[i][j] /= maxVal;
                }
            }
        }
    }
}