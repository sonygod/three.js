class WebGLBufferRenderer {

	var gl:Dynamic;
	var extensions:Dynamic;
	var info:Dynamic;
	var mode:Dynamic;
	var index:Int;
	var type:Dynamic;
	var object:Dynamic;

	public function new(backend:Dynamic) {

		this.gl = backend.gl;
		this.extensions = backend.extensions;
		this.info = backend.renderer.info;
		this.mode = null;
		this.index = 0;
		this.type = null;
		this.object = null;

	}

	public function render(start:Int, count:Int) {

		if (this.index != 0) {

			this.gl.drawElements(this.mode, count, this.type, start);

		} else {

			this.gl.drawArrays(this.mode, start, count);

		}

		this.info.update(this.object, count, this.mode, 1);

	}

	public function renderInstances(start:Int, count:Int, primcount:Int) {

		if (primcount == 0) return;

		if (this.index != 0) {

			this.gl.drawElementsInstanced(this.mode, count, this.type, start, primcount);

		} else {

			this.gl.drawArraysInstanced(this.mode, start, count, primcount);

		}

		this.info.update(this.object, count, this.mode, primcount);

	}

	public function renderMultiDraw(starts:Array<Int>, counts:Array<Int>, drawCount:Int) {

		if (drawCount == 0) return;

		var extension = this.extensions.get('WEBGL_multi_draw');

		if (extension == null) {

			for (i in 0...drawCount) {

				this.render(starts[i], counts[i]);

			}

		} else {

			if (this.index != 0) {

				extension.multiDrawElementsWEBGL(this.mode, counts, 0, this.type, starts, 0, drawCount);

			} else {

				extension.multiDrawArraysWEBGL(this.mode, starts, 0, counts, 0, drawCount);

			}

			var elementCount = 0;
			for (i in 0...drawCount) {

				elementCount += counts[i];

			}

			this.info.update(this.object, elementCount, this.mode, 1);

		}

	}

	public function renderMultiDrawInstances(starts:Array<Int>, counts:Array<Int>, drawCount:Int, primcount:Array<Int>) {

		if (drawCount == 0) return;

		var extension = this.extensions.get('WEBGL_multi_draw');

		if (extension == null) {

			for (i in 0...drawCount) {

				this.renderInstances(starts[i], counts[i], primcount[i]);

			}

		} else {

			if (this.index != 0) {

				extension.multiDrawElementsInstancedWEBGL(this.mode, counts, 0, this.type, starts, 0, primcount, 0, drawCount);

			} else {

				extension.multiDrawArraysInstancedWEBGL(this.mode, starts, 0, counts, 0, primcount, 0, drawCount);

			}

			var elementCount = 0;
			for (i in 0...drawCount) {

				elementCount += counts[i];

			}

			for (i in 0...primcount.length) {

				this.info.update(this.object, elementCount, this.mode, primcount[i]);

			}

		}

	}

}