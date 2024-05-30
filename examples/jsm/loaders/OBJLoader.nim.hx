import three.js.examples.jsm.loaders.OBJLoader;
import three.js.examples.jsm.loaders.FileLoader;
import three.js.examples.jsm.loaders.Loader;
import three.js.examples.jsm.loaders.Material;
import three.js.examples.jsm.loaders.Mesh;
import three.js.examples.jsm.loaders.MeshPhongMaterial;
import three.js.examples.jsm.loaders.Points;
import three.js.examples.jsm.loaders.PointsMaterial;
import three.js.examples.jsm.loaders.Vector3;
import three.js.examples.jsm.loaders.Color;
import three.js.examples.jsm.loaders.BufferGeometry;
import three.js.examples.jsm.loaders.Float32BufferAttribute;
import three.js.examples.jsm.loaders.Group;
import three.js.examples.jsm.loaders.LineBasicMaterial;
import three.js.examples.jsm.loaders.LineSegments;

// o object_name | g group_name
const _object_pattern:RegExp = ~/^[og]\s*(.+)?/;
// mtllib file_reference
const _material_library_pattern:RegExp = ~/^mtllib /;
// usemtl material_name
const _material_use_pattern:RegExp = ~/^usemtl /;
// usemap map_name
const _map_use_pattern:RegExp = ~/^usemap /;
const _face_vertex_data_separator_pattern:RegExp = ~/\s+/;

const _vA:Vector3 = new Vector3();
const _vB:Vector3 = new Vector3();
const _vC:Vector3 = new Vector3();

const _ab:Vector3 = new Vector3();
const _cb:Vector3 = new Vector3();

const _color:Color = new Color();

class ParserState {

    public var objects:Array<Dynamic>;
    public var object:Dynamic;

    public var vertices:Array<Dynamic>;
    public var normals:Array<Dynamic>;
    public var colors:Array<Dynamic>;
    public var uvs:Array<Dynamic>;

    public var materials:Dynamic;
    public var materialLibraries:Array<Dynamic>;

    public function new() {
        this.objects = [];
        this.object = {};

        this.vertices = [];
        this.normals = [];
        this.colors = [];
        this.uvs = [];

        this.materials = {};
        this.materialLibraries = [];

        this.startObject("", false);
    }

    public function startObject(name:String, fromDeclaration:Bool) {
        // ...
    }

    public function finalize() {
        // ...
    }

    public function parseVertexIndex(value:String, len:Int) {
        // ...
    }

    public function parseNormalIndex(value:String, len:Int) {
        // ...
    }

    public function parseUVIndex(value:String, len:Int) {
        // ...
    }

    public function addVertex(a:Int, b:Int, c:Int) {
        // ...
    }

    public function addVertexPoint(a:Int) {
        // ...
    }

    public function addVertexLine(a:Int) {
        // ...
    }

    public function addNormal(a:Int, b:Int, c:Int) {
        // ...
    }

    public function addFaceNormal(a:Int, b:Int, c:Int) {
        // ...
    }

    public function addColor(a:Int, b:Int, c:Int) {
        // ...
    }

    public function addUV(a:Int, b:Int, c:Int) {
        // ...
    }

    public function addDefaultUV() {
        // ...
    }

    public function addUVLine(a:Int) {
        // ...
    }

    public function addFace(a:String, b:String, c:String, ua:String, ub:String, uc:String, na:String, nb:String, nc:String) {
        // ...
    }

    public function addPointGeometry(vertices:Array<Dynamic>) {
        // ...
    }

    public function addLineGeometry(vertices:Array<Dynamic>, uvs:Array<Dynamic>) {
        // ...
    }

}

class OBJLoader extends Loader {

    public var materials:Dynamic;

    public function new(manager:Loader) {
        super(manager);

        this.materials = null;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        // ...
    }

    public function setMaterials(materials:Dynamic) {
        // ...
    }

    public function parse(text:String) {
        // ...
    }

}

export OBJLoader;