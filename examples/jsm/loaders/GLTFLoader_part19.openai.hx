package three.js.examples.jsm.loaders;

import three.js.loaders.GLTFLoader;
import three.js.core.Object3D;
import three.js CORE.Matrix4;
import three.js.math.Vector3;
import three.js.math.Quaternion;

class GLTFMeshGpuInstancing {
    public var name:String;
    public var parser:GLTFLoader;

    public function new(parser:GLTFLoader) {
        name = EXTENSIONS.EXT_MESH_GPU_INSTANCING;
        this.parser = parser;
    }

    public function createNodeMesh(nodeIndex:Int):Promise<Object3D> {
        var json:Dynamic = parser.json;
        var nodeDef:Dynamic = json.nodes[nodeIndex];

        if (!nodeDef.extensions || !nodeDef.extensions[name] || nodeDef.mesh == null) {
            return Promise.resolve(null);
        }

        var meshDef:Dynamic = json.meshes[nodeDef.mesh];

        // No Points or Lines + Instancing support yet
        for (primitive in meshDef.primitives) {
            if (primitive.mode != WEBGL_CONSTANTS.TRIANGLES &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_STRIP &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_FAN &&
                primitive.mode != null) {
                return Promise.resolve(null);
            }
        }

        var extensionDef:Dynamic = nodeDef.extensions[name];
        var attributesDef:Dynamic = extensionDef.attributes;

        // @TODO: Can we support InstancedMesh + SkinnedMesh?
        var pending:Array<Promise<Accessor>> = [];
        var attributes:Map<String, Accessor> = new Map();

        for (key in attributesDef) {
            pending.push(parser.getDependency('accessor', attributesDef[key]).then(function(accessor:Accessor) {
                attributes[key] = accessor;
                return accessor;
            }));
        }

        if (pending.length < 1) {
            return Promise.resolve(null);
        }

        pending.push(parser.createNodeMesh(nodeIndex));

        return Promise.all(pending).then(function(results:Array<Dynamic>) {
            var nodeObject:Object3D = results.pop();
            var meshes:Array<Object3D> = nodeObject.isGroup ? nodeObject.children : [nodeObject];
            var count:Int = results[0].count; // All attribute counts should be same
            var instancedMeshes:Array<InstancedMesh> = [];

            for (mesh in meshes) {
                // Temporal variables
                var m:Matrix4 = new Matrix4();
                var p:Vector3 = new Vector3();
                var q:Quaternion = new Quaternion();
                var s:Vector3 = new Vector3(1, 1, 1);

                var instancedMesh:InstancedMesh = new InstancedMesh(mesh.geometry, mesh.material, count);

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

                // Add instance attributes to the geometry, excluding TRS.
                for (attributeName in attributes.keys()) {
                    if (attributeName == '_COLOR_0') {
                        var attr:Accessor = attributes.get(attributeName);
                        instancedMesh.instanceColor = new InstancedBufferAttribute(attr.array, attr.itemSize, attr.normalized);
                    } else if (attributeName != 'TRANSLATION' && attributeName != 'ROTATION' && attributeName != 'SCALE') {
                        mesh.geometry.setAttribute(attributeName, attributes.get(attributeName));
                    }
                }

                // Just in case
                Object3D.prototype.copy(instancedMesh, mesh);

                parser.assignFinalMaterial(instancedMesh);

                instancedMeshes.push(instancedMesh);
            }

            if (nodeObject.isGroup) {
                nodeObject.clear();
                nodeObject.add(instancedMeshes...);
                return nodeObject;
            }

            return instancedMeshes[0];
        });
    }
}