class WebGLBufferRenderer {
	public var gl: WebGLRenderingContext;
	public var extensions: Map<String,Dynamic>;
	public var info: Dynamic;
	public var mode: Int;

	public function new(gl: WebGLRenderingContext, extensions: Map<String,Dynamic>, info: Dynamic) {
		this.gl = gl;
		this.extensions = extensions;
		this.info = info;
	}

	public function setMode(value: Int) {
		mode = value;
	}

	public function render(start: Int, count: Int) {
		gl.drawArrays(mode, start, count);
		info.update(count, mode, 1);
	}

	public function renderInstances(start: Int, count: Int, primcount: Int) {
		if (primcount == 0) return;
		gl.drawArraysInstanced(mode, start, count, primcount);
		info.update(count, mode, primcount);
	}

	public function renderMultiDraw(starts: Array<Int>, counts: Array<Int>, drawCount: Int) {
		if (drawCount == 0) return;
		var extension = extensions.get('WEBGL_multi_draw');
		if (extension == null) {
			for (i in 0...drawCount) {
				this.render(starts[i], counts[i]);
			}
		} else {
			extension.multiDrawArraysWEBGL(mode, starts, 0, counts, 0, drawCount);
			var elementCount = 0;
			for (i in 0...drawCount) {
				elementCount += counts[i];
			}
			info.update(elementCount, mode, 1);
		}
	}

	public function renderMultiDrawInstances(starts: Array<Int>, counts: Array<Int>, drawCount: Int, primcount: Array<Int>) {
		if (drawCount == 0) return;
		var extension = extensions.get('WEBGL_multi_draw');
		if (extension == null) {
			for (i in 0...starts.length) {
				renderInstances(starts[i], counts[i], primcount[i]);
			}
		} else {
			extension.multiDrawArraysInstancedWEBGL(mode, starts, 0, counts, 0, primcount, 0, drawCount);
			var elementCount = 0;
			for (i in 0...drawCount) {
				elementCount += counts[i];
			}
			for (i in 0...primcount.length) {
				info.update(elementCount, mode, primcount[i]);
			}
		}
	}
}