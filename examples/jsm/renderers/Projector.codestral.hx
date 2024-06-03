import three.math.Box3;
import three.math.Color;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.objects.Object3D;
import three.cameras.Camera;
import three.scenes.Scene;
import three.materials.Material;
import three.core.DoubleSide;
import three.math.Frustum;

class RenderableObject {
    public var id:Int = 0;
    public var object:Object3D = null;
    public var z:Float = 0;
    public var renderOrder:Int = 0;

    public function new() {}
}

class RenderableFace {
    public var id:Int = 0;
    public var v1:RenderableVertex = new RenderableVertex();
    public var v2:RenderableVertex = new RenderableVertex();
    public var v3:RenderableVertex = new RenderableVertex();
    public var normalModel:Vector3 = new Vector3();
    public var vertexNormalsModel:Array<Vector3> = [new Vector3(), new Vector3(), new Vector3()];
    public var vertexNormalsLength:Int = 0;
    public var color:Color = new Color();
    public var material:Material = null;
    public var uvs:Array<Vector2> = [new Vector2(), new Vector2(), new Vector2()];
    public var z:Float = 0;
    public var renderOrder:Int = 0;

    public function new() {}
}

class RenderableVertex {
    public var position:Vector3 = new Vector3();
    public var positionWorld:Vector3 = new Vector3();
    public var positionScreen:Vector4 = new Vector4();
    public var visible:Bool = true;

    public function new() {}

    public function copy(vertex:RenderableVertex):Void {
        this.positionWorld.copy(vertex.positionWorld);
        this.positionScreen.copy(vertex.positionScreen);
    }
}

class RenderableLine {
    public var id:Int = 0;
    public var v1:RenderableVertex = new RenderableVertex();
    public var v2:RenderableVertex = new RenderableVertex();
    public var vertexColors:Array<Color> = [new Color(), new Color()];
    public var material:Material = null;
    public var z:Float = 0;
    public var renderOrder:Int = 0;

    public function new() {}
}

class RenderableSprite {
    public var id:Int = 0;
    public var object:Object3D = null;
    public var x:Float = 0;
    public var y:Float = 0;
    public var z:Float = 0;
    public var rotation:Float = 0;
    public var scale:Vector2 = new Vector2();
    public var material:Material = null;
    public var renderOrder:Int = 0;

    public function new() {}
}

class Projector {
    private var _object:RenderableObject;
    private var _objectCount:Int;
    private var _objectPoolLength:Int = 0;
    private var _vertex:RenderableVertex;
    private var _vertexCount:Int;
    private var _vertexPoolLength:Int = 0;
    private var _face:RenderableFace;
    private var _faceCount:Int;
    private var _facePoolLength:Int = 0;
    private var _line:RenderableLine;
    private var _lineCount:Int;
    private var _linePoolLength:Int = 0;
    private var _sprite:RenderableSprite;
    private var _spriteCount:Int;
    private var _spritePoolLength:Int = 0;
    private var _modelMatrix:Matrix4;

    private var _renderData:Dynamic = { objects: [], lights: [], elements: [] };
    private var _vector3:Vector3 = new Vector3();
    private var _vector4:Vector4 = new Vector4();
    private var _clipBox:Box3 = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1));
    private var _boundingBox:Box3 = new Box3();
    private var _points3:Array<Vector4> = new Array<Vector4>(3);
    private var _viewMatrix:Matrix4 = new Matrix4();
    private var _viewProjectionMatrix:Matrix4 = new Matrix4();
    private var _modelViewProjectionMatrix:Matrix4 = new Matrix4();
    private var _frustum:Frustum = new Frustum();
    private var _objectPool:Array<RenderableObject> = [];
    private var _vertexPool:Array<RenderableVertex> = [];
    private var _facePool:Array<RenderableFace> = [];
    private var _linePool:Array<RenderableLine> = [];
    private var _spritePool:Array<RenderableSprite> = [];

    public function new() {}

    public function projectScene(scene:Scene, camera:Camera, sortObjects:Bool, sortElements:Bool):Dynamic {
        _faceCount = 0;
        _lineCount = 0;
        _spriteCount = 0;
        _renderData.elements = [];

        if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
        if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

        _viewMatrix.copy(camera.matrixWorldInverse);
        _viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);
        _frustum.setFromProjectionMatrix(_viewProjectionMatrix);

        _objectCount = 0;
        _renderData.objects = [];
        _renderData.lights = [];

        projectObject(scene);

        if (sortObjects) _renderData.objects.sort(painterSort);

        var objects = _renderData.objects;
        for (o in 0...objects.length) {
            var object = objects[o].object;
            var geometry = object.geometry;
            var renderList = new RenderList();
            renderList.setObject(object);
            _modelMatrix = object.matrixWorld;

            _vertexCount = 0;

            // Rest of the code...
        }

        if (sortElements) _renderData.elements.sort(painterSort);

        return _renderData;
    }

    private function projectObject(object:Object3D):Void {
        if (!object.visible) return;

        if (object.isLight) {
            _renderData.lights.push(object);
        } else if (object.isMesh || object.isLine || object.isPoints) {
            if (!object.material.visible) return;
            if (object.frustumCulled && !_frustum.intersectsObject(object)) return;
            addObject(object);
        } else if (object.isSprite) {
            if (!object.material.visible) return;
            if (object.frustumCulled && !_frustum.intersectsSprite(object)) return;
            addObject(object);
        }

        var children = object.children;
        for (i in 0...children.length) projectObject(children[i]);
    }

    private function addObject(object:Object3D):Void {
        _object = getNextObjectInPool();
        _object.id = object.id;
        _object.object = object;
        _vector3.setFromMatrixPosition(object.matrixWorld);
        _vector3.applyMatrix4(_viewProjectionMatrix);
        _object.z = _vector3.z;
        _object.renderOrder = object.renderOrder;
        _renderData.objects.push(_object);
    }

    // Rest of the methods...
}

class RenderList {
    private var normals:Array<Float> = [];
    private var colors:Array<Float> = [];
    private var uvs:Array<Float> = [];
    private var object:Object3D = null;
    private var normalMatrix:Matrix3 = new Matrix3();

    public function new() {}

    public function setObject(value:Object3D):Void {
        object = value;
        normalMatrix.getNormalMatrix(object.matrixWorld);
        normals = [];
        colors = [];
        uvs = [];
    }

    // Rest of the methods...
}