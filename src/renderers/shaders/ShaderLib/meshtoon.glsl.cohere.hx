package;

import openfl.display.DisplayObject;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Context3DProfile;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.geom.Rectangle;

class ToonShader extends Shader {
	public var diffuse:ShaderParameter;
	public var emissive:ShaderParameter;
	public var opacity:ShaderParameter;

	public function new() {
		super();

		vertexString =
			"#define TOON\n" +
			"varying vec3 vViewPosition;\n" +
			"attribute vec4 aVertexPosition;\n" +
			"attribute vec2 aTextureCoord;\n" +
			"attribute vec3 aVertexNormal;\n" +
			"uniform mat4 uProjectionMatrix;\n" +
			"uniform mat4 uModelViewMatrix;\n" +
			"uniform mat3 uNormalMatrix;\n" +
			"uniform vec3 uAmbientColor;\n" +
			"uniform vec3 uLightingDirection;\n" +
			"uniform bool uEnableLighting;\n" +
			"varying vec2 vTextureCoord;\n" +
			"varying vec3 vLightingDirection;\n" +
			"varying vec3 vAmbientLight;\n" +
			"void main(void) {\n" +
			"   gl_Position = uProjectionMatrix * uModelViewMatrix * aVertexPosition;\n" +
			"   vTextureCoord = aTextureCoord;\n" +
			"   vViewPosition = (uModelViewMatrix * aVertexPosition).xyz;\n" +
			"   vec3 transformedNormal = uNormalMatrix * aVertexNormal;\n" +
			"   vAmbientLight = uAmbientColor;\n" +
			"   if (uEnableLighting) {\n" +
			"       vLightingDirection = normalize((uModelViewMatrix * vec4(uLightingDirection, 0.0)).xyz);\n" +
			"   }\n" +
			"}";

		fragmentString =
			"#define TOON\n" +
			"varying vec3 vViewPosition;\n" +
			"varying vec2 vTextureCoord;\n" +
			"varyambigua3 vLightingDirection;\n" +
			"varying vec3 vAmbientLight;\n" +
			"uniform vec3 diffuse;\n" +
			"uniform vec3 emissive;\n" +
			"uniform float opacity;\n" +
			"uniform sampler2D uSampler;\n" +
			"void main(void) {\n" +
			"   vec4 textureColor = texture2D(uSampler, vTextureCoord);\n" +
			"   vec3 normal = normalize(vViewPosition);\n" +
			"   float directionalLightWeight = max(dot(normal, normalize(vLightingDirection)), 0.0);\n" +
			"   vec3 lightWeight = (vec3(1.0) - step(0.1, abs(normal.x))) + (vec3(1.0) - step(0.1, abs(normal.y))) + (vec3(1.0) - step(0.1, abs(normal.z)));\n" +
			"   vec3 lightColor = vec3(0.3) * vAmbientLight + vec3(0.7) * lightWeight * vec3(directionalLightWeight);\n" +
			"   gl_FragColor = vec4(textureColor.rgb * lightColor * diffuse + emissive, textureColor.a * opacity);\n" +
			"}";
	}
}

class Main extends Sprite {
	public function new() {
		super();

		var shader:ToonShader = new ToonShader();
		shader.addEventListener(Event.COMPLETE, onShaderComplete);
		shader.load();
	}

	public function onShaderComplete(e:Event):Void {
		var shader:ToonShader = cast(e.target, ToonShader);
		var container:DisplayObjectContainer = new DisplayObjectContainer();
		container.x = 100.0;
		container.y = 100.0;
		addChild(container);

		var graphics:Graphics = new Graphics();
		graphics.beginFill(0xFFFFFF, 1.0);
		graphics.drawRect(0, 0, 100, 100);
		graphics.endFill();
		var sprite:Sprite = new Sprite();
		sprite.graphics = graphics;
		sprite.x = -50.0;
		sprite.y = -50.0;
		container.addChild(sprite);

		var bitmapData:BitmapData = new BitmapData(100, 100, false, 0x00000000);
		var shaderInput:ShaderInput = new ShaderInput(bitmapData, "uSampler");
		var shaderParameter:ShaderParameter = shader.getShaderParameter("uSampler");
		shaderParameter.value = shaderInput;

		var context3D:Context3D = openfl.display3D.Context3D.create(null, 0, 0, null, null, 0, null, Context3DProfile.BASELINE);
		var vertexBuffer:VertexBuffer3D = context3D.createVertexBuffer(8, Context3DVertexBufferFormat.FLOAT_3);
		var indexBuffer:IndexBuffer3D = context3D.createIndexBuffer(6);
		var matrix3D:Matrix3D = new Matrix3D();
		var vector3D:Vector3D = new Vector3D();
		var rectangle:Rectangle = new Rectangle(0, 0, 100, 100);
		var indices:Array<Int> = [0, 1, 2, 2, 3, 0];
		var vertices:Array<Float> = [
			-1.0, -1.0, 0.0,
			1.0, -1.0, 0.0,
			1.0, 1.0, 0.0,
			-1.0, 1.0, 0.0
		];

		var program:Int = context3D.createProgram();
		context3D.uploadIndices(indexBuffer, 0, indices);
		context3D.uploadVertexBuffer(vertexBuffer, 0, vertices);
		context3D.setVertexBufferAt(program, 0, vertexBuffer, 0, Context3DProgramType.FRAGMENT);
		context3D.setProgram(program);
		context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix3D, true);
		context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 1, vector3D, 3);
		context3D.setProgramConstantsFromRectangle(Context3DProgramType.VERTEX, 2, rectangle, true);

		container.shader = shader;
	}
}

var main:Main = new Main();
addChild(main);