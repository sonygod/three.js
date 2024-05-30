class GLTFMeshGpuInstancing {

    var parser:GLTFParser;
    var name:String;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_MESH_GPU_INSTANCING;
    }

    public function createNodeMesh(nodeIndex:Int):Promise<Dynamic> {
        var json = this.parser.json;
        var nodeDef = json.nodes[nodeIndex];

        if (!nodeDef.extensions || !nodeDef.extensions[this.name] || nodeDef.mesh === undefined) {
            return null;
        }

        var meshDef = json.meshes[nodeDef.mesh];

        for (primitive in meshDef.primitives) {
            if (primitive.mode != WEBGL_CONSTANTS.TRIANGLES &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_STRIP &&
                primitive.mode != WEBGL_CONSTANTS.TRIANGLE_FAN &&
                primitive.mode != undefined) {
                return null;
            }
        }

        var extensionDef = nodeDef.extensions[this.name];
        var attributesDef = extensionDef.attributes;

        var pending = [];
        var attributes = {};

        for (key in attributesDef) {
            pending.push(this.parser.getDependency('accessor', attributesDef[key]).then(accessor -> {
                attributes[key] = accessor;
                return attributes[key];
            }));
        }

        if (pending.length < 1) {
            return null;
        }

        pending.push(this.parser.createNodeMesh(nodeIndex));

        return Promise.all(pending).then(results -> {
            var nodeObject = results.pop();
            var meshes = nodeObject.isGroup ? nodeObject.children : [nodeObject];
            var count = results[0].count;
            var instancedMeshes = [];

            for (mesh in meshes) {
                var m = new Matrix4();
                var p = new Vector3();
                var q = new Quaternion();
                var s = new Vector3(1, 1, 1);

                var instancedMesh = new InstancedMesh(mesh.geometry, mesh.material, count);

                for (i in 0...count) {
                    if (attributes.TRANSLATION) {
                        p.fromBufferAttribute(attributes.TRANSLATION, i);
                    }

                    if (attributes.ROTATION) {
                        q.fromBufferAttribute(attributes.ROTATION, i);
                    }

                    if (attributes.SCALE) {
                        s.fromBufferAttribute(attributes.SCALE, i);
                    }

                    instancedMesh.setMatrixAt(i, m.compose(p, q, s));
                }

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

                Object3D.prototype.copy.call(instancedMesh, mesh);
                this.parser.assignFinalMaterial(instancedMesh);
                instancedMeshes.push(instancedMesh);
            }

            if (nodeObject.isGroup) {
                nodeObject.clear();
                nodeObject.add(instancedMeshes);
                return nodeObject;
            }

            return instancedMeshes[0];
        });
    }
}