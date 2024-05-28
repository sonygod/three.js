import js.Browser.Window;
import js.html.CanvasElement;
import js.html.HtmlElement;
import js.html.ImageElement;
import js.html.MediaError;
import js.html.VideoElement;
import js.html._CanvasRenderingContext2D;
import js.html._WebGLRenderingContext;
import js.typedarray.ArrayBuffer;
import js.typedarray.Float32Array;
import js.typedarray.Int16Array;
import js.typedarray.Int32Array;
import js.typedarray.Int8Array;
import js.typedarray.Uint16Array;
import js.typedarray.Uint32Array;
import js.typedarray.Uint8Array;
import js.webgl.EXTTextureFilterAnisotropic;
import js.webgl.EXTTextureLOD;
import js.webgl.WebGLActiveInfo;
import js.webgl.WebGLBuffer;
import js.webgl.WebGLContextAttributes;
import js.webgl.WebGLContextEvent;
import js.webgl.WebGLFramebuffer;
import js.webgl.WebGLProgram;
import jsMultiplier.js.webgl.WebGLRenderbuffer;
import js.webgl.WebGLShader;
import js.webgl.WebGLShaderPrecisionFormat;
import js.webgl.WebGLSync;
import js.webgl.WebGLTexture;
import js.webgl.WebGLUniformLocation;
import js.webgl.WebGLVertexArrayObject;

class ShadowMaterial extends Material {
	public var isShadowMaterial:Bool;
	public var type:String;
	public var color:Color;
	public var transparent:Bool;
	public var fog:Bool;

	public function new(parameters:Dynamic) {
		super();
		isShadowMaterial = true;
		type = 'ShadowMaterial';
		color = new Color(0x000000);
		transparent = true;
		fog = true;
		setValues(parameters);
	}

	public function copy(source:Dynamic) : Dynamic {
		super.copy(source);
		color.copy(source.color);
		fog = source.fog;
		return this;
	}
}