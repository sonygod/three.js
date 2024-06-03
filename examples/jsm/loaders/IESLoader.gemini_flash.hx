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

	public var type:Int = HalfFloatType;

	public function new(manager:Loader = null) {
		super(manager);
	}

	private function _getIESValues(iesLamp:IESLamp, type:Int):Array<Float> {

		const width = 360;
		const height = 180;
		const size = width * height;

		var data = new Array<Float>(size);

		function interpolateCandelaValues(phi:Float, theta:Float):Float {

			var phiIndex = 0, thetaIndex = 0;
			var startTheta = 0., endTheta = 0., startPhi = 0., endPhi = 0.;

			for (i in 0...iesLamp.numHorAngles - 1) { // numHorAngles = horAngles.length-1 because of extra padding, so this wont cause an out of bounds error

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

			const deltaTheta = endTheta - startTheta;
			const deltaPhi = endPhi - startPhi;

			if (deltaPhi == 0) // Outside range
				return 0;

			const t1 = if (deltaTheta == 0) 0 else (theta - startTheta) / deltaTheta;
			const t2 = (phi - startPhi) / deltaPhi;

			const nextThetaIndex = if (deltaTheta == 0) thetaIndex else thetaIndex + 1;

			const v1 = MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex], iesLamp.candelaValues[nextThetaIndex][phiIndex], t1);
			const v2 = MathUtils.lerp(iesLamp.candelaValues[thetaIndex][phiIndex + 1], iesLamp.candelaValues[nextThetaIndex][phiIndex + 1], t1);
			const v = MathUtils.lerp(v1, v2, t2);

			return v;

		}

		const startTheta = iesLamp.horAngles[0], endTheta = iesLamp.horAngles[iesLamp.numHorAngles - 1];

		for (i in 0...size) {

			var theta = i % width;
			const phi = Math.floor(i / width);

			if (endTheta - startTheta != 0 && (theta < startTheta || theta >= endTheta)) { // Handle symmetry for hor angles

				theta %= endTheta * 2;

				if (theta > endTheta)
					theta = endTheta * 2 - theta;

			}

			data[phi + theta * height] = interpolateCandelaValues(phi, theta);

		}

		var result:Array<Float>;

		if (type == UnsignedByteType) result = data.map(v -> Math.min(v * 0xFF, 0xFF));
		else if (type == HalfFloatType) result = data.map(v -> DataUtils.toHalfFloat(v));
		else if (type == FloatType) result = data;
		else {
			console.error('IESLoader: Unsupported type:', type);
			result = null;
		}

		return result;

	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null) {

		var loader = new FileLoader(this.manager);
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

		const type = this.type;

		var iesLamp = new IESLamp(text);
		var data = _getIESValues(iesLamp, type);

		var texture = new DataTexture(data, 180, 1, RedFormat, type);
		texture.minFilter = LinearFilter;
		texture.magFilter = LinearFilter;
		texture.needsUpdate = true;

		return texture;

	}

}


class IESLamp {

	public var verAngles:Array<Float> = [];
	public var horAngles:Array<Float> = [];

	public var candelaValues:Array<Array<Float>> = [];

	public var tiltData:TiltData = new TiltData();

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

		function textToArray(text:String):Array<String> {

			text = text.replace( /^\s+|\s+$/g, '' ); // remove leading or trailing spaces
			text = text.replace( /,/g, ' ' ); // replace commas with spaces
			text = text.replace( /\s\s+/g, ' ' ); // replace white space/tabs etc by single whitespace

			var array = text.split(' ');

			return array;

		}

		function readArray(count:Int, array:Array<Float>) {

			while (true) {

				line = textArray[lineNumber++];
				var lineData = textToArray(line);

				for (i in 0...lineData.length) {

					array.push(Std.parseFloat(lineData[i]));

				}

				if (array.length == count)
					break;

			}

		}

		function readTilt() {

			line = textArray[lineNumber++];
			var lineData = textToArray(line);

			tiltData.lampToLumGeometry = Std.parseFloat(lineData[0]);

			line = textArray[lineNumber++];
			lineData = textToArray(line);

			tiltData.numAngles = Std.parseInt(lineData[0]);

			readArray(tiltData.numAngles, tiltData.angles);
			readArray(tiltData.numAngles, tiltData.mulFactors);

		}

		function readLampValues() {

			var values:Array<Float> = [];
			readArray(10, values);

			count = Std.parseInt(values[0]);
			lumens = Std.parseFloat(values[1]);
			multiplier = Std.parseFloat(values[2]);
			numVerAngles = Std.parseInt(values[3]);
			numHorAngles = Std.parseInt(values[4]);
			gonioType = Std.parseInt(values[5]);
			units = Std.parseInt(values[6]);
			width = Std.parseFloat(values[7]);
			length = Std.parseFloat(values[8]);
			height = Std.parseFloat(values[9]);

		}

		function readLampFactors() {

			var values:Array<Float> = [];
			readArray(3, values);

			ballFactor = Std.parseFloat(values[0]);
			blpFactor = Std.parseFloat(values[1]);
			inputWatts = Std.parseFloat(values[2]);

		}

		while (true) {

			line = textArray[lineNumber++];

			if (line.indexOf('TILT') != -1) {

				break;

			}

		}

		if (!line.indexOf('NONE') != -1) {

			if (line.indexOf('INCLUDE') != -1) {

				readTilt();

			} else {

				// TODO:: Read tilt data from a file

			}

		}

		readLampValues();

		readLampFactors();

		// Initialize candela value array
		for (i in 0...numHorAngles) {

			candelaValues.push(new Array<Float>());

		}

		// Parse Angles
		readArray(numVerAngles, verAngles);
		readArray(numHorAngles, horAngles);

		// Parse Candela values
		for (i in 0...numHorAngles) {

			readArray(numVerAngles, candelaValues[i]);

		}

		// Calculate actual candela values, and normalize.
		for (i in 0...numHorAngles) {

			for (j in 0...numVerAngles) {

				candelaValues[i][j] *= candelaValues[i][j] * multiplier * ballFactor * blpFactor;

			}

		}

		var maxVal = -1.;
		for (i in 0...numHorAngles) {

			for (j in 0...numVerAngles) {

				var value = candelaValues[i][j];
				maxVal = if (maxVal < value) value else maxVal;

			}

		}

		var bNormalize = true;
		if (bNormalize && maxVal > 0) {

			for (i in 0...numHorAngles) {

				for (j in 0...numVerAngles) {

					candelaValues[i][j] /= maxVal;

				}

			}

		}

	}

}


class TiltData {

	public var lampToLumGeometry:Float;
	public var numAngles:Int;
	public var angles:Array<Float> = [];
	public var mulFactors:Array<Float> = [];

	public function new() {}

}


export { IESLoader };