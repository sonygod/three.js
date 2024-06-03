import js.Browser.FileReader;
import js.html.File;
import haxe.io.Bytes;
import haxe.zip.Uncompress;
import haxe.Json;
import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.DoubleSide;
import three.FileLoader;
import three.Group;
import three.Loader;
import three.Mesh;
import three.MeshBasicMaterial;
import three.RawShaderMaterial;
import three.TextureLoader;
import three.Quaternion;
import three.Vector3;

class TiltLoader extends Loader {

    public function new() {
        super();
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, (buffer:Bytes) -> {
            try {
                onLoad(this.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:Bytes):Group {
        var group = new Group();

        var zip = Uncompress.run(buffer.sub(16));

        var metadata = Json.parse(zip['metadata.json'].toString());
        var data = new DataView(zip['data.sketch'].getBytes());

        var num_strokes = data.getInt32(16, true);

        var brushes:haxe.ds.StringMap<Array<Dynamic>> = new haxe.ds.StringMap();

        var offset = 20;

        for (i in 0...num_strokes) {
            var brush_index = data.getInt32(offset, true);

            var brush_color = [
                data.getFloat32(offset + 4, true),
                data.getFloat32(offset + 8, true),
                data.getFloat32(offset + 12, true),
                data.getFloat32(offset + 16, true)
            ];
            var brush_size = data.getFloat32(offset + 20, true);
            var stroke_mask = data.getUint32(offset + 24, true);
            var controlpoint_mask = data.getUint32(offset + 28, true);

            var offset_stroke_mask = 0;
            var offset_controlpoint_mask = 0;

            for (j in 0...4) {
                var byte = 1 << j;
                if ((stroke_mask & byte) > 0) offset_stroke_mask += 4;
                if ((controlpoint_mask & byte) > 0) offset_controlpoint_mask += 4;
            }

            offset = offset + 28 + offset_stroke_mask + 4;

            var num_control_points = data.getInt32(offset, true);

            var positions = new Float32Array(num_control_points * 3);
            var quaternions = new Float32Array(num_control_points * 4);

            offset = offset + 4;

            for (j in 0...num_control_points) {
                var k = j * 4;
                positions[j * 3] = data.getFloat32(offset, true);
                positions[j * 3 + 1] = data.getFloat32(offset + 4, true);
                positions[j * 3 + 2] = data.getFloat32(offset + 8, true);

                quaternions[k] = data.getFloat32(offset + 12, true);
                quaternions[k + 1] = data.getFloat32(offset + 16, true);
                quaternions[k + 2] = data.getFloat32(offset + 20, true);
                quaternions[k + 3] = data.getFloat32(offset + 24, true);

                offset = offset + 28 + offset_controlpoint_mask;
            }

            if (!brushes.exists(brush_index)) {
                brushes.set(brush_index, []);
            }

            brushes.get(brush_index).push([positions, quaternions, brush_size, brush_color]);
        }

        for (brush_index in brushes.keys()) {
            var geometry = new StrokeGeometry(brushes.get(brush_index));
            var material = getMaterial(metadata.BrushIndex[brush_index]);

            group.add(new Mesh(geometry, material));
        }

        return group;
    }
}

class StrokeGeometry extends BufferGeometry {

    public function new(strokes:Array<Dynamic>) {
        super();

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];
        var uvs:Array<Float> = [];

        var position = new Vector3();
        var prevPosition = new Vector3();

        var quaternion = new Quaternion();
        var prevQuaternion = new Quaternion();

        var vector1 = new Vector3();
        var vector2 = new Vector3();
        var vector3 = new Vector3();
        var vector4 = new Vector3();

        var color = new Color();

        for (k in 0...strokes.length) {
            var stroke = strokes[k];
            var positions = stroke[0];
            var quaternions = stroke[1];
            var size = stroke[2];
            var rgba = stroke[3];
            var alpha = stroke[3][3];

            color.fromArray(rgba).convertSRGBToLinear();

            prevPosition.fromArray(positions, 0);
            prevQuaternion.fromArray(quaternions, 0);

            for (i in 3...positions.length step 3) {
                var j = i * 4 / 3;
                position.fromArray(positions, i);
                quaternion.fromArray(quaternions, j);

                vector1.set(-size, 0, 0);
                vector1.applyQuaternion(quaternion);
                vector1.add(position);

                vector2.set(size, 0, 0);
                vector2.applyQuaternion(quaternion);
                vector2.add(position);

                vector3.set(size, 0, 0);
                vector3.applyQuaternion(prevQuaternion);
                vector3.add(prevPosition);

                vector4.set(-size, 0, 0);
                vector4.applyQuaternion(prevQuaternion);
                vector4.add(prevPosition);

                vertices.push(vector1.x, vector1.y, -vector1.z);
                vertices.push(vector2.x, vector2.y, -vector2.z);
                vertices.push(vector4.x, vector4.y, -vector4.z);

                vertices.push(vector2.x, vector2.y, -vector2.z);
                vertices.push(vector3.x, vector3.y, -vector3.z);
                vertices.push(vector4.x, vector4.y, -vector4.z);

                prevPosition.copy(position);
                prevQuaternion.copy(quaternion);

                colors.push(...color, alpha);
                colors.push(...color, alpha);
                colors.push(...color, alpha);

                colors.push(...color, alpha);
                colors.push(...color, alpha);
                colors.push(...color, alpha);

                var p1 = i / positions.length;
                var p2 = (i - 3) / positions.length;

                uvs.push(p1, 0);
                uvs.push(p1, 1);
                uvs.push(p2, 0);

                uvs.push(p1, 1);
                uvs.push(p2, 1);
                uvs.push(p2, 0);
            }
        }

        this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
        this.setAttribute('color', new BufferAttribute(new Float32Array(colors), 4));
        this.setAttribute('uv', new BufferAttribute(new Float32Array(uvs), 2));
    }
}

var BRUSH_LIST_ARRAY:haxe.ds.StringMap<String> = new haxe.ds.StringMap([
    // ... (rest of the BRUSH_LIST_ARRAY)
]);

var common = {
    // ... (rest of the common object)
};

var shaders:haxe.ds.StringMap<Dynamic> = null;

function getShaders():haxe.ds.StringMap<Dynamic> {
    if (shaders == null) {
        // ... (rest of the getShaders function)
    }
    return shaders;
}

function getMaterial(GUID:String):Dynamic {
    var name = BRUSH_LIST_ARRAY.get(GUID);

    switch (name) {
        case 'Light':
            return new RawShaderMaterial(getShaders().get('Light'));

        default:
            return new MeshBasicMaterial({ vertexColors: true, side: DoubleSide });
    }
}

export function TiltLoader() {
    return { TiltLoader: TiltLoader };
}