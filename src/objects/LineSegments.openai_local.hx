import threejs.objects.Line;
import threejs.math.Vector3;
import threejs.core.Float32BufferAttribute;
import threejs.core.BufferGeometry;
import js.Lib;

class LineSegments extends Line {
    public var isLineSegments:Bool;
    public var type:String;

    private static var _start:Vector3 = new Vector3();
    private static var _end:Vector3 = new Vector3();

    public function new(geometry:BufferGeometry, material:Dynamic) {
        super(geometry, material);
        this.isLineSegments = true;
        this.type = 'LineSegments';
    }

    public function computeLineDistances():LineSegments {
        var geometry:BufferGeometry = this.geometry;

        // we assume non-indexed geometry
        if (geometry.index == null) {
            var positionAttribute = geometry.attributes.position;
            var lineDistances:Array<Float> = [];

            for (i in 0...positionAttribute.count / 2) {
                var index = i * 2;

                _start.fromBufferAttribute(positionAttribute, index);
                _end.fromBufferAttribute(positionAttribute, index + 1);

                lineDistances[index] = (index == 0) ? 0 : lineDistances[index - 1];
                lineDistances[index + 1] = lineDistances[index] + _start.distanceTo(_end);
            }

            geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
        } else {
            Lib.debug("THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");
        }

        return this;
    }
}

@:keep
extern class Vector3 {
    public function new():Void;
    public function fromBufferAttribute(attribute:Dynamic, index:Int):Vector3;
    public function distanceTo(v:Vector3):Float;
}

@:keep
extern class Float32BufferAttribute {
    public function new(array:Array<Float>, itemSize:Int):Void;
}

@:keep
extern class BufferGeometry {
    public var index:Dynamic;
    public var attributes:Dynamic;
    public function setAttribute(name:String, attribute:Float32BufferAttribute):Void;
}

@:keep
extern class Line {
    public var geometry:BufferGeometry;
    public function new(geometry:BufferGeometry, material:Dynamic):Void;
}