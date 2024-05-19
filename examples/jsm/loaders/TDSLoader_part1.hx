import haxe.ds.StringMap;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.net.URLRequest;
import openfl.net.URLRequestHeader;
import openfl.net.URLRequestMethod;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IMemoryRange;
import openfl.utils.SNamedColor;
import tools.debug.Trace;

class TDSLoader extends EventDispatcher {

	public var debug:Bool;
	public var group:Group;
	public var materials:Array<MeshPhongMaterial>;
	public var meshes:Array<Mesh>;

	public function new(manager:EventDispatcher) {
		super();
		this.debug = false;
		this.group = null;
		this.materials = [];
		this.meshes = [];
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope:Dynamic = this;
		var path:String = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.addEventListener(Event.COMPLETE, function(e:Event):Void {
			try {
				onLoad(scope.parse(Type.getUint8Array(e.target.data), path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Trace.error(e);
				}
				scope.manager.itemError(url);
			}
		});
		loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
		loader.load(new URLRequest(url));
	}

	public function parse(arraybuffer:ArrayBufferView, path:String):Group {
		this.group = new Group();
		this.materials = [];
		this.meshes = [];
		this.readFile(arraybuffer, path);
		for (i in 0...this.meshes.length) {
			this.group.addChild(this.meshes[i]);
		}
		return this.group;
	}

	public function readFile(arraybuffer:ArrayBufferView, path:String):Void {
		var data:Dynamic = new DataView(arraybuffer.buffer);
		var chunk:Chunk = new Chunk(data, 0, this.debugMessage);
		if (chunk.id == MLIBMAGIC || chunk.id == CMAGIC || chunk.id == M3DMAGIC) {
			var next:Chunk = chunk.readChunk();
			while (next != null) {
				if (next.id == M3D_VERSION) {
					var version:Int = next.readDWord();
					this.debugMessage('3DS file version: ' + Std.string(version));
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
		var next:Chunk = chunk.readChunk();
		while (next != null) {
			if (next.id == MESH_VERSION) {
				var version:Int = next.readDWord();
				this.debugMessage('Mesh Version: ' + Std.string(version));
			} else if (next.id == MASTER_SCALE) {
				var scale:Float = next.readFloat();
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

	// Other methods omitted for brevity, but they should follow the same pattern

}