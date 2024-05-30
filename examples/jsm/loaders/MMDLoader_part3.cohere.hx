class GeometryBuilder {
    function build(data:Dynamic) : BufferGeometry {
        // for geometry
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

        // for work
        var offset:Int = 0;
        var boneTypeTable:Dynamic = {};

        // positions, normals, uvs, skinIndices, skinWeights

        for (i in 0...data.metadata.vertexCount) {
            var v = data.vertices[$i];

            for (j in 0...v.position.length) {
                positions.push(v.position[$j]);
            }

            for (j in 0...v.normal.length) {
                normals.push(v.normal[$j]);
            }

            for (j in 0...v.uv.length) {
                uvs.push(v.uv[$j]);
            }

            for (j in 0...4) {
                skinIndices.push(if (v.skinIndices.length - 1 >= j) v.skinIndices[j] else 0);
            }

            for (j in 0...4) {
                skinWeights.push(if (v.skinWeights.length - 1 >= j) v.skinWeights[j] else 0.0);
            }
        }

        // indices

        for (i in 0...data.metadata.faceCount) {
            var face = data.faces[$i];

            for (j in 0...face.indices.length) {
                indices.push(face.indices[$j]);
            }
        }

        // groups

        for (i in 0...data.metadata.materialCount) {
            var material = data.materials[$i];

            groups.push({ offset: offset * 3, count: material.faceCount * 3 });

            offset += material.faceCount;
        }

        // bones

        for (i in 0...data.metadata.rigidBodyCount) {
            var body = data.rigidBodies[$i];
            var value = boneTypeTable[body.boneIndex];

            // keeps greater number if already value is set without any special reasons
            value = if (value == null) body.type else Math.max(body.type, value);

            boneTypeTable[body.boneIndex] = value;
        }

        for (i in 0...data.metadata.boneCount) {
            var boneData = data.bones[$i];

            var bone = {
                index: i,
                transformationClass: boneData.transformationClass,
                parent: boneData.parentIndex,
                name: boneData.name,
                pos: boneData.position.slice(0, 3),
                rotq: [0, 0, 0, 1],
                scl: [1, 1, 1],
                rigidBodyType: if (boneTypeTable[i] != null) boneTypeTable[i] else -1
            };

            if (bone.parent != -1) {
                bone.pos[0] -= data.bones[bone.parent].position[0];
                bone.pos[1] -= data.bones[bone.parent].position[1];
                bone.pos[2] -= data.bones[bone.parent].position[2];
            }

            bones.push(bone);
        }

        // iks

        // TODO: remove duplicated codes between PMD and PMX
        if (data.metadata.format == 'pmd') {
            for (i in 0...data.metadata.ikCount) {
                var ik = data.iks[$i];

                var param = {
                    target: ik.target,
                    effector: ik.effector,
                    iteration: ik.iteration,
                    maxAngle: ik.maxAngle * 4,
                    links: []
                };

                for (j in 0...ik.links.length) {
                    var link = { index: ik.links[$j].index, enabled: true };

                    if (data.bones[link.index].name.indexOf('ひざ') >= 0) {
                        link.limitation = new Vector3(1.0, 0.0, 0.0);
                    }

                    param.links.push(link);
                }

                iks.push(param);
            }
        } else {
            for (i in 0...data.metadata.boneCount) {
                var ik = data.bones[$i].ik;

                if (ik == null) continue;

                var param = {
                    target: i,
                    effector: ik.effector,
                    iteration: ik.iteration,
                    maxAngle: ik.maxAngle,
                    links: []
                };

                for (j in 0...ik.links.length) {
                    var link = { index: ik.links[$j].index, enabled: true };

                    if (ik.links[$j].angleLimitation == 1) {
                        // Revert if rotationMin/Max doesn't work well
                        // link.limitation = new Vector3( 1.0, 0.0, 0.0 );

                        var rotationMin = ik.links[$j].lowerLimitationAngle;
                        var rotationMax = ik.links[$j].upperLimitationAngle;

                        // Convert Left to Right coordinate by myself because
                        // MMDParser doesn't convert. It's a MMDParser's bug

                        var tmp1 = -rotationMax[0];
                        var tmp2 = -rotationMax[1];
                        rotationMax[0] = -rotationMin[0];
                        rotationMax[1] = -rotationMin[1];
                        rotationMin[0] = tmp1;
                        rotationMin[1] = tmp2;

                        link.rotationMin = new Vector3().fromArray(rotationMin);
                        link.rotationMax = new Vector3().fromArray(rotationMax);
                    }

                    param.links.push(link);
                }

                iks.push(param);

                // Save the reference even from bone data for efficiently
                // simulating PMX animation system
                bones[$i].ik = param;
            }
        }

        // grants

        if (data.metadata.format == 'pmx') {
            // bone index -> grant entry map
            var grantEntryMap:Dynamic = {};

            for (i in 0...data.metadata.boneCount) {
                var boneData = data.bones[$i];
                var grant = boneData.grant;

                if (grant == null) continue;

                var param = {
                    index: i,
                    parentIndex: grant.parentIndex,
                    ratio: grant.ratio,
                    isLocal: grant.isLocal,
                    affectRotation: grant.affectRotation,
                    affectPosition: grant.affectPosition,
                    transformationClass: boneData.transformationClass
                };

                grantEntryMap[i] = { parent: null, children: [], param: param, visited: false };
            }

            var rootEntry = { parent: null, children: [], param: null, visited: false };

            // Build a tree representing grant hierarchy

            for (boneIndex in grantEntryMap) {
                var grantEntry = grantEntryMap[$boneIndex];
                var parentGrantEntry = if (grantEntryMap[grantEntry.parentIndex] != null) grantEntryMap[grantEntry.parentIndex] else rootEntry;

                grantEntry.parent = parentGrantEntry;
                parentGrantEntry.children.push(grantEntry);
            }

            // Sort grant parameters from parents to children because
            // grant uses parent's transform that parent's grant is already applied
            // so grant should be applied in order from parents to children

            function traverse(entry) {
                if (entry.param != null) {
                    grants.push(entry.param);

                    // Save the reference even from bone data for efficiently
                    // simulating PMX animation system
                    bones[entry.param.index].grant = entry.param;
                }

                entry.visited = true;

                for (i in 0...entry.children.length) {
                    var child = entry.children[$i];

                    // Cut off a loop if exists. (Is a grant loop invalid?)
                    if (!child.visited) traverse(child);
                }
            }

            traverse(rootEntry);
        }

        // morph

        function updateAttributes(attribute, morph, ratio) {
            for (i in 0...morph.elementCount) {
                var element = morph.elements[$i];

                var index:Int;

                if (data.metadata.format == 'pmd') {
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
            var morph = data.morphs[$i];
            var params = { name: morph.name };

            var attribute = new Float32BufferAttribute(data.metadata.vertexCount * 3, 3);
            attribute.name = morph.name;

            for (j in 0...data.metadata.vertexCount * 3) {
                attribute.array[$j] = positions[$j];
            }

            if (data.metadata.format == 'pmd') {
                if (i != 0) {
                    updateAttributes(attribute, morph, 1.0);
                }
            } else {
                if (morph.type == 0) { // group
                    for (j in 0...morph.elementCount) {
                        var morph2 = data.morphs[morph.elements[$j].index];
                        var ratio = morph.elements[$j].ratio;

                        if (morph2.type == 1) {
                            updateAttributes(attribute, morph2, ratio);
                        } else {
                            // TODO: implement
                        }
                    }
                } else if (morph.type == 1) { // vertex
                    updateAttributes(attribute, morph, 1.0);
                } else if (morph.type == 2) { // bone
                    // TODO: implement
                } else if (morph.type == 3) { // uv
                    // TODO: implement
                } else if (morph.type == 4) { // additional uv1
                    // TODO: implement
                } else if (morph.type == 5) { // additional uv2
                    // TODO: implement
                } else if (morph.type == 6) { // additional uv3
                    // TODO: implement
                } else if (morph.type == 7) { // additional uv4
                    // TODO: implement
                } else if (morph.type == 8) { // material
                    // TODO: implement
                }
            }

            morphTargets.push(params);
            morphPositions.push(attribute);
        }

        // rigid bodies from rigidBodies field.

        for (i in 0...data.metadata.rigidBodyCount) {
            var rigidBody = data.rigidBodies[$i];
            var params = {};

            for (key in rigidBody) {
                params[$key] = rigidBody[$key];
            }

            /*
                     * RigidBody position parameter in PMX seems global position
                     * while the one in PMD seems offset from corresponding bone.
                     * So unify being offset.
                     */
            if (data.metadata.format == 'pmx') {
                if (params.boneIndex != -1) {
                    var bone = data.bones[params.boneIndex];
                    params.position[0] -= bone.position[0];
                    params.position[1] -= bone.position[1];
                    params.position[2] -= bone.position[2];
                }
            }

            rigidBodies.push(params);
        }

        // constraints from constraints field.

        for (i in 0...data.metadata.constraintCount) {
            var constraint = data.constraints[$i];
            var params = {};

            for (key in constraint) {
                params[$key] = constraint[$key];
            }

            var bodyA = rigidBodies[params.rigidBodyIndex1];
            var bodyB = rigidBodies[params.rigidBodyIndex2];

            // Refer to http://www20.atpages.jp/katwat/wp/?p=4135
            if (bodyA.type != 0 && bodyB.type == 2) {
                if (bodyA.boneIndex != -1 && bodyB.boneIndex != -1 && data.bones[bodyB.boneIndex].parentIndex == bodyA.boneIndex) {
                    bodyB.type = 1;
                }
            }

            constraints.push(params);
        }

        // build BufferGeometry.

        var geometry = new BufferGeometry();

        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
        geometry.setAttribute('skinIndex', new Uint16BufferAttribute(skinIndices, 4));
        geometry.setAttribute('skinWeight', new Float32BufferAttribute(skinWeights, 4));
        geometry.setIndex(indices);

        for (i in 0...groups.length) {
            geometry.addGroup(groups[$i].offset, groups[$i].count, $i);
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