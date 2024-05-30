import three.DataTexture;
import three.FileLoader;
import three.FloatType;
import three.RedFormat;
import three.MathUtils;
import three.Loader;
import three.UnsignedByteType;
import three.LinearFilter;
import three.HalfFloatType;
import three.DataUtils;

class IESLoader extends Loader {

	public var type:HalfFloatType;

	public function new(manager:Loader) {
		super(manager);
		this.type = HalfFloatType;
	}

	private function _getIESValues(iesLamp:IESLamp, type:UnsignedByteType):Array<Float> {
		var width:Int = 360;
		var height:Int = 180;
		var size:Int = width * height;

		var data:Array<Float> = Array.alloc(size);

		function interpolateCandelaValues(phi:Float, theta:Float):Float {
			var phiIndex:Int = 0;
			var thetaIndex:Int = 0;
			var startTheta:Float = 0;
			var endTheta:Float = 0;
			var startPhi:Float = 0;
			var endPhi:Float = 0;

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

		var startTheta:Float = iesLamp.horAngles[0];
		var endTheta:Float = iesLamp.horAngles[iesLamp.numHorAngles - 1];

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

		var result:Array<Float> = null;

		if (type == UnsignedByteType) result = Array.alloc(size);
		else if (type == HalfFloatType) result = Array.alloc(size);
		else if (type == FloatType) result = Array.alloc(size);
		else trace('IESLoader: Unsupported type:', type);

		return result;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
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
		var type:HalfFloatType = this.type;

		var iesLamp:IESLamp = new IESLamp(text);
		var data:Array<Float> = this._getIESValues(iesLamp, type);

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

	public function new(text:String) {
		var textArray:Array<String> = text.split('\n');

		var lineNumber:Int = 0;
		var line:String;

		this.verAngles = [];
		this.horAngles = [];

		this.candelaValues = [];

		this.tiltData = { };
		this.tiltData.angles = [];
		this.tiltData.mulFactors = [];

		function textToArray(text:String):Array<String> {
			text = text.replace(/^\s+|\s+$/g, ''); // remove leading or trailing spaces
			text = text.replace(/,/g, ' '); // replace commas with spaces
			text = text.replace(/\s\s+/g, ' '); // replace white space/tabs etc by single whitespace

			var array:Array<String> = text.split(' ');

			return array;
		}

		function readArray(count:Int, array:Array<Float>):Void {
			while (true) {
				var line:String = textArray[lineNumber++];
				var lineData:Array<String> = textToArray(line);

				for (i in 0...lineData.length) {
					array.push(Std.parseFloat(lineData[i]));
				}

				if (array.length == count)
					break;
			}
		}

		function readTilt():Void {
			var line:String = textArray[lineNumber++];
			var lineData:Array<String> = textToArray(line);

			this.tiltData.lampToLumGeometry = Std.parseFloat(lineData[0]);

			line = textArray[lineNumber++];
			lineData = textToArray(line);

			this.tiltData.numAngles = Std.parseInt(lineData[0]);

			readArray(this.tiltData.numAngles, this.tiltData.angles);
			readArray(this.tiltData.numAngles, this.tiltData.mulFactors);
		}

		function readLampValues():Void {
			var values:Array<Float> = [];
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

		function readLampFactors():Void {
			var values:Array<Float> = [];
			readArray(3, values);

			this.ballFactor = Std.parseFloat(values[0]);
			this.blpFactor = Std.parseFloat(values[1]);
			this.inputWatts = Std.parseFloat(values[2]);
		}

		while (true) {
			line = textArray[lineNumber++];

			if (line.indexOf('TILT') != -1) {
				break;
			}
		}

		if (line.indexOf('NONE') == -1) {
			if (line.indexOf('INCLUDE') != -1) {
				readTilt();
			} else {
				// TODO:: Read tilt data from a file
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

		// Calculate actual candela values, and normalize.
		for (i in 0...this.numHorAngles) {
			for (j in 0...this.numVerAngles) {
				this.candelaValues[i][j] *= this.candelaValues[i][j] * this.multiplier
					* this.ballFactor * this.blpFactor;
			}
		}

		var maxVal:Float = -1;
		for (i in 0...this.numHorAngles) {
			for (j in 0...this.numVerAngles) {
				var value:Float = this.candelaValues[i][j];
				maxVal = maxVal < value ? value : maxVal;
			}
		}

		var bNormalize:Bool = true;
		if (bNormalize && maxVal > 0) {
			for (i in 0...this.numHorAngles) {
				for (j in 0...this.numVerAngles) {
					this.candelaValues[i][j] /= maxVal;
				}
			}
		}
	}
}