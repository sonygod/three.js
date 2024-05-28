class WebGLIndexedBufferRenderer {
	var mode:Int;
	var type:Int;
	var bytesPerElement:Int;
	var gl:WebGLRenderer;
	var extensions:WebGLExtensions;
	var info:WebGLInfo;

	public function new(gl:WebGLRenderer, extensions:WebGLExtensions, info:WebGLInfo) {
		this.gl = gl;
		this.extensions = extensions;
		this.info = info;
	}

	public function setMode(value:Int):Void {
		mode = value;
	}

	public function setIndex(value:Dynamic):Void {
		type = value.type;
		bytesPerElement = value.bytesPerElement;
	}

	public function render(start:Int, count:Int):Void {
		gl.drawElements(mode, count, type, start * bytesPerElement);
		info.update(count, mode, 1);
	}

	public function renderInstances(start:Int, count:Int, primcount:Int):Void {
		if (primcount == 0) return;
		gl.drawElementsInstanced(mode, count, type, start * bytesPerElement, primcount);
		info.update(count, mode, primcount);
	}

	public function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int):Void {
		if (drawCount == 0) return;
		if (extensions.has('WEBGL_multi_draw')) {
			extensions.get('WEBGL_multi_draw').multiDrawElementsWEBGL(mode, counts, 0, type, starts, 0, drawCount);
			var elementCount:Int = 0;
			for (i in 0...drawCount) {
				elementCount += counts[i];
			}
			info.update(elementCount, mode, 1);
		} else {
			for (i in 0...drawCount) {
				this.render(starts[i] / bytesPerElement, counts[i]);
			}
		}
	}

	public function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcounts:Array<Int>):Void {
		if (drawCount == 0) return;
		if (extensions.has('WEBGL_multi_draw')) {
			extensions.get('WEBGL_multi_draw').multiDrawElementsInstancedWEBGL(mode, counts, 0, type, starts, 0, primcounts, 0, drawCount);
			var elementCount:Int = 0;
			for (i in 0...drawCount) {
				elementCount += counts[i];
			}
			for (i in 0...primcounts.length) {
				info.update(elementCount, mode, primcounts[i]);
			}
		} else {
			for (i in 0...starts.length) {
				renderInstances(starts[i] / bytesPerElement, counts[i], primcounts[i]);
			}
		}
	}
}