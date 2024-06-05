package three.geom;

import three.BufferGeometry;
import three.BufferAttribute;
import three.Curve;
import three.Vector2;
import three.Vector3;
import three.Shape;
import three.ShapeUtils;

class ExtrudeGeometry extends BufferGeometry {
    public function new(shapes:Array<Shape> = [new Shape([new Vector2(0.5, 0.5), new Vector2(-0.5, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)])], options:Dynamic = {}) {
        super();
        this.type = 'ExtrudeGeometry';
        this.parameters = {
            shapes: shapes,
            options: options
        };

        shapes = (Std.isOfType(shapes, Array)) ? shapes : [shapes];

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
        // ...
    }

    function copy(source:ExtrudeGeometry) {
        super.copy(source);
        this.parameters = Object.assign({}, source.parameters);
        return this;
    }

    function toJSON() {
        var data = super.toJSON();
        var shapes = this.parameters.shapes;
        var options = this.parameters.options;

        return toJSON(shapes, options, data);
    }

    static function fromJSON(data:Dynamic, shapes:Array<Shape>) {
        var geometryShapes:Array<Shape> = [];

        for (j in 0...data.shapes.length) {
            var shape = shapes[data.shapes[j]];
            geometryShapes.push(shape);
        }

        var extrudePath = data.options.extrudePath;

        if (extrudePath != null) {
            data.options.extrudePath = new Curve(extrudePath.type).fromJSON(extrudePath);
        }

        return new ExtrudeGeometry(geometryShapes, data.options);
    }
}

class WorldUVGenerator {
    public static function generateTopUV(geometry:BufferGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int) {
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

    public static function generateSideWallUV(geometry:BufferGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int, indexD:Int) {
        // ...
    }
}

function toJSON(shapes:Array<Shape>, options:Dynamic, data:Dynamic) {
    data.shapes = [];

    if (Std.isOfType(shapes, Array)) {
        for (i in 0...shapes.length) {
            var shape = shapes[i];
            data.shapes.push(shape.uuid);
        }
    } else {
        data.shapes.push(shapes.uuid);
    }

    data.options = Object.assign({}, options);

    if (options.extrudePath != null) data.options.extrudePath = options.extrudePath.toJSON();

    return data;
}