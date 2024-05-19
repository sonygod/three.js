package three.geom;

import haxe.ds.Vector;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.curves.Curves;
import three.math.Vector2;
import three.math.Vector3;
import three.extras.Shape;
import three.extras.ShapeUtils;

class ExtrudeGeometry extends BufferGeometry {
    public var type:String = 'ExtrudeGeometry';

    public function new(shapes:Array<Shape> = [new Shape([new Vector2(0.5, 0.5), new Vector2(-0.5, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)])], options:Dynamic = {}) {
        super();

        this.parameters = {
            shapes: shapes,
            options: options
        };

        var verticesArray:Array<Float> = [];
        var uvArray:Array<Float> = [];

        for (i in 0...shapes.length) {
            addShape(shapes[i]);
        }

        this.setAttribute('position', new Float32BufferAttribute(verticesArray, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvArray, 2));

        this.computeVertexNormals();
    }

    function addShape(shape:Shape) {
        var vertices:Array<Vector2> = shape.extractPoints(12);
        var holes:Array<Array<Vector2>> = shape.holes;

        var verticesMovements:Array<Vector2> = [];
        for (i in 0...vertices.length) {
            verticesMovements.push(getBevelVec(vertices[i], vertices[(i + vertices.length - 1) % vertices.length], vertices[(i + 1) % vertices.length]));
        }

        var holesMovements:Array<Array<Vector2>> = [];
        for (hole in holes) {
            var oneHoleMovements:Array<Vector2> = [];
            for (i in 0...hole.length) {
                oneHoleMovements.push(getBevelVec(hole[i], hole[(i + hole.length - 1) % hole.length], hole[(i + 1) % hole.length]));
            }
            holesMovements.push(oneHoleMovements);
        }

        // ... (rest of the code remains the same)
    }

    static function fromJSON(data:Dynamic, shapes:Array<Shape>):ExtrudeGeometry {
        var geometryShapes:Array<Shape> = [];

        for (j in 0...data.shapes.length) {
            var shape = shapes[data.shapes[j]];
            geometryShapes.push(shape);
        }

        var extrudePath:Curve = null;
        if (data.options.extrudePath != null) {
            extrudePath = new Curves[data.options.extrudePath.type]().fromJSON(data.options.extrudePath);
        }

        return new ExtrudeGeometry(geometryShapes, data.options);
    }
}

class WorldUVGenerator {
    public static function generateTopUV(geometry:BufferGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int):Array<Vector2> {
        var a_x:Float = vertices[indexA * 3];
        var a_y:Float = vertices[indexA * 3 + 1];
        var b_x:Float = vertices[indexB * 3];
        var b_y:Float = vertices[indexB * 3 + 1];
        var c_x:Float = vertices[indexC * 3];
        var c_y:Float = vertices[indexC * 3 + 1];

        return [
            new Vector2(a_x, a_y),
            new Vector2(b_x, b_y),
            new Vector2(c_x, c_y)
        ];
    }

    public static function generateSideWallUV(geometry:BufferGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int, indexD:Int):Array<Vector2> {
        // ... (rest of the code remains the same)
    }
}