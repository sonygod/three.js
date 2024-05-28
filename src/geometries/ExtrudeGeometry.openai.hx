package three.js.geometries;

import three.js.BufferGeometry;
import three.js.BufferAttribute;
import three.js.math.Vector2;
import three.js.math.Vector3;
import three.js.extras.Shape;
import three.js.extras.ShapeUtils;
import three.js.extras.curves.Curves;

class ExtrudeGeometry extends BufferGeometry {
    public function new(shapes = new Shape([new Vector2(0.5, 0.5), new Vector2(-0.5, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)]), options = {}) {
        super();

        this.type = 'ExtrudeGeometry';

        this.parameters = {
            shapes: shapes,
            options: options
        };

        var verticesArray:Array<Float> = [];
        var uvArray:Array<Float> = [];

        for (i in 0...shapes.length) {
            addShape(shapes[i]);
        }

        // build geometry
        this.setAttribute('position', new Float32BufferAttribute(verticesArray, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvArray, 2));

        this.computeVertexNormals();

        // functions
        function addShape(shape:Shape) {
            // ...
        }
    }

    public function copy(source:ExtrudeGeometry):ExtrudeGeometry {
        super.copy(source);

        this.parameters = Object.assign({}, source.parameters);

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();

        var shapes:Array<Shape> = this.parameters.shapes;
        var options:Dynamic = this.parameters.options;

        return toJSON(shapes, options, data);
    }

    static function fromJSON(data:Dynamic, shapes:Array<Shape>):ExtrudeGeometry {
        var geometryShapes:Array<Shape> = [];

        for (j in 0...data.shapes.length) {
            var shape:Shape = shapes[data.shapes[j]];
            geometryShapes.push(shape);
        }

        var extrudePath:Dynamic = data.options.extrudePath;

        if (extrudePath != null) {
            data.options.extrudePath = new Curves[extrudePath.type]().fromJSON(extrudePath);
        }

        return new ExtrudeGeometry(geometryShapes, data.options);
    }
}

class WorldUVGenerator {
    public static function generateTopUV(geometry:ExtrudeGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int):Array<Vector2> {
        var a_x = vertices[indexA * 3];
        var a_y = vertices[indexA * 3 + 1];
        var b_x = vertices[indexB * 3];
        var b_y = vertices[indexB * 3 + 1];
        var c_x = vertices[indexC * 3];
        var c_y = vertices[indexC * 3 + 1];

        return [
            new Vector2(a_x, a_y),
            new Vector2(b_x, b_y),
            new Vector2(c_x, c_y)
        ];
    }

    public static function generateSideWallUV(geometry:ExtrudeGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int, indexD:Int):Array<Vector2> {
        var a_x = vertices[indexA * 3];
        var a_y = vertices[indexA * 3 + 1];
        var a_z = vertices[indexA * 3 + 2];
        var b_x = vertices[indexB * 3];
        var b_y = vertices[indexB * 3 + 1];
        var b_z = vertices[indexB * 3 + 2];
        var c_x = vertices[indexC * 3];
        var c_y = vertices[indexC * 3 + 1];
        var c_z = vertices[indexC * 3 + 2];
        var d_x = vertices[indexD * 3];
        var d_y = vertices[indexD * 3 + 1];
        var d_z = vertices[indexD * 3 + 2];

        if (Math.abs(a_y - b_y) < Math.abs(a_x - b_x)) {
            return [
                new Vector2(a_x, 1 - a_z),
                new Vector2(b_x, 1 - b_z),
                new Vector2(c_x, 1 - c_z),
                new Vector2(d_x, 1 - d_z)
            ];
        } else {
            return [
                new Vector2(a_y, 1 - a_z),
                new Vector2(b_y, 1 - b_z),
                new Vector2(c_y, 1 - c_z),
                new Vector2(d_y, 1 - d_z)
            ];
        }
    }
}

function toJSON(shapes:Array<Shape>, options:Dynamic, data:Dynamic):Dynamic {
    data.shapes = [];

    if (shapes.length > 0) {
        for (i in 0...shapes.length) {
            var shape:Shape = shapes[i];
            data.shapes.push(shape.uuid);
        }
    } else {
        data.shapes.push(shapes.uuid);
    }

    data.options = Object.assign({}, options);

    if (options.extrudePath != null) data.options.extrudePath = options.extrudePath.toJSON();

    return data;
}