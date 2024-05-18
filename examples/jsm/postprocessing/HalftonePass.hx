package three.js.examples.jvm.postprocessing;

import three.js.renderers.gl.GLShader;
import three.js.renderers.gl.GLUniforms;
import three.js.renderers.pass.Pass;
import three.js.renderers.pass.FullScreenQuad;
import three.js.shaders.HalftoneShader;

/**
 * RGB Halftone pass for three.js effects composer. Requires HalftoneShader.
 */

class HalftonePass extends Pass {
	
	var uniforms:GLUniforms;
	var material:GLShader;
	var fsQuad:FullScreenQuad;

	public function new(width:Int, height:Int, params:Dynamic) {
		super();
		
		uniforms = GLUniforms.clone(HalftoneShader.uniforms);
		material = new GLShader({
			uniforms: uniforms,
			fragmentShader: HalftoneShader.fragmentShader,
			vertexShader: HalftoneShader.vertexShader
		});
		
		// set params
		uniforms.get("width").value = width;
		uniforms.get("height").value = height;
		
		for (key in Reflect.fields(params)) {
			if (Reflect.hasField(params, key) && Reflect.hasField(uniforms, key)) {
				uniforms.get(key).value = Reflect.field(params, key);
			}
		}
		
		fsQuad = new FullScreenQuad(material);
	}

	public function render(renderer:Renderer, writeBuffer:RenderBuffer, readBuffer:RenderBuffer/*, deltaTime:Float, maskActive:Bool*/) {
		material.uniforms.get("tDiffuse").value = readBuffer.texture;
		
		if (renderToScreen) {
			renderer.setRenderTarget(null);
			fsQuad.render(renderer);
		} else {
			renderer.setRenderTarget(writeBuffer);
			if (clear) renderer.clear();
			fsQuad.render(renderer);
		}
	}

	public function setSize(width:Int, height:Int) {
		uniforms.get("width").value = width;
		uniforms.get("height").value = height;
	}

	public function dispose() {
		material.dispose();
		fsQuad.dispose();
	}
}

// Export the class
#if js
extern class HalftonePass extends Pass {
#else
@:keep
@:expose
class HalftonePass extends Pass {
#end