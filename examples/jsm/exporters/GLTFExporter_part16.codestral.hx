import js.html.ArrayBufferView;
import three.js.math.Matrix4;
import three.js.math.Vector3;
import three.js.math.Quaternion;
import three.js.core.BufferAttribute;
import three.js.exporters.GLTFWriter;

class GLTFMeshGpuInstancing {

    private var writer: GLTFWriter;
    public var name: String = 'EXT_mesh_gpu_instancing';

    public function new(writer: GLTFWriter) {
        this.writer = writer;
    }

    public function writeNode(object: Dynamic, nodeDef: Dynamic) {
        if (!Std.is(object, js.html.JsObject) || !(js.html.JsObject(object).hasOwnProperty("isInstancedMesh"))) return;

        var mesh = object;

        var translationAttr = new Float32Array(mesh.count * 3);
        var rotationAttr = new Float32Array(mesh.count * 4);
        var scaleAttr = new Float32Array(mesh.count * 3);

        var matrix = new Matrix4();
        var position = new Vector3();
        var quaternion = new Quaternion();
        var scale = new Vector3();

        for (var i:Int = 0; i < mesh.count; i++) {
            mesh.getMatrixAt(i, matrix);
            matrix.decompose(position, quaternion, scale);

            position.toArray(translationAttr, i * 3);
            quaternion.toArray(rotationAttr, i * 4);
            scale.toArray(scaleAttr, i * 3);
        }

        var attributes = {
            "TRANSLATION": this.writer.processAccessor(new BufferAttribute(translationAttr, 3)),
            "ROTATION": this.writer.processAccessor(new BufferAttribute(rotationAttr, 4)),
            "SCALE": this.writer.processAccessor(new BufferAttribute(scaleAttr, 3))
        };

        if (Std.is(mesh.instanceColor, js.html.JsObject) && js.html.JsObject(mesh.instanceColor).hasOwnProperty("array")) {
            attributes["_COLOR_0"] = this.writer.processAccessor(mesh.instanceColor);
        }

        if (!Std.is(nodeDef.extensions, js.html.JsObject)) {
            nodeDef.extensions = {};
        }
        nodeDef.extensions[this.name] = { "attributes": attributes };

        this.writer.extensionsUsed[this.name] = true;
        this.writer.extensionsRequired[this.name] = true;
    }
}