import three.math.Vector3;
import three.math.Matrix4;
import three.math.Color;
import three.core.Loader;
import three.core.FileLoader;
import three.core.Group;
import three.materials.MeshStandardMaterial;
import three.materials.LineBasicMaterial;
import three.objects.LineSegments;
import three.objects.Mesh;
import three.objects.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Ray;
import three.math.Quaternion;
import three.math.Euler;
import three.math.Box3;
import three.math.Sphere;
import three.math.Frustum;
import three.core.UniformsLib;
import three.core.UniformsUtils;
import three.objects.BufferAttribute;

// Special surface finish tag types.
const FINISH_TYPE_DEFAULT:Int = 0;
const FINISH_TYPE_CHROME:Int = 1;
const FINISH_TYPE_PEARLESCENT:Int = 2;
const FINISH_TYPE_RUBBER:Int = 3;
const FINISH_TYPE_MATTE_METALLIC:Int = 4;
const FINISH_TYPE_METAL:Int = 5;

// State machine to search a subobject path.
const FILE_LOCATION_TRY_PARTS:Int = 0;
const FILE_LOCATION_TRY_P:Int = 1;
const FILE_LOCATION_TRY_MODELS:Int = 2;
const FILE_LOCATION_AS_IS:Int = 3;
const FILE_LOCATION_TRY_RELATIVE:Int = 4;
const FILE_LOCATION_TRY_ABSOLUTE:Int = 5;
const FILE_LOCATION_NOT_FOUND:Int = 6;

const MAIN_COLOUR_CODE:String = "16";
const MAIN_EDGE_COLOUR_CODE:String = "24";

const COLOR_SPACE_LDRAW = three.math.SRGBColorSpace;

class LDrawConditionalLineMaterial extends ShaderMaterial {

	public function new(parameters:Dynamic):Void {
		super(parameters);
	}

	public function get opacity():Float {
		return this.uniforms.opacity.value;
	}

	public function set opacity(value:Float) {
		this.uniforms.opacity.value = value;
	}

	public function get color():Color {
		return this.uniforms.diffuse.value;
	}

}

class ConditionalLineSegments extends LineSegments {

	public function new(geometry:BufferGeometry, material:LDrawConditionalLineMaterial) {
		super(geometry, material);
		this.isConditionalLine = true;
	}

}

function generateFaceNormals(faces:Array<Dynamic>):Void {
	// ...
}

const _ray = new Ray();
function smoothNormals(faces:Array<Dynamic>, lineSegments:Array<Dynamic>, checkSubSegments:Bool = false):Void {
	// ...
}

function isPartType(type:String):Bool {
	return type == "Part" || type == "Unofficial_Part";
}

function isPrimitiveType(type:String):Bool {
	return /primitive/i.test(type) || type == "Subpart";
}

class LineParser {

	public function new(line:String, lineNumber:Int) {
		// ...
	}

	public function seekNonSpace():Void {
		// ...
	}

	public function getToken():String {
		// ...
	}

	public function getVector():Vector3 {
		// ...
	}

	public function getRemainingString():String {
		// ...
	}

	public function isAtTheEnd():Bool {
		// ...
	}

	public function setToEnd():Void {
		// ...
	}

	public function getLineNumberString():String {
		// ...
	}

}

// Fetches and parses an intermediate representation of LDraw parts files.
class LDrawParsedCache {

	public function new(loader:Loader) {
		// ...
	}

	public function cloneResult(original:Dynamic):Dynamic {
		// ...
	}

	public function async fetchData(fileName:String):Promise<String> {
		// ...
	}

	public function parse(text:String, fileName:String = null):Dynamic {
		// ...
	}

	public function getData(fileName:String, clone:Bool = true):Dynamic {
		// ...
	}

	public function ensureDataLoaded(fileName:String):Promise<Dynamic> {
		// ...
	}

	public function setData(fileName:String, text:String) {
		// ...
	}

}

// Class used to parse and build LDraw parts as three.js objects and cache them if they're a "Part" type.
class LDrawPartsGeometryCache {

	public function new(loader:Loader) {
		// ...
	}

	public function processIntoMesh(info:Dynamic):Promise<Group> {
		// ...
	}

	public function hasCachedModel(fileName:String):Bool {
		// ...
	}

	public function getCachedModel(fileName:String):Promise<Group> {
		// ...
	}

	public function loadModel(fileName:String):Promise<Group> {
		// ...
	}

	public function parseModel(text:String):Promise<Group> {
		// ...
	}

}

function sortByMaterial(a:Dynamic, b:Dynamic):Int {
	// ...
}

function createObject(loader:Loader, elements:Array<Dynamic>, elementSize:Int, isConditionalSegments:Bool = false, totalElements:Int = null):Dynamic {
	// ...
}

class LDrawLoader extends Loader {

	public function new(manager:LoaderManager) {
		// ...
	}

	public function setPartsLibraryPath(path:String):Void {
		// ...
	}

	public function preloadMaterials(url:String):Void {
		// ...
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		// ...
	}

	public function parse(text:String, onLoad:Dynamic, onError:Dynamic):Void {
		// ...
	}

	public function setMaterials(materials:Array<Dynamic>):Void {
		// ...
	}

	public function setFileMap(fileMap:Dynamic):Void {
		// ...
	}

	public function addMaterial(material:Dynamic):Void {
		// ...
	}

	public function getMaterial(colorCode:String):Dynamic {
		// ...
	}

	public function applyMaterialsToMesh(group:Group, parentColorCode:String, materialHierarchy:Dynamic, finalMaterialPass:Bool = false):Void {
		// ...
	}

	public function computeBuildingSteps(group:Group):Void {
		// ...
	}

	public function getMainMaterial():Dynamic {
		// ...
	}

	public function getMainEdgeMaterial():Dynamic {
		// ...
	}

}