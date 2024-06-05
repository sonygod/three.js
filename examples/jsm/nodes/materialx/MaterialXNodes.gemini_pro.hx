import mx.noise.MxNoise;
import mx.color.MxHsv;
import mx.transform.MxTransformColor;
import haxe.math.Math;
import openfl.geom.Vector3;
import openfl.geom.Vector2;
import openfl.utils.Float;
import openfl.Vector;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Stage;

class MxNoiseHaxe {

	static public function aastep(threshold:Float, value:Float):Float {
		var afwidth = Vector2.getDistance(new Vector2(value.dFdx(), value.dFdy()), new Vector2(0, 0)) * 0.70710678118654757;
		return Math.smoothstep(threshold - afwidth, threshold + afwidth, value);
	}

	static public function ramplr(valuel:Float, valuer:Float, texcoord:Vector2 = new Vector2(0, 0)):Float {
		return Math.mix(valuel, valuer, texcoord.x.clamp());
	}

	static public function ramptb(valuet:Float, valueb:Float, texcoord:Vector2 = new Vector2(0, 0)):Float {
		return Math.mix(valuet, valueb, texcoord.y.clamp());
	}

	static public function splitlr(valuel:Float, valuer:Float, center:Float, texcoord:Vector2 = new Vector2(0, 0)):Float {
		return Math.mix(valuel, valuer, aastep(center, texcoord.x));
	}

	static public function splittb(valuet:Float, valueb:Float, center:Float, texcoord:Vector2 = new Vector2(0, 0)):Float {
		return Math.mix(valuet, valueb, aastep(center, texcoord.y));
	}

	static public function transformUv(uvScale:Float = 1, uvOffset:Float = 0, uvGeo:Vector2 = new Vector2(0, 0)):Vector2 {
		return uvGeo.multiply(uvScale).add(uvOffset);
	}

	static public function safePower(in1:Float, in2:Float = 1):Float {
		return Math.abs(in1).pow(in2) * Math.sign(in1);
	}

	static public function contrast(input:Float, amount:Float = 1, pivot:Float = 0.5):Float {
		return (input - pivot) * amount + pivot;
	}

	static public function noiseFloat(texcoord:Vector2 = new Vector2(0, 0), amplitude:Float = 1, pivot:Float = 0):Float {
		return MxNoise.perlinNoiseFloat(texcoord) * amplitude + pivot;
	}

	static public function noiseVec3(texcoord:Vector2 = new Vector2(0, 0), amplitude:Float = 1, pivot:Float = 0):Vector3 {
		return MxNoise.perlinNoiseVec3(texcoord).multiply(amplitude).add(new Vector3(pivot, pivot, pivot));
	}

	static public function noiseVec4(texcoord:Vector2 = new Vector2(0, 0), amplitude:Float = 1, pivot:Float = 0):Vector<Float> {
		var noiseVec4:Vector<Float> = new Vector<Float>();
		noiseVec4.push(MxNoise.perlinNoiseVec3(texcoord).x * amplitude + pivot);
		noiseVec4.push(MxNoise.perlinNoiseVec3(texcoord).y * amplitude + pivot);
		noiseVec4.push(MxNoise.perlinNoiseVec3(texcoord).z * amplitude + pivot);
		noiseVec4.push(MxNoise.perlinNoiseFloat(texcoord.add(new Vector2(19, 73))) * amplitude + pivot);
		return noiseVec4;
	}

	static public function worleyNoiseFloat(texcoord:Vector2 = new Vector2(0, 0), jitter:Float = 1):Float {
		return MxNoise.worleyNoiseFloat(texcoord, jitter, 1);
	}

	static public function worleyNoiseVec2(texcoord:Vector2 = new Vector2(0, 0), jitter:Float = 1):Vector2 {
		return MxNoise.worleyNoiseVec2(texcoord, jitter, 1);
	}

	static public function worleyNoiseVec3(texcoord:Vector2 = new Vector2(0, 0), jitter:Float = 1):Vector3 {
		return MxNoise.worleyNoiseVec3(texcoord, jitter, 1);
	}

	static public function cellNoiseFloat(texcoord:Vector2 = new Vector2(0, 0)):Float {
		return MxNoise.cellNoiseFloat(texcoord);
	}

	static public function fractalNoiseFloat(position:Vector2 = new Vector2(0, 0), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = 0.5, amplitude:Float = 1):Float {
		return MxNoise.fractalNoiseFloat(position, octaves, lacunarity, diminish) * amplitude;
	}

	static public function fractalNoiseVec2(position:Vector2 = new Vector2(0, 0), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = 0.5, amplitude:Float = 1):Vector2 {
		return MxNoise.fractalNoiseVec2(position, octaves, lacunarity, diminish).multiply(amplitude);
	}

	static public function fractalNoiseVec3(position:Vector2 = new Vector2(0, 0), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = 0.5, amplitude:Float = 1):Vector3 {
		return MxNoise.fractalNoiseVec3(position, octaves, lacunarity, diminish).multiply(amplitude);
	}

	static public function fractalNoiseVec4(position:Vector2 = new Vector2(0, 0), octaves:Int = 3, lacunarity:Float = 2, diminish:Float = 0.5, amplitude:Float = 1):Vector<Float> {
		var noiseVec4:Vector<Float> = new Vector<Float>();
		noiseVec4.push(MxNoise.fractalNoiseVec3(position, octaves, lacunarity, diminish).x * amplitude);
		noiseVec4.push(MxNoise.fractalNoiseVec3(position, octaves, lacunarity, diminish).y * amplitude);
		noiseVec4.push(MxNoise.fractalNoiseVec3(position, octaves, lacunarity, diminish).z * amplitude);
		noiseVec4.push(MxNoise.fractalNoiseFloat(position, octaves, lacunarity, diminish) * amplitude);
		return noiseVec4;
	}

	// Color functions
	static public var hsvtorgb = MxHsv.hsvtorgb;
	static public var rgbtohsv = MxHsv.rgbtohsv;
	static public var srgbTextureToLinRec709 = MxTransformColor.srgbTextureToLinRec709;

}