import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.extras.core.Shape;
import three.extras.ShapeUtils;
import three.math.Vector2;

class ShapeGeometry extends BufferGeometry {

    public function new(shapes:Array<Shape> = [new Vector2(0, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)], curveSegments:Int = 12) {
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

        var groupStart:Int = 0;
        var groupCount:Int = 0;

        // allow single and array values for "shapes" parameter

        if (shapes.length == 1) {
            addShape(shapes[0]);
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
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));

        // helper functions

        function addShape(shape:Shape) {
            var indexOffset:Int = vertices.length / 3;
            var points = shape.extractPoints(curveSegments);

            var shapeVertices = points.shape;
            var shapeHoles = points.holes;

            // check direction of vertices

            if (!ShapeUtils.isClockWise(shapeVertices)) {
                shapeVertices.reverse();
            }

            for (i in 0...shapeHoles.length) {
                if (ShapeUtils.isClockWise(shapeHoles[i])) {
                    shapeHoles[i].reverse();
                }
            }

            var faces = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

            // join vertices of inner and outer paths to a single array

            for (i in 0...shapeHoles.length) {
                shapeVertices.concat(shapeHoles[i]);
            }

            // vertices, normals, uvs

            for (i in 0...shapeVertices.length) {
                var vertex = shapeVertices[i];

                vertices.push(vertex.x, vertex.y, 0);
                normals.push(0, 0, 1);
                uvs.push(vertex.x, vertex.y); // world uvs
            }

            // indices

            for (i in 0...faces.length) {
                var face = faces[i];

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

        this.parameters = Std.clone(source.parameters);

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();

        var shapes = this.parameters.shapes;

        return toJSON(shapes, data);
    }

    public static function fromJSON(data:Dynamic, shapes:Array<Shape>):ShapeGeometry {
        var geometryShapes:Array<Shape> = [];

        for (j in 0...data.shapes.length) {
            var shape = shapes[data.shapes[j]];

            geometryShapes.push(shape);
        }

        return new ShapeGeometry(geometryShapes, data.curveSegments);
    }

    public static function toJSON(shapes:Array<Shape>, data:Dynamic):Dynamic {
        data.shapes = [];

        for (i in 0...shapes.length) {
            var shape = shapes[i];

            data.shapes.push(shape.uuid);
        }

        return data;
    }
}