class WebGLBufferRenderer {

	public var gl: WebGLRenderingContext;
	public var extensions: WebGLRenderingContextExtensions;
	public var info: WebGLInfo;
	public var mode: WebGLRenderingContextMode = null;
	public var index: Int = 0;
	public var type: WebGLRenderingContextType = null;
	public var object: Dynamic = null;

	public function new(backend: Dynamic) {
		this.gl = backend.gl;
		this.extensions = backend.extensions;
		this.info = backend.renderer.info;
	}

	public function render(start: Int, count: Int): Void {

		if (index != 0) {
			gl.drawElements(mode, count, type, start);
		} else {
			gl.drawArrays(mode, start, count);
		}

		info.update(object, count, mode, 1);

	}

	public function renderInstances(start: Int, count: Int, primcount: Int): Void {

		if (primcount == 0) return;

		if (index != 0) {
			gl.drawElementsInstanced(mode, count, type, start, primcount);
		} else {
			gl.drawArraysInstanced(mode, start, count, primcount);
		}

		info.update(object, count, mode, primcount);

	}

	public function renderMultiDraw(starts: Array<Int>, counts: Array<Int>, drawCount: Int): Void {

		if (drawCount == 0) return;

		var extension = extensions.get('WEBGL_multi_draw');

		if (extension == null) {

			for (i in 0...drawCount) {
				this.render(starts[i], counts[i]);
			}

		} else {

			if (this.index != 0) {
				extension.multiDrawElementsWEBGL(mode, counts, 0, this.type, starts, 0, drawCount);
			} else {
				extension.multiDrawArraysWEBGL(mode, starts, 0, counts, 0, drawCount);
			}

			var elementCount: Int = 0;
			for (i in 0...drawCount) {
				elementCount += counts[i];
			}

			info.update(object, elementCount, mode, 1);

		}

	}

	public function renderMultiDrawInstances(starts: Array<Int>, counts: Array<Int>, drawCount: Int, primcount: Array<Int>): Void {

		if (drawCount == 0) return;

		var extension = extensions.get('WEBGL_multi_draw');

		if (extension == null) {

			for (i in 0...drawCount) {
				this.renderInstances(starts[i], counts[i], primcount[i]);
			}

		} else {

			if (this.index != 0) {
				extension.multiDrawElementsInstancedWEBGL(mode, counts, 0, this.type, starts, 0, primcount, 0, drawCount);
			} else {
				extension.multiDrawArraysInstancedWEBGL(mode, starts, 0, counts, 0, primcount, 0, drawCount);
			}

			var elementCount: Int = 0;

			for (i in 0...drawCount) {
				elementCount += counts[i];
			}

			for (i in 0...primcount.length) {
				info.update(object, elementCount, mode, primcount[i]);
			}

		}

	}

}