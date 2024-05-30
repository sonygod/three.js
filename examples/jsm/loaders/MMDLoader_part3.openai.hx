package three.js.loaders;

import three.js.BufferGeometry;
import three.js.BufferAttribute;
import three.js.Vector3;

class GeometryBuilder {
    public function build(data:Object):BufferGeometry {
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
        var morphPositions:Array<BufferAttribute> = [];

        var iks:Array<Dynamic> = [];
        var grants:Array<Dynamic> = [];

        var rigidBodies:Array<Dynamic> = [];
        var constraints:Array<Dynamic> = [];

        // for work
        var offset:Int = 0;
        var boneTypeTable:Map<Int, Int> = new Map();

        // positions, normals, uvs, skinIndices, skinWeights
        for (i in 0...data.metadata.vertexCount) {
            var v:Object = data.vertices[i];

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

        // indices
        for (i in 0...data.metadata.faceCount) {
            var face:Object = data.faces[i];

            for (j in 0...face.indices.length) {
                indices.push(face.indices[j]);
            }
        }

        // groups
        for (i in 0...data.metadata.materialCount) {
            var material:Object = data.materials[i];

            groups.push({
                offset: offset * 3,
                count: material.faceCount * 3
            });

            offset += material.faceCount;
        }

        // bones
        for (i in 0...data.metadata.rigidBodyCount) {
            var body:Object = data.rigidBodies[i];
            var value:Int = boneTypeTable.get(body.boneIndex);

            // keeps greater number if already value is set without any special reasons
            value = value == null ? body.type : Math.max(body.type, value);

            boneTypeTable[body.boneIndex] = value;
        }

        for (i in 0...data.metadata.boneCount) {
            var boneData:Object = data.bones[i];

            var bone:Dynamic = {
                index: i,
                transformationClass: boneData.transformationClass,
                parent: boneData.parentIndex,
                name: boneData.name,
                pos: boneData.position.slice(0, 3),
                rotq: [0, 0, 0, 1],
                scl: [1, 1, 1],
                rigidBodyType: boneTypeTable.get(i) != null ? boneTypeTable.get(i) : -1
            };

            if (bone.parent != -1) {
                bone.pos[0] -= data.bones[bone.parent].position[0];
                bone.pos[1] -= data.bones[bone.parent].position[1];
                bone.pos[2] -= data.bones[bone.parent].position[2];
            }

            bones.push(bone);
        }

        // iks
        if (data.metadata.format == 'pmd') {
            // ...
        } else {
            for (i in 0...data.metadata.boneCount) {
                var ik:Object = data.bones[i].ik;

                if (ik == null) continue;

                var param:Dynamic = {
                    target: i,
                    effector: ik.effector,
                    iteration: ik.iteration,
                    maxAngle: ik.maxAngle,
                    links: []
                };

                for (j in 0...ik.links.length) {
                    var link:Dynamic = {};
                    link.index = ik.links[j].index;
                    link.enabled = true;

                    if (ik.links[j].angleLimitation == 1) {
                        // ...
                    }

                    param.links.push(link);
                }

                iks.push(param);

                // Save the reference even from bone data for efficiently
                // simulating PMX animation system
                bones[i].ik = param;
            }
        }

        // grants
        if (data.metadata.format == 'pmx') {
            // ...
        }

        // morph
        function updateAttributes(attribute:BufferAttribute, morph:Object, ratio:Float) {
            for (i in 0...morph.elementCount) {
                var element:Object = morph.elements[i];

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
            var morph:Object = data.morphs[i];
            var params:Dynamic = { name: morph.name };

            var attribute:BufferAttribute = new Float32BufferAttribute(data.metadata.vertexCount * 3, 3);
            attribute.name = morph.name;

            for (j in 0...data.metadata.vertexCount * 3) {
                attribute.array[j] = positions[j];
            }

            if (data.metadata.format == 'pmd') {
                if (i != 0) {
                    updateAttributes(attribute, morph, 1.0);
                }
            } else {
                if (morph.type == 0) { // group
                    // ...
                } else if (morph.type == 1) { // vertex
                    updateAttributes(attribute, morph, 1.0);
                } else {
                    // TODO: implement
                }
            }

            morphTargets.push(params);
            morphPositions.push(attribute);
        }

        // rigid bodies from rigidBodies field.
        for (i in 0...data.metadata.rigidBodyCount) {
            var rigidBody:Object = data.rigidBodies[i];
            var params:Dynamic = {};

            for (key in rigidBody) {
                params[key] = rigidBody[key];
            }

            rigidBodies.push(params);
        }

        // constraints from constraints field.
        for (i in 0...data.metadata.constraintCount) {
            var constraint:Object = data.constraints[i];
            var params:Dynamic = {};

            for (key in constraint) {
                params[key] = constraint[key];
            }

            constraints.push(params);
        }

        // build BufferGeometry.
        var geometry:BufferGeometry = new BufferGeometry();

        geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
        geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        geometry.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
        geometry.setAttribute('skinIndex', new Uint16BufferAttribute(skinIndices, 4));
        geometry.setAttribute('skinWeight', new Float32BufferAttribute(skinWeights, 4));
        geometry.setIndex(indices);

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