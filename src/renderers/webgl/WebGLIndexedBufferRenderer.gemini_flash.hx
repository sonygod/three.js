import haxe.ds.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;

class WebGLIndexedBufferRenderer {

	private var _gl:Context3D;
	private var _extensions:Map<String,Dynamic>;
	private var _info:Dynamic; // Assuming this is a class with an update method

	private var _mode:Int;
	private var _type:Int;
	private var _bytesPerElement:Int;

	public function new(gl:Context3D, extensions:Map<String,Dynamic>, info:Dynamic) {
		_gl = gl;
		_extensions = extensions;
		_info = info;
	}

	public function setMode(value:Int):Void {
		_mode = value;
	}

	public function setIndex(value:Dynamic):Void {
		_type = value.type;
		_bytesPerElement = value.bytesPerElement;
	}

	public function render(start:Int, count:Int):Void {
		_gl.drawElements(_mode, count, _type, start * _bytesPerElement);
		_info.update(count, _mode, 1);
	}

	public function renderInstances(start:Int, count:Int, primcount:Int):Void {
		if (primcount == 0) return;
		_gl.drawElementsInstanced(_mode, count, _type, start * _bytesPerElement, primcount);
		_info.update(count, _mode, primcount);
	}

	public function renderMultiDraw(starts:Vector<Int>, counts:Vector<Int>, drawCount:Int):Void {
		if (drawCount == 0) return;

		var extension = _extensions.get("WEBGL_multi_draw");
		if (extension == null) {
			for (i in 0...drawCount) {
				render(starts[i] / _bytesPerElement, counts[i]);
			}
		} else {
			// Assuming extension.multiDrawElementsWEBGL is a function that accepts the same arguments as the WebGL equivalent
			extension.multiDrawElementsWEBGL(_mode, counts, 0, _type, starts, 0, drawCount);
			var elementCount = 0;
			for (i in 0...drawCount) {
				elementCount += counts[i];
			}
			_info.update(elementCount, _mode, 1);
		}
	}

	public function renderMultiDrawInstances(starts:Vector<Int>, counts:Vector<Int>, drawCount:Int, primcount:Vector<Int>):Void {
		if (drawCount == 0) return;

		var extension = _extensions.get("WEBGL_multi_draw");
		if (extension == null) {
			for (i in 0...starts.length) {
				renderInstances(starts[i] / _bytesPerElement, counts[i], primcount[i]);
			}
		} else {
			// Assuming extension.multiDrawElementsInstancedWEBGL is a function that accepts the same arguments as the WebGL equivalent
			extension.multiDrawElementsInstancedWEBGL(_mode, counts, 0, _type, starts, 0, primcount, 0, drawCount);
			var elementCount = 0;
			for (i in 0...drawCount) {
				elementCount += counts[i];
			}
			for (i in 0...primcount.length) {
				_info.update(elementCount, _mode, primcount[i]);
			}
		}
	}

}