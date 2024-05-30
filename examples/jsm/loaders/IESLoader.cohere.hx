import haxe.io.Bytes;
import js.Browser;
import js.html.HttpRequest;
import js.html.HttpRequestHeaders;
import js.html.HttpRequestResponseType;
import js.html.Window;

class IESLoader {
    public var type:Int;
    public var manager:Dynamic;
    public var crossOrigin:Dynamic;
    public var withCredentials:Bool;
    public var path:String;
    public var requestHeader:Dynamic;

    public function new(manager:Dynamic) {
        this.type = js.Browser.HalfFloatType;
        this.manager = manager;
    }

    public function _getIESValues(iesLamp:IESLamp, type:Int):Dynamic {
        var width = 360;
        var height = 180;
        var size = width * height;
        var data = Array<Float>.make(size);

        function interpolateCandelaValues(phi:Float, theta:Float):Float {
            var phiIndex = 0;
            var thetaIndex = 0;
            var startTheta = 0.0;
            var endTheta = 0.0;
            var startPhi = 0.0;
            var endPhi = 0.0;

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

            var deltaTheta = endTheta - startTheta;
            var deltaPhi = endPhi - startPhi;

            if (deltaPhi == 0) {
                return 0;
            }

            var t1 = (deltaTheta == 0) ? 0 : (theta - startTheta) / deltaTheta;
            var t2 = (phi - startPhi) / deltaPhi;

            var nextThetaIndex = (deltaTheta == 0) ? thetaIndex : thetaIndex + 1;

            var v1 = js.Browser.MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex], iesLamp.candelaValues[nextThetaIndex][phiIndex], t1);
            var v2 = js.Browser.MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex + 1], iesLamp.candelaValues[nextThetaIndex][phiIndex + 1], t1);
            var v = js.Browser.MathUtils.lerp(v1, v2, t2);

            return v;
        }

        var startTheta = iesLamp.horAngles[0];
        var endTheta = iesLamp.horAngles[iesLamp.numHorAngles - 1];

        for (i in 0...size) {
            var theta = i % width;
            var phi = Std.int(i / width);

            if (endTheta - startTheta != 0 && (theta < startTheta || theta >= endTheta)) {
                theta %= endTheta * 2;
                if (theta > endTheta) {
                    theta = endTheta * 2 - theta;
                }
            }

            data[phi + theta * height] = interpolateCandelaValues(phi, theta);
        }

        var result:Dynamic = null;

        if (type == js.Browser.UnsignedByteType) {
            result = data.map((v) -> Std.int(Math.min(v * 0xFF, 0xFF)));
        } else if (type == js.Browser.HalfFloatType) {
            result = data.map(js.Browser.DataUtils.toHalfFloat);
        } else if (type == js.Browser.FloatType) {
            result = data;
        } else {
            js.Browser.window.console.error('IESLoader: Unsupported type:', type);
        }

        return result;
    }

    public function load(url:String, onLoad:Dynamic -> Void, onProgress:Dynamic -> Void, onError:Dynamic -> Void) {
        var loader = FileLoader(this.manager);
        loader.setResponseType(HttpRequestResponseType.Text);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setWithCredentials(this.withCredentials);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);

        loader.load(url, (text) -> onLoad(this.parse(text)), onProgress, onError);
    }

    public function parse(text:String):Dynamic {
        var type = this.type;
        var iesLamp = IESLamp(text);
        var data = this._getIESValues(iesLamp, type);

        var texture = DataTexture(data, 180, 1, js.Browser.RedFormat, type);
        texture.minFilter = js.Browser.LinearFilter;
        texture.magFilter = js.Browser.LinearFilter;
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
        var textArray = text.split('\n');
        var lineNumber = 0;
        var line:String;

        this.verAngles = [];
        this.horAngles = [];
        this.candelaValues = [];
        this.tiltData = {
            angles: [],
            mulFactors: []
        };

        function textToArray(text:String):Array<String> {
            text = text.replace(/#.*$/, ''); // remove comments
            text = text.replace(/^\s+|\s+$/g, ''); // remove leading or trailing spaces
            text = text.replace(/,/g, ' '); // replace commas with spaces
            text = text.replace(/\s\s+/g, ' '); // replace white space/tabs etc by single whitespace
            return text.split(' ');
        }

        function readArray(count:Int, array:Array<Float>) {
            while (true) {
                line = textArray[lineNumber++];
                var lineData = textToArray(line);

                for (i in 0...lineData.length) {
                    array.push(Std.parseFloat(lineData[i]));
                }

                if (array.length == count) {
                    break;
                }
            }
        }

        function readTilt() {
            line = textArray[lineNumber++];
            var lineData = textToArray(line);

            this.tiltData.lampToLumGeometry = Std.parseFloat(lineData[0]);

            line = textArray[lineNumber++];
            lineData = textToArray(line);

            this.tiltData.numAngles = Std.parseInt(lineData[0]);

            readArray(this.tiltData.numAngles, this.tiltData.angles);
            readArray(this.tiltData.numAngles, this.tiltData.mulFactors);
        }

        function readLampValues() {
            var values = [];
            readArray(10, values);

            this.count = Std.parseInt(values[0]);
            this.lumens = Std.parseFloat(values[1]);
            this.multiplier = Std.parseFloat(values[2]);
            this.numVerAngles = Std.parseInt(values[3]);
            this.numHorAngles = Std.parseInt(values[4]);
            this.gonioType = Std.parseInt(values[5]);
            this.units = Std.parseInt(values[6]);
            this.width = Std.parseFloat(values[7]);
            this.length = Std.parseFloat(values[8]);
            this.height = Std.parseFloat(values[9]);
        }

        function readLampFactors() {
            var values = [];
            readArray(3, values);

            this.ballFactor = Std.parseFloat(values[0]);
            this.blpFactor = Std.parseFloat(values[1]);
            this.inputWatts = Std.parseFloat(values[2]);
        }

        while (true) {
            line = textArray[lineNumber++];

            if (line.includes('TILT')) {
                break;
            }
        }

        if (!line.includes('NONE')) {
            if (line.includes('INCLUDE')) {
                readTilt();
            } else {
                // TODO: Read tilt data from a file
            }
        }

        readLampValues();
        readLampFactors();

        // Initialize candela value array
        for (i in 0...this.numHorAngles) {
            this.candelaValues.push([]);
        }

        // Parse Angles
        readArray(this.numVerAngles, this.verAngles);
        readArray(this.numHorAngles, this.horAngles);

        // Parse Candela values
        for (i in 0...this.numHorAngles) {
            readArray(this.numVerAngles, this.candelaValues[i]);
        }

        // Calculate actual candela values and normalize
        for (i in 0...this.numHorAngles) {
            for (j in 0...this.numVerAngles) {
                this.candelaValues[i][j] *= this.candelaValues[i][j] * this.multiplier * this.ballFactor * this.blpFactor;
            }
        }

        var maxVal = -1.0;
        for (i in 0...this.numHorAngles) {
            for (j in 0...this.numVerAngles) {
                var value = this.candelaValues[i][j];
                maxVal = (maxVal < value) ? value : maxVal;
            }
        }

        var bNormalize = true;
        if (bNormalize && maxVal > 0) {
            for (i in 0...this.numHorAngles) {
                for (j in 0...this.numVerAngles) {
                    this.candelaValues[i][j] /= maxVal;
                }
            }
        }
    }
}

class FileLoader {
    public var manager:Dynamic;
    public var responseType:HttpRequestResponseType;
    public var crossOrigin:Dynamic;
    public var withCredentials:Bool;
    public var path:String;
    public var requestHeader:Dynamic;

    public function new(manager:Dynamic) {
        this.manager = manager;
    }

    public function load(url:String, onLoad:Bytes -> Void, onProgress:Dynamic -> Void, onError:Dynamic -> Void) {
        var loader = HttpRequest(this.manager);
        loader.open('GET', url, true);
        loader.responseType = this.responseType;
        loader.withCredentials = this.withCredentials;
        loader.setRequestHeader(this.requestHeader);

        if (this.crossOrigin != null) {
            loader.setRequestHeader(HttpRequestHeaders.CrossOrigin, this.crossOrigin);
        }

        if (this.path != null) {
            url = this.path + url;
        }

        loader.onLoad = (e) -> onLoad(e.currentTarget.response);
        loader.onError = onError;
        loader.send();
    }

    public function setResponseType(value:HttpRequestResponseType) {
        this.responseType = value;
    }

    public function setCrossOrigin(value:Dynamic) {
        this.crossOrigin = value;
    }

    public function setWithCredentials(value:Bool) {
        this.withCredentials = value;
    }

    public function setPath(value:String) {
        this.path = value;
    }

    public function setRequestHeader(value:Dynamic) {
        this.requestHeader = value;
    }
}