package;

import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Output;
import js.Browser;
import js.typedarrays.Uint8Array;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IMemoryRange;

class EXRLoader extends openfl.display.BitmapData {

	public function new() {
		super(0, 0);
		this.type = haxe.io.DataView.FLOAT;
	}

	public var type:Int;

	private function parse(buffer:ArrayBuffer):Dynamic {
		// ... (same implementation as JavaScript code)
	}

	public function setDataType(value:Int):EXRLoader {
		this.type = value;
		return this;
	}

	public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
		// ... (same implementation as JavaScript code)
	}

}