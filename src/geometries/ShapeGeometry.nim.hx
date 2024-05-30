import BufferGeometry.BufferGeometry;
import BufferAttribute.Float32BufferAttribute;
import Shape.Shape;
import ShapeUtils.ShapeUtils;
import Vector2.Vector2;

class ShapeGeometry extends BufferGeometry {

    public var type:String = 'ShapeGeometry';
    public var parameters:Dynamic;

    public function new(shapes:Array<Shape> = [new Shape([new Vector2(0, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)])], curveSegments:Int = 12) {

        super();

        this.parameters = {
            shapes: shapes,
            curveSegments: curveSegments
        };

        // buffers

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helper variables

        var groupStart:Int = 0;
        var groupCount:Int = 0;

        // allow single and array values for "shapes" parameter

        if (!Std.is(shapes, Array)) {

            addShape(shapes);

        } else {

            for (i in 0...shapes.length) {

                addShape(shapes[i]);

                this.addGroup(groupStart, groupCount, i); // enables MultiMaterial support

                groupStart += groupCount;
                groupCount = 0;

            }

        }

        // build geometry

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        // helper functions

        function addShape(shape:Shape) {

            var indexOffset:Int = vertices.length / 3;
            var points:Dynamic = shape.extractPoints(curveSegments);

            var shapeVertices:Array<Vector2> = points.shape;
            var shapeHoles:Array<Array<Vector2>> = points.holes;

            // check direction of vertices

            if (!ShapeUtils.isClockWise(shapeVertices)) {

                shapeVertices = shapeVertices.reverse();

            }

            for (i in 0...shapeHoles.length) {

                var shapeHole:Array<Vector2> = shapeHoles[i];

                if (ShapeUtils.isClockWise(shapeHole)) {

                    shapeHoles[i] = shapeHole.reverse();

                }

            }

            var faces:Array<Array<Int>> = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

            // join vertices of inner and outer paths to a single array

            for (i in 0...shapeHoles.length) {

                var shapeHole:Array<Vector2> = shapeHoles[i];
                shapeVertices = shapeVertices.concat(shapeHole);

            }

            // vertices, normals, uvs

            for (i in 0...shapeVertices.length) {

                var vertex:Vector2 = shapeVertices[i];

                vertices.push(vertex.x, vertex.y, 0);
                normals.push(0, 0, 1);
                uvs.push(vertex.x, vertex.y); // world uvs

            }

            // indices

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

    public function copy(source:ShapeGeometry):ShapeGeometry {

        super.copy(source);

        this.parameters = Type.clone(source.parameters);

        return this;

    }

    public function toJSON():Dynamic {

        var data:Dynamic = super.toJSON();

        var shapes:Dynamic = this.parameters.shapes;

        return toJSON(shapes, data);

    }

    public static function fromJSON(data:Dynamic, shapes:Array<Shape>):ShapeGeometry {

        var geometryShapes:Array<Shape> = [];

        for (j in 0...data.shapes.length) {

            var shape:Shape = shapes[data.shapes[j]];

            geometryShapes.push(shape);

        }

        return new ShapeGeometry(geometryShapes, data.curveSegments);

    }

}

function toJSON(shapes:Dynamic, data:Dynamic):Dynamic {

    data.shapes = [];

    if (Std.is(shapes, Array)) {

        for (i in 0...shapes.length) {

            var shape:Shape = shapes[i];

            data.shapes.push(shape.uuid);

        }

    } else {

        data.shapes.push(shapes.uuid);

    }

    return data;

}