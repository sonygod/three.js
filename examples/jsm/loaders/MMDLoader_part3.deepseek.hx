class GeometryBuilder {

    public function build(data:Dynamic):BufferGeometry {

        var positions:Array<Float> = [];
        var uvs:Array<Float> = [];
        var normals:Array<Float> = [];

        var indices:Array<Int> = [];

        var groups:Array<Dynamic> = [];

        var bones:Array<Dynamic> = [];
        var skinIndices:Array<Float> = [];
        var skinWeights:Array<Float> = [];

        var morphTargets:Array<Dynamic> = [];
        var morphPositions:Array<Float32BufferAttribute> = [];

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

            value = value === undefined ? body.type : Math.max(body.type, value);

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
                rigidBodyType: boneTypeTable[i] !== undefined ? boneTypeTable[i] : -1
            };

            if (bone.parent !== -1) {
                bone.pos[0] -= data.bones[bone.parent].position[0];
                bone.pos[1] -= data.bones[bone.parent].position[1];
                bone.pos[2] -= data.bones[bone.parent].position[2];
            }

            bones.push(bone);

        }

        // iks, grants, rigidBodies, constraints, and morphTargets are omitted for brevity

        var geometry = new BufferGeometry();

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