import hl.types.Int;
import hl.types.Float;
import hl.types.Bool;
import hl.types.Array;
import hl.types.Null;
import hl.types.Tuple;
import hl.types.Static;
import hl.types.Dynamic;
import hl.types.AmlNode;
import hl.types.AmlNodeType;
import hl.types.AmlType;
import hl.types.AmlField;
import hl.types.AmlFunction;
import hl.types.AmlVariable;
import hl.types.AmlStruct;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import haxe.ds.Null<Dynamic>;
import haxe.ds.Null<Float>;
import haxe.ds.Null<Int>;
import haxe.ds.Null<Bool>;
import haxe.ds.Null<Array<Dynamic>>;
import haxe.ds.Null<Array<Float>>;
import haxe.ds.Null<Array<Int>>;
import haxe.ds.Null<Array<Bool>>;
import haxe.ds.Null<Array<Array<Dynamic>>>;
import haxe.ds.Null<Array<Array<Float>>>;
import haxe.ds.Null<Array<Array<Int>>>;
import haxe.ds.Null<Array<Array<Bool>>>;
import js.Js;

class MxNoise {

	public static function mx_select(b:Bool, t:Float, f:Float):Float {
		return b.toBool() ? t : f;
	}

	public static function mx_negate_if(val:Float, b:Bool):Float {
		return b.toBool() ? -val : val;
	}

	public static function mx_floor(x:Float):Int {
		return x.toInt();
	}

	public static function mx_floorfrac(x:Float, i:Int):Float {
		i.set(x.toInt());
		return x - i.toFloat();
	}

	public static function mx_bilerp_0(v0:Float, v1:Float, v2:Float, v3:Float, s:Float, t:Float):Float {
		return (1.0 - t) * (v0 * (1.0 - s) + v1 * s) + t * (v2 * (1.0 - s) + v3 * s));
	}

	public static function mx_bilerp_1(v0:Vec3, v1:Vec3, v2:Vec3, v3:Vec3, s:Float, t:Float):Vec3 {
		return (1.0 - t) * (v0 * (1.0 - s) + v1 * s) + t * (v2 * (1.0 - s) + v3 * s);
	}

	public static function mx_bilerp(v0:Dynamic, v1:Dynamic, v2:Dynamic, v3:Dynamic, s:Float, t:Float):Dynamic {
		return switch (Std.int(v0)) {
			case 0:
				return mx_bilerp_0(Std.float(v0), Std.float(v1), Std.float(v2), Std.float(v3), s, t);
			case 1:
				return mx_bilerp_1(Std.vec3(v0), Std.vec3(v1), Std.vec3(v2), Std.vec3(v3), s, t);
			default:
				throw "Invalid type for bilerp";
		}
	}

	// ... continue defining the rest of the functions ...

}