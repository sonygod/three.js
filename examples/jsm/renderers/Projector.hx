import three.math.Box3;
import three.math.Color;
import three.math.Frustum;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;

class RenderableObject {

	public var id:Int;
	public var object:Dynamic;
	public var z:Float;
	public var renderOrder:Int;

	public function new() {
		this.id = 0;
		this.object = null;
		this.z = 0;
		this.renderOrder = 0;
	}
}

class RenderableFace {

	public var id:Int;
	public var v1:RenderableVertex;
	public var v2:RenderableVertex;
	public var v3:RenderableVertex;
	public var normalModel:Vector3;
	public var vertexNormalsModel:Array<Vector3>;
	public var vertexNormalsLength:Int;
	public var color:Color;
	public var material:Dynamic;
	public var uvs:Array<Vector2>;
	public var z:Float;
	public var renderOrder:Int;

	public function new() {
		this.id = 0;
		this.v1 = new RenderableVertex();
		this.v2 = new RenderableVertex();
		this.v3 = new RenderableVertex();
		this.normalModel = new Vector3();
		this.vertexNormalsModel = [new Vector3(), new Vector3(), new Vector3()];
		this.vertexNormalsLength = 0;
		this.color = new Color();
		this.material = null;
		this.uvs = [new Vector2(), new Vector2(), new Vector2()];
		this.z = 0;
		this.renderOrder = 0;
	}
}

class RenderableVertex {

	public var position:Vector3;
	public var positionWorld:Vector3;
	public var positionScreen:Vector4;
	public var visible:Bool;

	public function new() {
		this.position = new Vector3();
		this.positionWorld = new Vector3();
		this.positionScreen = new Vector4();
		this.visible = true;
	}

	public function copy(vertex:RenderableVertex) {
		this.positionWorld.copy(vertex.positionWorld);
		this.positionScreen.copy(vertex.positionScreen);
	}
}

class RenderableLine {

	public var id:Int;
	public var v1:RenderableVertex;
	public var v2:RenderableVertex;
	public var vertexColors:Array<Color>;
	public var material:Dynamic;
	public var z:Float;
	public var renderOrder:Int;

	public function new() {
		this.id = 0;
		this.v1 = new RenderableVertex();
		this.v2 = new RenderableVertex();
		this.vertexColors = [new Color(), new Color()];
		this.material = null;
		this.z = 0;
		this.renderOrder = 0;
	}
}

class RenderableSprite {

	public var id:Int;
	public var object:Dynamic;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var rotation:Float;
	public var scale:Vector2;
	public var material:Dynamic;
	public var renderOrder:Int;

	public function new() {
		this.id = 0;
		this.object = null;
		this.x = 0;
		this.y = 0;
		this.z = 0;
		this.rotation = 0;
		this.scale = new Vector2();
		this.material = null;
		this.renderOrder = 0;
	}
}

class Projector {

	private var _object:Dynamic;
	private var _objectCount:Int;
	private var _objectPoolLength:Int;
	private var _vertex:RenderableVertex;
	private var _vertexCount:Int;
	private var _vertexPoolLength:Int;
	private var _face:RenderableFace;
	private var _faceCount:Int;
	private var _facePoolLength:Int;
	private var _line:RenderableLine;
	private var _lineCount:Int;
	private var _linePoolLength:Int;
	private var _sprite:RenderableSprite;
	private var _spriteCount:Int;
	private var _spritePoolLength:Int;
	private var _modelMatrix:Matrix4;

	private var _renderData:Dynamic;
	private var _vector3:Vector3;
	private var _vector4:Vector4;
	private var _clipBox:Box3;
	private var _boundingBox:Box3;
	private var _points3:Array<Vector4>;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _modelViewProjectionMatrix:Matrix4;
	private var _frustum:Frustum;
	private var _objectPool:Array<RenderableObject>;
	private var _vertexPool:Array<RenderableVertex>;
	private var _facePool:Array<RenderableFace>;
	private var _linePool:Array<RenderableLine>;
	private var _spritePool:Array<RenderableSprite>;

	public function new() {
		// initialize properties
	}

	// implement methods

	public function projectScene(scene:Dynamic, camera:Dynamic, sortObjects:Bool, sortElements:Bool):Dynamic {
		// implement method
	}

}