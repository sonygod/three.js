import js.Browser;
import js.Lib;
import js.html.HTMLElement;
import js.html.HTMLCanvasElement;
import js.html.ImageData;
import js.html.Window;
import js.html._CanvasRenderingContext2D;
import js.html._WebGLRenderingContext;
import js.node.Buffer;
import js.node.Fs;
import js.node.Path;
import js.node.Process;
import js.node.process;
import js.sys.FileSystem;
import js.sys.net.URL;
import js.sys.net.URLConnection;
import js.sys.net.WebSocket;
import js.sys.NodeJs;
import js.sys.Sys;
class BASIS {
	public static var wasmBinary : Bytes;
	public static var wasmMemory : Bytes;
	public static var wasmTable : Dynamic;
	public static var preRun : Array<Function>;
	public static var init : Array<Function>;
	public static var preMain : Array<Function>;
	public static var postRun : Array<Function>;
	public static var calledRun : Bool;
	public static var noExitRuntime : Bool;
	public static var wasmBinaryFile : String;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var wasmJS : Dynamic;
	public static var wasmModule : Dynamic;
	public static var tempRet0 : Int;
	public static var setTempRet0 : Function;
	public static var tempDoubleRet0 : Float;
	public static var setTempDoubleRet0 : Function;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var preloadedImages : Dynamic;
	public static var preloadedAudios : Dynamic;
	public static var dataURIPrefix : String;
	public static var fileURIPrefix : String;
	public static var wasmBinary : Bytes;
	public static var wasmMemory : Bytes;
	public static var wasmTable : Dynamic;
	public static var preRun : Array<Function>;
	public static var init : Array<Function>;
	public static var preMain : Array<Function>;
	public static var postRun : Array<Function>;
	public static var calledRun : Bool;
	public static var noExitRuntime : Bool;
	public static var wasmBinaryFile : String;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var wasmJS : Dynamic;
	public static var wasmModule : Dynamic;
	public static var tempRet0 : Int;
	public static var setTempRet0 : Function;
	public static var tempDoubleRet0 : Float;
	public static var setTempDoubleRet0 : Function;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var preloadedImages : Dynamic;
	public static var preloadedAudios : Dynamic;
	public static var dataURIPrefix : String;
	public static var fileURIPrefix : String;
	public static var wasmBinary : Bytes;
	public static var wasmMemory : Bytes;
	public static var wasmTable : Dynamic;
	public static var preRun : Array<Function>;
	public static var init : Array<Function>;
	public static var preMain : Array<Function>;
	public static var postRun : Array<Function>;
	public static var calledRun : Bool;
	public static var noExitRuntime : Bool;
	public static var wasmBinaryFile : String;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var wasmJS : Dynamic;
	public static var wasmModule : Dynamic;
	public static var tempRet0 : Int;
	public static var setTempRet0 : Function;
	public static var tempDoubleRet0 : Float;
	public static var setTempDoubleRet0 : Function;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var preloadedImages : Dynamic;
	public static var preloadedAudios : Dynamic;
	public static var dataURIPrefix : String;
	public static var fileURIPrefix : String;
	public static var wasmBinary : Bytes;
	public static var wasmMemory : Bytes;
	public static var wasmTable : Dynamic;
	public static var preRun : Array<Function>;
	public static var init : Array<Function>;
	public static var preMain : Array<Function>;
	public static var postRun : Array<Function>;
	public static var calledRun : Bool;
	public static var noExitRuntime : Bool;
	public static var wasmBinaryFile : String;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var wasmJS : Dynamic;
	public static var wasmModule : Dynamic;
	public static var tempRet0 : Int;
	public static var setTempRet0 : Function;
	public static var tempDoubleRet0 : Float;
	public static var setTempDoubleRet0 : Function;
	public static var ABORT : Bool;
	public static var EXITSTATUS : Int;
	public static var preloadedImages : Dynamic;
	public static var preloadedAudios : Dynamic;
	public static var dataURIPrefix : String;
	public static var fileURIPrefix : String;
	public static function ready() : Promise<Bool> {
		var promise = new Promise<Bool>(function(resolve, reject) {
			resolve(true);
		});
		return promise;
	}
	public static function init() {
		var Module = {
			ready : BASIS.ready,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable : BASIS.wasmTable,
			preRun : BASIS.preRun,
			init : BASIS.init,
			preMain : BASIS.preMain,
			postRun : BASIS.postRun,
			calledRun : BASIS.calledRun,
			noExitRuntime : BASIS.noExitRuntime,
			wasmBinaryFile : BASIS.wasmBinaryFile,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			wasmJS : BASIS.wasmJS,
			wasmModule : BASIS.wasmModule,
			tempRet0 : BASIS.tempRet0,
			setTempRet0 : BASIS.setTempRet0,
			tempDoubleRet0 : BASIS.tempDoubleRet0,
			setTempDoubleRet0 : BASIS.setTempDoubleRet0,
			ABORT : BASIS.ABORT,
			EXITSTATUS : BASIS.EXITSTATUS,
			preloadedImages : BASIS.preloadedImages,
			preloadedAudios : BASIS.preloadedAudios,
			dataURIPrefix : BASIS.dataURIPrefix,
			fileURIPrefix : BASIS.fileURIPrefix,
			wasmBinary : BASIS.wasmBinary,
			wasmMemory : BASIS.wasmMemory,
			wasmTable :