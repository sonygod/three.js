import js.html.ArrayBufferView;

class GeometryBuilder {

    public function build(data:Dynamic):BufferGeometry {

        var positions:Array<Float> = [];
        var uvs:Array<Float> = [];
        var normals:Array<Float> = [];

        var indices:Array<Int> = [];

        var groups:Array<Dynamic> = [];

        var bones:Array<Dynamic> = [];
        var skinIndices:Array<Int> = [];
        var skinWeights:Array<Float> = [];

        var morphTargets:Array<Dynamic> = [];
        var morphPositions:Array<Dynamic> = [];

        var iks:Array<Dynamic> = [];
        var grants:Array<Dynamic> = [];

        var rigidBodies:Array<Dynamic> = [];
        var constraints:Array<Dynamic> = [];

        var offset:Int = 0;
        var boneTypeTable:Dynamic = {};

        for (i in 0...data.metadata.vertexCount) {

            var v = data.vertices[i];

            for (j in 0...v.position.length) {

                positions.push(v.position[j]);

            }

            for (j in 0...v.normal.length) {

                normals.push(v.normal[j]);

            }

            for (j in 0...v.uv.length) {

                uvs.push(v.uv[j]);

            }

            for (j in 0...4) {

                skinIndices.push(v.skinIndices.length - 1 >= j ? v.skinIndices[j] : 0.0);

            }

            for (j in 0...4) {

                skinWeights.push(v.skinWeights.length - 1 >= j ? v.skinWeights[j] : 0.0);

            }

        }

        for (i in 0...data.metadata.faceCount) {

            var face = data.faces[i];

            for (j in 0...face.indices.length) {

                indices.push(face.indices[j]);

            }

        }

        for (i in 0...data.metadata.materialCount) {

            var material = data.materials[i];

            groups.push({
                offset: offset * 3,
                count: material.faceCount * 3
            });

            offset += material.faceCount;

        }

        for (i in 0...data.metadata.rigidBodyCount) {

            var body = data.rigidBodies[i];
            var value = boneTypeTable[body.boneIndex];

            value = value === null ? body.type : Math.max(body.type, value);

            boneTypeTable[body.boneIndex] = value;

        }

        for (i in 0...data.metadata.boneCount) {

            var boneData = data.bones[i];

            var bone = {
                index: i,
                transformationClass: boneData.transformationClass,
                parent: boneData.parentIndex,
                name: boneData.name,
                pos: boneData.position.slice(0, 3),
                rotq: [0, 0, 0, 1],
                scl: [1, 1, 1],
                rigidBodyType: boneTypeTable[i] !== null ? boneTypeTable[i] : -1
            };

            if (bone.parent !== -1) {

                bone.pos[0] -= data.bones[bone.parent].position[0];
                bone.pos[1] -= data.bones[bone.parent].position[1];
                bone.pos[2] -= data.bones[bone.parent].position[2];

            }

            bones.push(bone);

        }

        if (data.metadata.format === 'pmd') {

            for (i in 0...data.metadata.ikCount) {

                var ik = data.iks[i];

                var param = {
                    target: ik.target,
                    effector: ik.effector,
                    iteration: ik.iteration,
                    maxAngle: ik.maxAngle * 4,
                    links: []
                };

                for (j in 0...ik.links.length) {

                    var link = {};
                    link.index = ik.links[j].index;
                    link.enabled = true;

                    if (data.bones[link.index].name.indexOf('ひざ') >= 0) {

                        link.limitation = new Vector3(1.0, 0.0, 0.0);

                    }

                    param.links.push(link);

                }

                iks.push(param);

            }

        } else {

            for (i in 0...data.metadata.boneCount) {

                var ik = data.bones[i].ik;

                if (ik === null) continue;

                var param = {
                    target: i,
                    effector: ik.effector,
                    iteration: ik.iteration,
                    maxAngle: ik.maxAngle,
                    links: []
                };

                for (j in 0...ik.links.length) {

                    var link = {};
                    link.index = ik.links[j].index;
                    link.enabled = true;

                    if (ik.links[j].angleLimitation === 1) {

                        var rotationMin = ik.links[j].lowerLimitationAngle;
                        var rotationMax = ik.links[j].upperLimitationAngle;

                        var tmp1 = -rotationMax[0];
                        var tmp2 = -rotationMax[1];
                        rotationMax[0] = -rotationMin[0];
                        rotationMax[1] = -rotationMin[1];
                        rotationMin[0] = tmp1;
                        rotationMin[1] = tmp2;

                        link.rotationMin = new Vector3(rotationMin[0], rotationMin[1], rotationMin[2]);
                        link.rotationMax = new Vector3(rotationMax[0], rotationMax[1], rotationMax[2]);

                    }

                    param.links.push(link);

                }

                iks.push(param);

                bones[i].ik = param;

            }

        }

        if (data.metadata.format === 'pmx') {

            var grantEntryMap:Dynamic = {};

            for (i in 0...data.metadata.boneCount) {

                var boneData = data.bones[i];
                var grant = boneData.grant;

                if (grant === null) continue;

                var param = {
                    index: i,
                    parentIndex: grant.parentIndex,
                    ratio: grant.ratio,
                    isLocal: grant.isLocal,
                    affectRotation: grant.affectRotation,
                    affectPosition: grant.affectPosition,
                    transformationClass: boneData.transformationClass
                };

                grantEntryMap[i] = {parent: null, children: [], param: param, visited: false};

            }

            var rootEntry = {parent: null, children: [], param: null, visited: false};

            for (boneIndex in Reflect.fields(grantEntryMap)) {

                var grantEntry = grantEntryMap[boneIndex];
                var parentGrantEntry = grantEntryMap[grantEntry.parentIndex] || rootEntry;

                grantEntry.parent = parentGrantEntry;
                parentGrantEntry.children.push(grantEntry);

            }

            function traverse(entry:Dynamic) {

                if (entry.param !== null) {

                    grants.push(entry.param);

                    bones[entry.param.index].grant = entry.param;

                }

                entry.visited = true;

                for (i in 0...entry.children.length) {

                    var child = entry.children[i];

                    if (!child.visited) traverse(child);

                }

            }

            traverse(rootEntry);

        }

        function updateAttributes(attribute:Dynamic, morph:Dynamic, ratio:Float) {

            for (i in 0...morph.elementCount) {

                var element = morph.elements[i];

                var index:Int;

                if (data.metadata.format === 'pmd') {

                    index = data.morphs[0].elements[element.index].index;

                } else {

                    index = element.index;

                }

                attribute.array[index * 3 + 0] += element.position[0] * ratio;
                attribute.array[index * 3 + 1] += element.position[1] * ratio;
                attribute.array[index * 3 + 2] += element.position[2] * ratio;

            }

        }

        for (i in 0...data.metadata.morphCount) {

            var morph = data.morphs[i];
            var params = {name: morph.name};

            var attribute = new Float32Array(data.metadata.vertexCount * 3);
            attribute.name = morph.name;

            for (j in 0...data.metadata.vertexCount * 3) {

                attribute[j] = positions[j];

            }

            if (data.metadata.format === 'pmd') {

                if (i !== 0) {

                    updateAttributes(attribute, morph, 1.0);

                }

            } else {

                if (morph.type === 0) {

                    for (j in 0...morph.elementCount) {

                        var morph2 = data.morphs[morph.elements[j].index];
                        var ratio = morph.elements[j].ratio;

                        if (morph2.type === 1) {

                            updateAttributes(attribute, morph2, ratio);

                        } else {

                            // TODO: implement

                        }

                    }

                } else if (morph.type === 1) {

                    updateAttributes(attribute, morph, 1.0);

                } else if (morph.type === 2) {

                    // TODO: implement

                } else if (morph.type === 3) {

                    // TODO: implement

                } else if (morph.type === 4) {

                    // TODO: implement

                } else if (morph.type === 5) {

                    // TODO: implement

                } else if (morph.type === 6) {

                    // TODO: implement

                } else if (morph.type === 7) {

                    // TODO: implement

                } else if (morph.type === 8) {

                    // TODO: implement

                }

            }

            morphTargets.push(params);
            morphPositions.push(attribute);

        }

        for (i in 0...data.metadata.rigidBodyCount) {

            var rigidBody = data.rigidBodies[i];
            var params = {};

            for (key in Reflect.fields(rigidBody)) {

                params[key] = rigidBody[key];

            }

            if (data.metadata.format === 'pmx') {

                if (params.boneIndex !== -1) {

                    var bone = data.bones[params.boneIndex];
                    params.position[0] -= bone.position[0];
                    params.position[1] -= bone.position[1];
                    params.position[2] -= bone.position[2];

                }

            }

            rigidBodies.push(params);

        }

        for (i in 0...data.metadata.constraintCount) {

            var constraint = data.constraints[i];
            var params = {};

            for (key in Reflect.fields(constraint)) {

                params[key] = constraint[key];

            }

            var bodyA = rigidBodies[params.rigidBodyIndex1];
            var bodyB = rigidBodies[params.rigidBodyIndex2];

            if (bodyA.type !== 0 && bodyB.type === 2) {

                if (bodyA.boneIndex !== -1 && bodyB.boneIndex !== -1 &&
                    data.bones[bodyB.boneIndex].parentIndex === bodyA.boneIndex) {

                    bodyB.type = 1;

                }

            }

            constraints.push(params);

        }

        var geometry = new BufferGeometry();

        geometry.setAttribute('position', new Float32Array(positions));
        geometry.setAttribute('normal', new Float32Array(normals));
        geometry.setAttribute('uv', new Float32Array(uvs));
        geometry.setAttribute('skinIndex', new Uint16Array(skinIndices));
        geometry.setAttribute('skinWeight', new Float32Array(skinWeights));
        geometry.setIndex(new Uint32Array(indices));

        for (i in 0...groups.length) {

            geometry.addGroup(groups[i].offset, groups[i].count, i);

        }

        geometry.bones = bones;

        geometry.morphTargets = morphTargets;
        geometry.morphAttributes.position = morphPositions;
        geometry.morphTargetsRelative = false;

        geometry.userData.MMD = {
            bones: bones,
            iks: iks,
            grants: grants,
            rigidBodies: rigidBodies,
            constraints: constraints,
            format: data.metadata.format
        };

        geometry.computeBoundingSphere();

        return geometry;

    }

}