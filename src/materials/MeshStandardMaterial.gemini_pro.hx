import js.html.CanvasElement;
import js.html.ImageData;
import js.html.ImageElement;
import js.html.HTMLCanvasElement;
import js.html.HTMLImageElement;
import js.lib.Array;
import js.lib.Float32Array;
import js.lib.Math;
import js.lib.Uint8Array;

import three.constants.TangentSpaceNormalMap;
import three.math.Color;
import three.math.Euler;
import three.math.Vector2;
import three.materials.Material;

class MeshStandardMaterial extends Material {

	public var isMeshStandardMaterial:Bool = true;

	public var defines:Dynamic = { 'STANDARD': '' };

	public var type:String = 'MeshStandardMaterial';

	public var color:Color = new Color(0xffffff); // diffuse
	public var roughness:Float = 1.0;
	public var metalness:Float = 0.0;

	public var map:CanvasElement = null;

	public var lightMap:CanvasElement = null;
	public var lightMapIntensity:Float = 1.0;

	public var aoMap:CanvasElement = null;
	public var aoMapIntensity:Float = 1.0;

	public var emissive:Color = new Color(0x000000);
	public var emissiveIntensity:Float = 1.0;
	public var emissiveMap:CanvasElement = null;

	public var bumpMap:CanvasElement = null;
	public var bumpScale:Float = 1;

	public var normalMap:CanvasElement = null;
	public var normalMapType:Int = TangentSpaceNormalMap;
	public var normalScale:Vector2 = new Vector2(1, 1);

	public var displacementMap:CanvasElement = null;
	public var displacementScale:Float = 1;
	public var displacementBias:Float = 0;

	public var roughnessMap:CanvasElement = null;

	public var metalnessMap:CanvasElement = null;

	public var alphaMap:CanvasElement = null;

	public var envMap:CanvasElement = null;
	public var envMapRotation:Euler = new Euler();
	public var envMapIntensity:Float = 1.0;

	public var wireframe:Bool = false;
	public var wireframeLinewidth:Float = 1;
	public var wireframeLinecap:String = 'round';
	public var wireframeLinejoin:String = 'round';

	public var flatShading:Bool = false;

	public var fog:Bool = true;

	public function new(parameters:Dynamic = null) {
		super();
		this.setValues(parameters);
	}

	public function copy(source:MeshStandardMaterial):MeshStandardMaterial {
		super.copy(source);
		this.defines = { 'STANDARD': '' };
		this.color.copy(source.color);
		this.roughness = source.roughness;
		this.metalness = source.metalness;
		this.map = source.map;
		this.lightMap = source.lightMap;
		this.lightMapIntensity = source.lightMapIntensity;
		this.aoMap = source.aoMap;
		this.aoMapIntensity = source.aoMapIntensity;
		this.emissive.copy(source.emissive);
		this.emissiveMap = source.emissiveMap;
		this.emissiveIntensity = source.emissiveIntensity;
		this.bumpMap = source.bumpMap;
		this.bumpScale = source.bumpScale;
		this.normalMap = source.normalMap;
		this.normalMapType = source.normalMapType;
		this.normalScale.copy(source.normalScale);
		this.displacementMap = source.displacementMap;
		this.displacementScale = source.displacementScale;
		this.displacementBias = source.displacementBias;
		this.roughnessMap = source.roughnessMap;
		this.metalnessMap = source.metalnessMap;
		this.alphaMap = source.alphaMap;
		this.envMap = source.envMap;
		this.envMapRotation.copy(source.envMapRotation);
		this.envMapIntensity = source.envMapIntensity;
		this.wireframe = source.wireframe;
		this.wireframeLinewidth = source.wireframeLinewidth;
		this.wireframeLinecap = source.wireframeLinecap;
		this.wireframeLinejoin = source.wireframeLinejoin;
		this.flatShading = source.flatShading;
		this.fog = source.fog;
		return this;
	}

}