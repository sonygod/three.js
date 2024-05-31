import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.extras.core.Shape;
import three.extras.ShapeUtils;
import three.math.Vector2;

class ShapeGeometry extends BufferGeometry {
    public var parameters:Dynamic;

    public function new(shapes:Shape = new Shape([new Vector2(0, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)]), curveSegments:Int = 12) {
        super();

        this.type = 'ShapeGeometry';

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
        var groupStart = 0;
        var groupCount = 0;

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
        function addShape(shape:Shape):Void {
            var indexOffset = vertices.length / 3;
            var points = shape.extractPoints(curveSegments);

            var shapeVertices = points.shape;
            var shapeHoles = points.holes;

            // check direction of vertices
            if (!ShapeUtils.isClockWise(shapeVertices)) {
                shapeVertices = shapeVertices.reverse();
            }

            for (i in 0...shapeHoles.length) {
                var shapeHole = shapeHoles[i];
                if (ShapeUtils.isClockWise(shapeHole)) {
                    shapeHoles[i] = shapeHole.reverse();
                }
            }

            var faces = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

            // join vertices of inner and outer paths to a single array
            for (shapeHole in shapeHoles) {
                shapeVertices = shapeVertices.concat(shapeHole);
            }

            // vertices, normals, uvs
            for (vertex in shapeVertices) {
                vertices.push(vertex.x, vertex.y, 0);
                normals.push(0, 0, 1);
                uvs.push(vertex.x, vertex.y); // world uvs
            }

            // indices
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
        this.parameters = Reflect.copy(source.parameters);
        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();
        var shapes = this.parameters.shapes;
        return toJSON(shapes, data);
    }

    public static function fromJSON(data:Dynamic, shapes:Map<String, Shape>):ShapeGeometry {
        var geometryShapes:Array<Shape> = [];
        for (j in 0...data.shapes.length) {
            var shape = shapes.get(data.shapes[j]);
            geometryShapes.push(shape);
        }
        return new ShapeGeometry(geometryShapes, data.curveSegments);
    }

    private static function toJSON(shapes:Dynamic, data:Dynamic):Dynamic {
        data.shapes = [];
        if (Std.is(shapes, Array)) {
            for (shape in shapes) {
                data.shapes.push(shape.uuid);
            }
        } else {
            data.shapes.push(shapes.uuid);
        }
        return data;
    }
}