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

	public function new(manager:LoaderManager) {
		super(manager);
		this.type = HalfFloatType;
	}

	private function _getIESValues(iesLamp:IESLamp, type:Int):Array<Float> {
		var width = 360;
		var height = 180;
		var size = width * height;
		var data = new Array();
		for (i in 0...size) data.push(0);

		function interpolateCandelaValues(phi:Float, theta:Float):Float {
			var phiIndex = 0;
			var thetaIndex = 0;
			var startTheta = 0;
			var endTheta = 0;
			var startPhi = 0;
			var endPhi = 0;

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

			if (deltaPhi == 0) return 0;

			var t1 = deltaTheta == 0 ? 0 : (theta - startTheta) / deltaTheta;
			var t2 = (phi - startPhi) / deltaPhi;

			var nextThetaIndex = deltaTheta == 0 ? thetaIndex : thetaIndex + 1;

			var v1 = MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex], iesLamp.candelaValues[nextThetaIndex][phiIndex], t1);
			var v2 = MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex + 1], iesLamp.candelaValues[nextThetaIndex][phiIndex + 1], t1);
			var v = MathUtils.lerp(v1, v2, t2);

			return v;
		}

		var startTheta = iesLamp.horAngles[0];
		var endTheta = iesLamp.horAngles[iesLamp.numHorAngles - 1];

		for (i in 0...size) {
			var theta = i % width;
			var phi = Math.floor(i / width);

			if (endTheta - startTheta != 0 && (theta < startTheta || theta >= endTheta)) {
				theta %= endTheta * 2;
				if (theta > endTheta) theta = endTheta * 2 - theta;
			}

			data[phi + theta * height] = interpolateCandelaValues(phi, theta);
		}

		var result = null;

		if (type == UnsignedByteType) result = data.map(v -> Math.min(v * 0xFF, 0xFF));
		else if (type == HalfFloatType) result = data.map(v -> DataUtils.toHalfFloat(v));
		else if (type == FloatType) result = data;
		else trace('IESLoader: Unsupported type: $type');

		return result;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var loader = new FileLoader(this.manager);
		loader.setResponseType('text');
		loader.setCrossOrigin(this.crossOrigin);
		loader.setWithCredentials(this.withCredentials);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);

		loader.load(url, text -> {
			onLoad(this.parse(text));
		}, onProgress, onError);
	}

	public function parse(text:String):DataTexture {
		var type = this.type;
		var iesLamp = new IESLamp(text);
		var data = this._getIESValues(iesLamp, type);
		var texture = new DataTexture(data, 180, 1, RedFormat, type);
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
	public var count:Float;
	public var lumens:Float;
	public var multiplier:Float;
	public var numVerAngles:Float;
	public var numHorAngles:Float;
	public var gonioType:Float;
	public var units:Float;
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
		this.tiltData = { angles: [], mulFactors: [] };

		function textToArray(text:String):Array<String> {
			text = text.replace(/^\s+|\s+$/g, '');
			text = text.replace(/,/g, ' ');
			text = text.replace(/\s\s+/g, ' ');
			return text.split(' ');
		}

		function readArray(count:Int, array:Array<Float>):Void {
			while (true) {
				line = textArray[lineNumber++];
				var lineData = textToArray(line);
				for (i in 0...lineData.length) array.push(Std.parseFloat(lineData[i]));
				if (array.length == count) break;
			}
		}

		function readTilt():Void {
			line = textArray[lineNumber++];
			var lineData = textToArray(line);
			this.tiltData.lampToLumGeometry = Std.parseFloat(lineData[0]);
			line = textArray[lineNumber++];
			lineData = textToArray(line);
			this.tiltData.numAngles = Std.parseFloat(lineData[0]);
			readArray(this.tiltData.numAngles, this.tiltData.angles);
			readArray(this.tiltData.numAngles, this.tiltData.mulFactors);
		}

		function readLampValues():Void {
			var values = [];
			readArray(10, values);
			this.count = Std.parseFloat(values[0]);
			this.lumens = Std.parseFloat(values[1]);
			this.multiplier = Std.parseFloat(values[2]);
			this.numVerAngles = Std.parseFloat(values[3]);
			this.numHorAngles = Std.parseFloat(values[4]);
			this.gonioType = Std.parseFloat(values[5]);
			this.units = Std.parseFloat(values[6]);
			this.width = Std.parseFloat(values[7]);
			this.length = Std.parseFloat(values[8]);
			this.height = Std.parseFloat(values[9]);
		}

		function readLampFactors():Void {
			var values = [];
			readArray(3, values);
			this.ballFactor = Std.parseFloat(values[0]);
			this.blpFactor = Std.parseFloat(values[1]);
			this.inputWatts = Std.parseFloat(values[2]);
		}

		while (true) {
			line = textArray[lineNumber++];
			if (line.indexOf('TILT') != -1) break;
		}

		if (line.indexOf('NONE') == -1) {
			if (line.indexOf('INCLUDE') != -1) readTilt();
			else {
				// TODO:: Read tilt data from a file
			}
		}

		readLampValues();
		readLampFactors();

		for (i in 0...this.numHorAngles) this.candelaValues.push([]);
		readArray(this.numVerAngles, this.verAngles);
		readArray(this.numHorAngles, this.horAngles);
		for (i in 0...this.numHorAngles) readArray(this.numVerAngles, this.candelaValues[i]);

		for (i in 0...this.numHorAngles) {
			for (j in 0...this.numVerAngles) {
				this.candelaValues[i][j] *= this.candelaValues[i][j] * this.multiplier * this.ballFactor * this.blpFactor;
			}
		}

		var maxVal = -1;
		for (i in 0...this.numHorAngles) {
			for (j in 0...this.numVerAngles) {
				var value = this.candelaValues[i][j];
				maxVal = maxVal < value ? value : maxVal;
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