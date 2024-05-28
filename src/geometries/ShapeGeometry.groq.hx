package three.js.src.geometries;

import three.js.core.BufferGeometry;
import three.js.core.Float32BufferAttribute;
import three.js.extras.core.Shape;
import three.js.extras.ShapeUtils;
import three.js.math.Vector2;

class ShapeGeometry extends BufferGeometry {
    public function new(shapes:Shape = new Shape([new Vector2(0, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)]), curveSegments:Int = 12) {
        super();
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

        if (!Std.isOfType(shapes, Array)) {
            addShape(shapes);
        } else {
            for (i in 0...shapes.length) {
                addShape(shapes[i]);
                this.addGroup(groupStart, groupCount, i); // enables MultiMaterial support
                groupStart += groupCount;
                groupCount = 0;
            }
        }

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function addShape(shape:Shape) {
            var indexOffset:Int = vertices.length / 3;
            var points = shape.extractPoints(curveSegments);

            var shapeVertices:Array<Vector2> = points.shape;
            var shapeHoles:Array<Array<Vector2>> = points.holes;

            if (!ShapeUtils.isClockWise(shapeVertices)) {
                shapeVertices.reverse();
            }

            for (i in 0...shapeHoles.length) {
                var shapeHole:Array<Vector2> = shapeHoles[i];
                if (ShapeUtils.isClockWise(shapeHole)) {
                    shapeHoles[i] = shapeHole.reverse();
                }
            }

            var faces:Array<Array<Int>> = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

            for (i in 0...shapeHoles.length) {
                var shapeHole:Array<Vector2> = shapeHoles[i];
                shapeVertices = shapeVertices.concat(shapeHole);
            }

            for (i in 0...shapeVertices.length) {
                var vertex:Vector2 = shapeVertices[i];
                vertices.push(vertex.x, vertex.y, 0);
                normals.push(0, 0, 1);
                uvs.push(vertex.x, vertex.y); // world uvs
            }

            for (i in 0...faces.length) {
                var face:Array<Int> = faces[i];
                var a:Int = face[0] + indexOffset;
                var b:Int = face[1] + indexOffset;
                var c:Int = face[2] + indexOffset;
                indices.push(a, b, c);
                groupCount += 3;
            }
        }
    }

    override public function copy(source:BufferGeometry) {
        super.copy(source);
        this.parameters = Object.assign({}, source.parameters);
        return this;
    }

    override public function toJSON() {
        var data = super.toJSON();
        var shapes:Array<Shape> = this.parameters.shapes;
        return toJSON(shapes, data);
    }

    static public function fromJSON(data:Dynamic, shapes:Array<Shape>) {
        var geometryShapes:Array<Shape> = [];
        for (j in 0...data.shapes.length) {
            var shape:Shape = shapes[data.shapes[j]];
            geometryShapes.push(shape);
        }
        return new ShapeGeometry(geometryShapes, data.curveSegments);
    }
}

function toJSON(shapes:Array<Shape>, data:Dynamic) {
    data.shapes = [];
    if (Std.isOfType(shapes, Array)) {
        for (i in 0...shapes.length) {
            var shape:Shape = shapes[i];
            data.shapes.push(shape.uuid);
        }
    } else {
        data.shapes.push(shapes.uuid);
    }
    return data;
}