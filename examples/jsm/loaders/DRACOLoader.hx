import js.html.FileLoader;
import js.typedarrays.Float32Array;
import js.typedarrays.Int32Array;
import js.typedarrays.Uint8Array;
import js.typedarrays.Uint32Array;
import js.flash.DracoDecoderModule;
import js.flash.DracoDecoder;
import js.flash.DracoGeometry;
import js.flash.DracoMesh;
import js.flash.DracoPointCloud;
import js.flash.DracoAttribute;
import js.flash.DracoAttributeType;
import js.flash.DracoAttributeData;
import js.flash.DracoAttributeDataArray;
import js.flash.DracoAttributeDataUint32Array;
import js.flash.DracoEncodedGeometryType;
import js.flash.DracoStatus;
import js.flash.DracoAttributeDataFloat32Array;
import js.flash.DracoAttributeDataInt8Array;
import js.flash.DracoAttributeDataInt16Array;
import js.flash.DracoAttributeDataInt32Array;
import js.flash.DracoAttributeDataUint8Array;
import js.flash.DracoAttributeDataUint16Array;
import js.flash.DracoAttributeDataUint32Array;
import js.flash.DracoDecoderModuleLoader;
import js.flash.DracoDecoderModule;
import js.flash.DracoAttributeDataView;
import js.flash.DracoValueType;

class DRACOLoader {

	private _taskCache:Map<Dynamic,Dynamic>;
	private decoderPath:String;
	private decoderConfig:Dynamic;
	private decoderBinary:Dynamic;
	private decoderPending:Dynamic;
	private workerLimit:Int;
	private workerPool:Array<Dynamic>;
	private workerNextTaskID:Int;
	private workerSourceURL:String;
	private defaultAttributeIDs:Dynamic;
	private defaultAttributeTypes:Dynamic;

	public function new(manager:Dynamic) {
		super(manager);
		this._taskCache = new Map();
		this.decoderPath = "";
		this.decoderConfig = {};
		this.decoderBinary = null;
		this.decoderPending = null;
		this.workerLimit = 4;
		this.workerPool = [];
		this.workerNextTaskID = 1;
		this.workerSourceURL = "";
		this.defaultAttributeIDs = {
			position: "POSITION",
			normal: "NORMAL",
			color: "COLOR",
			uv: "TEX_COORD"
		};
		this.defaultAttributeTypes = {
			position: Float32Array,
			normal: Float32Array,
			color: Float32Array,
			uv: Float32Array
		};
	}

	// ... (other methods)

}