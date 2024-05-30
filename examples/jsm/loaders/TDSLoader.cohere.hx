import haxe.io.Bytes;
import js.Browser.window;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Uint8Array;

class TDSLoader {
    public var group:Group;
    public var materials:Array<MeshPhongMaterial>;
    public var meshes:Array<Mesh>;
    public var debug:Bool;
    public var path:String;
    public var manager:Loader;
    public var requestHeader:String;
    public var withCredentials:Bool;

    public function new(manager:Loader) {
        super(manager);
        this.debug = false;
        this.group = null;
        this.materials = [];
        this.meshes = [];
    }

    public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var scope = this;
        var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
        var loader = new FileLoader(this.manager);
        loader.path = this.path;
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(data) {
            try {
                onLoad(scope.parse(data, path));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(arraybuffer:Bytes, path:String):Group {
        this.group = new Group();
        this.materials = [];
        this.meshes = [];
        this.readFile(arraybuffer, path);
        for (i in 0...this.meshes.length) {
            this.group.add(this.meshes[i]);
        }
        return this.group;
    }

    public function readFile(arraybuffer:Bytes, path:String):Void {
        var data = new DataView(arraybuffer);
        var chunk = new Chunk(data, 0, this.debugMessage);
        if (chunk.id == MLIBMAGIC || chunk.id == CMAGIC || chunk.id == M3DMAGIC) {
            var next = chunk.readChunk();
            while (next != null) {
                if (next.id == M3D_VERSION) {
                    var version = next.readDWord();
                    this.debugMessage('3DS file version: ' + version);
                } else if (next.id == MDATA) {
                    this.readMeshData(next, path);
                } else {
                    this.debugMessage('Unknown main chunk: ' + next.hexId);
                }
                next = chunk.readChunk();
            }
        }
        this.debugMessage('Parsed ' + this.meshes.length + ' meshes');
    }

    public function readMeshData(chunk:Chunk, path:String):Void {
        var next = chunk.readChunk();
        while (next != null) {
            if (next.id == MESH_VERSION) {
                var version = next.readDWord();
                this.debugMessage('Mesh Version: ' + version);
            } else if (next.id == MASTER_SCALE) {
                var scale = next.readFloat();
                this.debugMessage('Master scale: ' + scale);
                this.group.scale.set(scale, scale, scale);
            } else if (next.id == NAMED_OBJECT) {
                this.debugMessage('Named Object');
                this.readNamedObject(next);
            } else if (next.id == MAT_ENTRY) {
                this.debugMessage('Material');
                this.readMaterialEntry(next, path);
            } else {
                this.debugMessage('Unknown MDATA chunk: ' + next.hexId);
            }
            next = chunk.readChunk();
        }
    }

    public function readNamedObject(chunk:Chunk):Void {
        var name = chunk.readString();
        var next = chunk.readChunk();
        while (next != null) {
            if (next.id == N_TRI_OBJECT) {
                var mesh = this.readMesh(next);
                mesh.name = name;
                this.meshes.push(mesh);
            } else {
                this.debugMessage('Unknown named object chunk: ' + next.hexId);
            }
            next = chunk.readChunk();
        }
    }

    public function readMaterialEntry(chunk:Chunk, path:String):Void {
        var next = chunk.readChunk();
        var material = new MeshPhongMaterial();
        while (next != null) {
            if (next.id == MAT_NAME) {
                material.name = next.readString();
                this.debugMessage('Name: ' + material.name);
            } else if (next.id == MAT_WIRE) {
                this.debugMessage('Wireframe');
                material.wireframe = true;
            } else if (next.id == MAT_WIRE_SIZE) {
                var value = next.readByte();
                material.wireframeLinewidth = value;
                this.debugMessage('Wireframe Thickness: ' + value);
            } else if (next.id == MAT_TWO_SIDE) {
                material.side = DoubleSide;
                this.debugMessage('DoubleSided');
            } else if (next.id == MAT_ADDITIVE) {
                this.debugMessage('Additive Blending');
                material.blending = AdditiveBlending;
            } else if (next.id == MAT_DIFFUSE) {
                this.debugMessage('Diffuse Color');
                material.color = this.readColor(next);
            } else if (next.id == MAT_SPECULAR) {
                this.debug