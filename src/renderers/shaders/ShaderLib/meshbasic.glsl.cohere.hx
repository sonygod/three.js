package;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.VertexBuffer3DData;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;

class ShaderMaterial extends Sprite implements IEventDispatcher {

	private var _shader:Shader;
	private var _context:Context3D;
	private var _vertexBuffer:VertexBuffer3D;
	private var _indexBuffer:IndexBuffer3D;

	private var _uniforms:Array<ShaderParameter>;
	private var _attributes:Array<ShaderInput>;

	private var _width:Int;
	private var _height:Int;

	private var _transparent:Bool;

	public function new(vertex:String, fragment:String, width:Int = 1, height:Int = 1, transparent:Bool = true) {
		super();

		_width = width;
		_height = height;
		_transparent = transparent;

		_context = openfl.Lib.current.stage3D.context3D;
		_context.enableErrorChecking = true;

		_shader = _context.createShader(Context3DProgramType.VERTEX_SHADER, vertex);
		_context.uploadShader(_shader);

		_shader = _context.createShader(Context3DProgramType.FRAGMENT_SHADER, fragment);
		_context.uploadShader(_shader);

		_shader = _context.createProgram();
		_context.attachShader(_shader, _context.getShaderByByteCode(_context.createVertexShaderByteCode(_shader)));
		_context.attachShader(_shader, _context.getShaderByByteCode(_context.createFragmentShaderByteCode(_shader)));
		_context.linkProgram(_shader);

		_context.setProgram(_shader);

		_uniforms = _context.getUniforms();
		_attributes = _context.getVertexDeclaration();

		_vertexBuffer = _context.createVertexBuffer(Context3DVertexBufferFormat.FLOAT_3, 4, 4);
		_indexBuffer = _context.createIndexBuffer(6);

		var vertices:Float32Array = _vertexBuffer.uploadFromArray(Context3DVertexBufferFormat.FLOAT_3, [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1]);
		var indices:Uint16Array = _indexBuffer.uploadFromArray([0, 1, 2, 0, 2, 3]);

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(e:Event):Void {
		_context.setBlendFactors(_transparent ? BlendMode.NORMAL : BlendMode.NONE);
		_context.setProgram(_shader);

		_context.setVertexBufferAt(_vertexBuffer, 0, 0, Context3DVertexBufferFormat.FLOAT_3);

		_context.drawTriangles(_indexBuffer);
	}

	public function setUniform(name:String, value:Float):Void {
		_context.setProgram(_shader);
		_context.setProgramConstantsFromMatrix(_uniforms[name], Matrix3D, null, value);
	}

	public function setUniform(name:String, value:Float, count:Int):Void {
		_context.setProgram(_shader);
		_context.setProgramConstantsFromFloatArray(_uniforms[name], value, count);
	}

	public function setUniform(name:String, value:Float, x:Float, y:Float):Void {
		_context.setProgram(_shader);
		_context.setProgramConstantsFromFloat(_uniforms[name], value, x, y);
	}

	public function setUniform(name:String, value:Float, x:Float, y:Float, z:Float):Void {
		_context.setProgram(_shader);
		_context.setProgramConstantsFromFloat(_uniforms[name], value, x, y, z);
	}

	public function setUniform(name:String, value:Float, x:Float, y:Float, z:Float, w:Float):Void {
		_context.setProgram(_shader);
		_context.setProgramConstantsFromFloat(_uniforms[name], value, x, y, z, w);
	}

	public function setUniform(name:String, value:Float, mat:Matrix3D):Void {
		_context.setProgram(_shader);
		_context.setProgramConstantsFromMatrix(_uniforms[name], Matrix3D, null, mat);
	}

	public function setUniform(name:String, value:Float, mat:Matrix3D, transpose:Bool):Void {
		_context.setProgram(_shader);
		_context.setProgramConstantsFromMatrix(_uniforms[name], Matrix3D, transpose, mat);
	}

	public function setUniform(name:String, value:BitmapData):Void {
		_context.setTextureAt(value.getTexture(), 0);
		_context.setProgram(_shader);
		_context.setProgramTexture(_uniforms[name], value.getTexture());
	}

	public function dispatchEvent(event:Event):Bool {
		return EventDispatcher.dispatchEvent(event);
	}

}