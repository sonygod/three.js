import openfl.display.DisplayObject3D;
import openfl.display.DisplayObjectContainer;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.geom.Vector3D;

class ArrowHelper extends DisplayObject3D {
    public var line:Line;
    public var cone:Cone;

    public function new(dir:Vector3D = Vector3D.Y_AXIS, origin:Vector3D = Vector3D.ZERO, length:Float = 1.0, color:Int = 0xffff00, headLength:Float = length * 0.2, headWidth:Float = headLength * 0.2) {
        super();

        if (_lineGeometry == null) {
            _lineGeometry = new LineGeometry();
            _coneGeometry = new ConeGeometry(0, 0.5, 1, 5, 1);
            _coneGeometry.translate(0, -0.5, 0);
        }

        position = origin;

        line = new Line(_lineGeometry, new LineMaterial(color));
        line.matrixAutoUpdate = false;
        addChild(line);

        cone = new Cone(_coneGeometry, new MeshMaterial(color));
        cone.matrixAutoUpdate = false;
        addChild(cone);

        setDirection(dir);
        setLength(length, headLength, headWidth);
    }

    public function setDirection(dir:Vector3D):Void {
        if (dir.y > 0.99999) {
            quaternion = new Quaternion();
        } else if (dir.y < -0.99999) {
            quaternion = Quaternion.AXIS_Y;
        } else {
            var axis:Vector3D = new Vector3D(dir.z, 0, -dir.x);
            axis.normalize();
            var radians:Float = Math.acos(dir.y);
            quaternion = Quaternion.fromAxisAngle(axis, radians);
        }
    }

    public function setLength(length:Float, headLength:Float = length * 0.2, headWidth:Float = headLength * 0.2):Void {
        line.scale = new Vector3D(1, Math.max(0.0001, length - headLength), 1);
        line.updateMatrix();

        cone.scale = new Vector3D(headWidth, headLength, headWidth);
        cone.position.y = length;
        cone.updateMatrix();
    }

    public function setColor(color:Int):Void {
        line.material.color = color;
        cone.material.color = color;
    }

    public function copy(source:ArrowHelper):ArrowHelper {
        super.copy(source);
        line.copy(source.line);
        cone.copy(source.cone);
        return this;
    }

    public function dispose():Void {
        line.geometry.dispose();
        line.material.dispose();
        cone.geometry.dispose();
        cone.material.dispose();
    }
}

class LineGeometry {
    public var vertexBuffer:VertexBuffer3D;
    public var indexBuffer:IndexBuffer3D;

    public function new() {
        vertexBuffer = Context3D.createVertexBuffer(6, 3);
        vertexBuffer.uploadFromVector(Vector.<Float>([0, 0, 0, 0, 1, 0]));

        indexBuffer = Context3D.createIndexBuffer(2);
        indexBuffer.uploadFromVector(Vector.<Int>([0, 1]));
    }
}

class LineMaterial {
    public var color:Int;

    public function new(color:Int) {
        this.color = color;
    }
}

class Line extends DisplayObject3D {
    public var geometry:LineGeometry;
    public var material:LineMaterial;

    public function new(geometry:LineGeometry, material:LineMaterial) {
        super();
        this.geometry = geometry;
        this.material = material;
    }
}

class ConeGeometry {
    public var vertexBuffer:VertexBuffer3D;
    public var indexBuffer:IndexBuffer3D;

    public function new(bottomRadius:Float, topRadius:Float, height:Float, radialSegments:Int, heightSegments:Int) {
        vertexBuffer = Context3D.createVertexBuffer(0, Context3DVertexBufferFormat.FLOAT_3);
        indexBuffer = Context3D.createIndexBuffer(0);

        // TODO: Implement ConeGeometry
    }

    public function translate(x:Float, y:Float, z:Float):Void {
        // TODO: Implement ConeGeometry translation
    }
}

class MeshMaterial {
    public var color:Int;

    public function new(color:Int) {
        this.color = color;
    }
}

class Cone extends DisplayObject3D {
    public var geometry:ConeGeometry;
    public var material:MeshMaterial;

    public function new(geometry:ConeGeometry, material:MeshMaterial) {
        super();
        this.geometry = geometry;
        this.material = material;
    }
}

var _lineGeometry:LineGeometry;
var _coneGeometry:ConeGeometry;