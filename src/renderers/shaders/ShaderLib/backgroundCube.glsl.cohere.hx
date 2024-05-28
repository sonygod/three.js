package;

import openfl.display.DisplayObject;
import openfl.display.Shader;
import openfl.display.Sprite;
import openfl.display.Tilesheet;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;

class ShaderMaterial extends Shader {

	public var envMap:TextureBase;
	public var flipEnvMap:Float;
	public var backgroundBlurriness:Float;
	public var backgroundIntensity:Float;
	public var backgroundRotation:Matrix3D;

	public function new(vertex:String, fragment:String, context:Context3D) {
		super(vertex, fragment, context);
	}

	override public function upload(context:Context3D, sprite:Sprite, interpolation:Float, tilesheet:Tilesheet = null) {
		super.upload(context, sprite, interpolation, tilesheet);

		var program:Program3D = context.activeProgram;
		var gl = context.gl;

		if (envMap != null) {
			context.setTextureAt(program, "envMap", envMap);
		}

		context.setProgramConstantsFromMatrix(program, "backgroundRotation", backgroundRotation, false);
		context.setProgramConstantFromFloat(program, "flipEnvMap", flipEnvMap);
		context.setProgramConstantFromFloat(program, "backgroundBlurriness", backgroundBlurriness);
		context.setProgramConstantFromFloat(program, "backgroundIntensity", backgroundIntensity);
	}

}

class Demo extends Sprite {

	public function new() {
		super();

		addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(event:Event) {
		var stage:DisplayObject = stage;
		var context:Context3D = stage.context3D;

		var vertex:String = "...";
		var fragment:String = "...";

		var shader:ShaderMaterial = ShaderMaterial.fromStrings(context, vertex, fragment);
		shader.envMap = TextureBase.fromFile("env.png");
		shader.flipEnvMap = 1.0;
		shader.backgroundBlurriness = 0.0;
		shader.backgroundIntensity = 1.0;
		shader.backgroundRotation = Matrix3D.createRotationX(0.0);

		graphics.beginShaderFill(shader, null, ColorTransform.DEFAULT_CXFORM_ALPHABIT);
		graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		graphics.endFill();
	}

}