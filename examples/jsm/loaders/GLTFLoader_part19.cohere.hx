class GLTFMeshGpuInstancing {
    public var name:String;
    public var parser:Dynamic;

    public function new(parser:Dynamic) {
        this.name = EXTENSIONS.EXT_MESH_GPU_INSTANCING;
        this.parser = parser;
    }

    public function createNodeMesh(nodeIndex:Int):Dynamic {
        var json = parser.json;
        var nodeDef = json.nodes[nodeIndex];

        if (!nodeDef.extensions || !nodeDef.extensions[name] || nodeDef.mesh == null) {
            return null;
        }

        var meshDef = json.meshes[nodeDef.mesh];

        // No Points or Lines + Instancing support yet
        var invalidMode = false;
        for (primitive in meshDef.primitives) {
            if (primitive.mode != WEBGL_CONSTANTS.TRIANGLES &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_STRIP &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_FAN) {
                invalidMode = true;
                break;
            }
        }
        if (invalidMode) {
            return null;
        }

        var extensionDef = nodeDef.extensions[name];
        var attributesDef = extensionDef.attributes;

        // @TODO: Can we support InstancedMesh + SkinnedMesh?
        var pending = [];
        var attributes = { };

        for (key in attributesDef) {
            pending.push(parser.getDependency('accessor', attributesDef[key]).then(function (accessor) {
                attributes[key] = accessor;
                return attributes[key];
            }));
        }

        if (pending.length < 1) {
            return null;
        }

        pending.push(parser.createNodeMesh(nodeIndex));

        return Promise.all(pending).then(function (results) {
            var nodeObject = results.pop();
            var meshes = nodeObject.isGroup ? nodeObject.children : [nodeObject];
            var count = results[0].count; // All attribute counts should be same
            var instancedMeshes = [];

            for (mesh in meshes) {
                // Temporal variables
                var m = new Matrix4();
                var p = new Vector3();
                var q = new Quaternion();
                var s = new Vector3(1, 1, 1);

                var instancedMesh = new InstancedMesh(mesh.geometry, mesh.material, count);

                for (i in 0...count) {
                    if (attributes.TRANSLATION != null) {
                        p.fromBufferAttribute(attributes.TRANSLATION, i);
                    }

                    if (attributes.ROTATION != null) {
                        q.fromBufferAttribute(attributes.ROTATION, i);
                    }

                    if (attributes.SCALE != null) {
                        s.fromBufferAttribute(attributes.SCALE, i);
                    }

                    instancedMesh.setMatrixAt(i, m.compose(p, q, s));
                }

                // Add instance attributes to the geometry, excluding TRS.
                for (attributeName in attributes) {
                    if (attributeName == '_COLOR_0') {
                        var attr = attributes[attributeName];
                        instancedMesh.instanceColor = new InstancedBufferAttribute(attr.array, attr.itemSize, attr.normalized);
                    } else if (attributeName != 'TRANSLATION' &&
                        attributeName != 'ROTATION' &&
                        attributeName != 'SCALE') {

                        mesh.geometry.setAttribute(attributeName, attributes[attributeName]);
                    }
                }

                // Just in case
                Object3D.prototype.copy.call(instancedMesh, mesh);

                parser.assignFinalMaterial(instancedMesh);

                instancedMeshes.push(instancedMesh);
            }

            if (nodeObject.isGroup) {
                nodeObject.clear();

                for (mesh in instancedMeshes) {
                    nodeObject.add(mesh);
                }

                return nodeObject;
            }

            return instancedMeshes[0];
        });
    }
}