class GeometryBuilder {

	public function build(data:Dynamic):Geometry {

		// for geometry
		var positions = [];
		var uvs = [];
		var normals = [];

		var indices = [];

		var groups = [];

		var bones = [];
		var skinIndices = [];
		var skinWeights = [];

		var morphTargets = [];
		var morphPositions = [];

		var iks = [];
		var grants = [];

		var rigidBodies = [];
		var constraints = [];

		// for work
		var offset = 0;
		var boneTypeTable:Dict<Int, Int> = new Dict();

		// positions, normals, uvs, skinIndices, skinWeights

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

		// indices

		for (i in 0...data.metadata.faceCount) {

			var face = data.faces[i];

			for (j in 0...face.indices.length) {

				indices.push(face.indices[j]);

			}

		}

		// groups

		for (i in 0...data.metadata.materialCount) {

			var material = data.materials[i];

			groups.push({
				offset: offset * 3,
				count: material.faceCount * 3
			});

			offset += material.faceCount;

		}

		// bones

		for (i in 0...data.metadata.rigidBodyCount) {

			var body = data.rigidBodies[i];
			var value = boneTypeTable.get(body.boneIndex);

			// keeps greater number if already value is set without any special reasons
			value = value === null ? body.type : Math.max(body.type, value);

			boneTypeTable.set(body.boneIndex, value);

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
				rigidBodyType: boneTypeTable.get(i) !== null ? boneTypeTable.get(i) : -1
			};

			if (bone.parent !== -1) {

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

				if (ik === undefined) continue;

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

					if (ik.links[j].angleLimitation == 1) {

						// Revert if rotationMin/Max doesn't work well
						// link.limitation = new Vector3(1.0, 0.0, 0.0);

						var rotationMin = ik.links[j].lowerLimitationAngle;
						var rotationMax = ik.links[j].upperLimitationAngle;

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
				bones[i].ik = param;

			}

		}

		// grants

		if (data.metadata.format == 'pmx') {

			// bone index -> grant entry map
			var grantEntryMap:Dict<Int, GrantEntry> = new Dict();

			for (i in 0...data.metadata.boneCount) {

				var boneData = data.bones[i];
				var grant = boneData.grant;

				if (grant === undefined) continue;

				var param = {
					index: i,
					parentIndex: grant.parentIndex,
					ratio: grant.ratio,
					isLocal: grant.isLocal,
					affectRotation: grant.affectRotation,
					affectPosition: grant.affectPosition,
					transformationClass: boneData.transformationClass
				};

				grantEntryMap.set(i, {parent: null, children: [], param: param, visited: false});

			}

			var rootEntry = {parent: null, children: [], param: null, visited: false};

			// Build a tree representing grant hierarchy

			for (grantEntry in grantEntryMap.values()) {

				var parentGrantEntry = grantEntryMap[grantEntry.parentIndex]