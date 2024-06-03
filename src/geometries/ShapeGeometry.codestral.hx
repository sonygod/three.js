import js.Browser.document;
import js.html.ArrayBuffer;
import js.html.Float32Array;

import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.extras.core.Shape;
import three.extras.ShapeUtils;
import three.math.Vector2;

class ShapeGeometry extends BufferGeometry {

    public var parameters:Dynamic;

    public function new(shapes:Array<Shape> = null, curveSegments:Int = 12) {
        super();

        if(shapes == null)
            shapes = [new Shape([new Vector2(0, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)])];

        this.type = 'ShapeGeometry';

        this.parameters = {
            shapes: shapes,
            curveSegments: curveSegments
        };

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        var groupStart:Int = 0;
        var groupCount:Int = 0;

        for (shape in shapes) {
            addShape(shape);
            this.addGroup(groupStart, groupCount, shapes.indexOf(shape));
            groupStart += groupCount;
            groupCount = 0;
        }

        this.setIndex(indices);
        this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
        this.setAttribute('normal', new BufferAttribute(new Float32Array(normals), 3));
        this.setAttribute('uv', new BufferAttribute(new Float32Array(uvs), 2));

        function addShape(shape:Shape) {
            var indexOffset:Int = vertices.length / 3;
            var points = shape.extractPoints(curveSegments);

            var shapeVertices = points.shape;
            var shapeHoles = points.holes;

            if (ShapeUtils.isClockWise(shapeVertices) == false) {
                shapeVertices = shapeVertices.reverse();
            }

            for (shapeHole in shapeHoles) {
                if (ShapeUtils.isClockWise(shapeHole) == true) {
                    shapeHoles[shapeHoles.indexOf(shapeHole)] = shapeHole.reverse();
                }
            }

            var faces = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

            for (shapeHole in shapeHoles) {
                shapeVertices = shapeVertices.concat(shapeHole);
            }

            for (vertex in shapeVertices) {
                vertices.push(vertex.x, vertex.y, 0);
                normals.push(0, 0, 1);
                uvs.push(vertex.x, vertex.y);
            }

            for (face in faces) {
                var a = face[0] + indexOffset;
                var b = face[1] + indexOffset;
                var c = face[2] + indexOffset;

                indices.push(a, b, c);
                groupCount += 3;
            }
        }
    }

    public function copy(source:ShapeGeometry):ShapeGeometry {
        super.copy(source);
        this.parameters = js.Browser.Type.createEmptyInstance(Dynamic);
        js.Boot.copy(source.parameters, this.parameters);
        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();
        var shapes = this.parameters.shapes;
        return toJSON(shapes, data);
    }

    public static function fromJSON(data:Dynamic, shapes:Array<Shape>):ShapeGeometry {
        var geometryShapes:Array<Shape> = [];
        for (i in data.shapes) {
            var shape = shapes[data.shapes[i]];
            geometryShapes.push(shape);
        }
        return new ShapeGeometry(geometryShapes, data.curveSegments);
    }
}

function toJSON(shapes:Array<Shape>, data:Dynamic):Dynamic {
    data.shapes = [];
    for (shape in shapes) {
        data.shapes.push(shape.uuid);
    }
    return data;
}