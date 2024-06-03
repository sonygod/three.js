import three.examples.jsm.loaders.EXTENSIONS;
import three.core.Object3D;
import three.core.Matrix4;
import three.math.Vector3;
import three.math.Quaternion;
import three.objects.InstancedMesh;
import three.objects.InstancedBufferAttribute;
import three.core.BufferAttribute;
import three.examples.jsm.loaders.GLTFLoader;
import haxe.remoting.Async;
import haxe.remoting.Promise;
import three.constants.WEBGL_CONSTANTS;

class GLTFMeshGpuInstancing {
    public var name:String;
    public var parser:GLTFLoader;

    public function new(parser:GLTFLoader) {
        this.name = EXTENSIONS.EXT_MESH_GPU_INSTANCING;
        this.parser = parser;
    }

    public function createNodeMesh(nodeIndex:Int):Promise<Object3D> {
        var json = this.parser.json;
        var nodeDef = json.nodes[nodeIndex];

        if (nodeDef.extensions == null || nodeDef.extensions[this.name] == null || nodeDef.mesh == null) {
            return Async.resolve(null);
        }

        var meshDef = json.meshes[nodeDef.mesh];

        for (primitive in meshDef.primitives) {
            if (primitive.mode != WEBGL_CONSTANTS.TRIANGLES &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_STRIP &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_FAN &&
                primitive.mode != null) {
                return Async.resolve(null);
            }
        }

        var extensionDef = nodeDef.extensions[this.name];
        var attributesDef = extensionDef.attributes;

        var pending:Array<Promise<BufferAttribute>> = [];
        var attributes:haxe.ds.StringMap<BufferAttribute> = new haxe.ds.StringMap();

        for (key in Reflect.fields(attributesDef)) {
            var accessorPromise = this.parser.getDependency('accessor', attributesDef[key]);
            pending.push(accessorPromise.then((accessor) => {
                attributes.set(key, accessor);
                return accessor;
            }));
        }

        if (pending.length < 1) {
            return Async.resolve(null);
        }

        var nodePromise = this.parser.createNodeMesh(nodeIndex);
        pending.push(nodePromise);

        return Promise.all(pending).then((results) => {
            var nodeObject = results.pop();
            var meshes = nodeObject.isGroup ? nodeObject.children : [nodeObject];
            var count = results[0].count;
            var instancedMeshes:Array<InstancedMesh> = [];

            for (mesh in meshes) {
                var m = new Matrix4();
                var p = new Vector3();
                var q = new Quaternion();
                var s = new Vector3(1, 1, 1);

                var instancedMesh = new InstancedMesh(mesh.geometry, mesh.material, count);

                for (i in 0...count) {
                    if (attributes.exists('TRANSLATION')) {
                        p.fromBufferAttribute(attributes.get('TRANSLATION'), i);
                    }

                    if (attributes.exists('ROTATION')) {
                        q.fromBufferAttribute(attributes.get('ROTATION'), i);
                    }

                    if (attributes.exists('SCALE')) {
                        s.fromBufferAttribute(attributes.get('SCALE'), i);
                    }

                    instancedMesh.setMatrixAt(i, m.compose(p, q, s));
                }

                for (attributeName in Reflect.fields(attributes)) {
                    if (attributeName == '_COLOR_0') {
                        var attr = attributes.get(attributeName);
                        instancedMesh.instanceColor = new InstancedBufferAttribute(attr.array, attr.itemSize, attr.normalized);
                    } else if (attributeName != 'TRANSLATION' && attributeName != 'ROTATION' && attributeName != 'SCALE') {
                        mesh.geometry.setAttribute(attributeName, attributes.get(attributeName));
                    }
                }

                Object3D.prototype.copy.call(instancedMesh, mesh);

                this.parser.assignFinalMaterial(instancedMesh);

                instancedMeshes.push(instancedMesh);
            }

            if (nodeObject.isGroup) {
                nodeObject.clear();
                nodeObject.add(...instancedMeshes);
                return nodeObject;
            }

            return instancedMeshes[0];
        });
    }
}