import haxe.ds.Float32Array;
import three.math.Vector3;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.Color;
import three.core.DynamicDrawUsage;
import three.core.Mesh;
import three.core.Sphere;

class MarchingCubes extends Mesh {

	public var resolution:Int;
	public var isolation:Float;
	public var size:Int;
	public var size2:Int;
	public var size3:Int;
	public var halfsize:Float;
	public var delta:Float;
	public var yd:Int;
	public var zd:Int;
	public var field:Float32Array;
	public var normal_cache:Float32Array;
	public var palette:Float32Array;
	public var count:Int;
	public var positionArray:Float32Array;
	public var normalArray:Float32Array;
	public var uvArray:Float32Array;
	public var colorArray:Float32Array;
	public var enableUvs:Bool;
	public var enableColors:Bool;
	public var maxVertexCount:Int;
	public var positionAttribute:BufferAttribute;
	public var normalAttribute:BufferAttribute;
	public var uvAttribute:BufferAttribute;
	public var colorAttribute:BufferAttribute;
	public var geometry:BufferGeometry;
	public var init:Void -> Void;
	public var lerp:(Float, Float, Float) -> Float;
	public var VIntX:(Int, Int, Float, Float, Float, Float, Float, Float, Int, Int) -> Void;
	public var VIntY:(Int, Int, Float, Float, Float, Float, Float, Float, Int, Int) -> Void;
	public var VIntZ:(Int, Int, Float, Float, Float, Float, Int, Int, Int, Int) -> Void;
	public var compNorm:(Int) -> Void;
	public var polygonize:(Float, Float, Float, Int, Float) -> Int;
	public var posnormtriv:(Float32Array, Float32Array, Float32Array, Int, Int, Int) -> Void;
	public var addBall:(Float, Float, Float, Float, Float, Float32Array) -> Void;
	public var addPlaneX:(Float, Float) -> Void;
	public var addPlaneY:(Float, Float) -> Void;
	public var addPlaneZ:(Float, Float) -> Void;
	public var setCell:(Int, Int, Int, Float) -> Void;
	public var getCell:(Int, Int, Int) -> Float;
	public var blur:(Float) -> Void;
	public var reset:Void -> Void;
	public var update:Void -> Void;

	public function new(resolution:Int, material:Mesh, enableUvs:Bool=false, enableColors:Bool=false, maxPolyCount:Int=10000) {
		super(new BufferGeometry(), material);
		this.isMarchingCubes = true;

		var scope:Dynamic = this;

		// temp buffers used in polygonize
		var vlist:Float32Array = new Float32Array(12 * 3);
		var nlist:Float32Array = new Float32Array(12 * 3);
		var clist:Float32Array = new Float32Array(12 * 3);

		this.enableUvs = enableUvs;
		this.enableColors = enableColors;

		// functions have to be object properties
		// prototype functions kill performance
		// (tested and it was 4x slower !!!)

		this.init = function (resolution:Int) {
			// implementation here
		}

		// implement other functions here

		this.init(resolution);
	}
}