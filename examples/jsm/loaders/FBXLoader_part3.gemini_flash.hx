import three.Matrix3;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.core.BufferGeometry;
import three.core.bufferAttributes.Float32BufferAttribute;
import three.core.bufferAttributes.Uint16BufferAttribute;
import three.geometries.ShapeUtils;
import three.math.Color;
import three.objects.Skeleton;
import three.extras.curves.NURBSCurve;

class GeometryParser {
	public var negativeMaterialIndices:Bool;

	public function new() {
		this.negativeMaterialIndices = false;
	}

	// Parse nodes in FBXTree.Objects.Geometry
	public function parse(deformers:Dynamic):Map<Int, BufferGeometry> {
		final geometryMap = new Map<Int, BufferGeometry>();

		if (Reflect.hasField(fbxTree.Objects, "Geometry")) {
			final geoNodes = Reflect.field(fbxTree.Objects, "Geometry");

			for (nodeId in Reflect.fields(geoNodes)) {
				final relationships = connections.get(Std.parseInt(nodeId));
				final geo = parseGeometry(relationships, Reflect.field(geoNodes, nodeId), deformers);
				geometryMap.set(Std.parseInt(nodeId), geo);
			}
		}

		// report warnings
		if (this.negativeMaterialIndices) {
			trace('THREE.FBXLoader: The FBX file contains invalid (negative) material indices. The asset might not render as expected.');
		}

		return geometryMap;
	}

	// Parse single node in FBXTree.Objects.Geometry
	function parseGeometry(relationships:Dynamic, geoNode:Dynamic, deformers:Dynamic):BufferGeometry {
		switch (geoNode.attrType) {
			case "Mesh":
				return parseMeshGeometry(relationships, geoNode, deformers);
			case "NurbsCurve":
				return parseNurbsGeometry(geoNode);
			default:
				return null;
		}
	}

	// Parse single node mesh geometry in FBXTree.Objects.Geometry
	function parseMeshGeometry(relationships:Dynamic, geoNode:Dynamic, deformers:Dynamic):BufferGeometry {
		final skeletons = deformers.skeletons;
		final morphTargets:Array<Dynamic> = [];

		final modelNodes = relationships.parents.map(function(parent) {
			return Reflect.field(fbxTree.Objects.Model, parent.ID);
		});

		// don't create geometry if it is not associated with any models
		if (modelNodes.length == 0)
			return null;

		final skeleton:Skeleton = relationships.children.reduce(function(skeleton:Skeleton, child) {
			if (Reflect.hasField(skeletons, child.ID))
				skeleton = Reflect.field(skeletons, child.ID);
			return skeleton;
		}, null);

		for (child in relationships.children) {
			if (Reflect.hasField(deformers.morphTargets, child.ID)) {
				morphTargets.push(Reflect.field(deformers.morphTargets, child.ID));
			}
		}

		// Assume one model and get the preRotation from that
		// if there is more than one model associated with the geometry this may cause problems
		final modelNode = modelNodes[0];

		final transformData:Dynamic = {};
		if (Reflect.hasField(modelNode, "RotationOrder"))
			transformData.eulerOrder = getEulerOrder(modelNode.RotationOrder.value);
		if (Reflect.hasField(modelNode, "InheritType"))
			transformData.inheritType = Std.parseInt(modelNode.InheritType.value);

		if (Reflect.hasField(modelNode, "GeometricTranslation"))
			transformData.translation = modelNode.GeometricTranslation.value;
		if (Reflect.hasField(modelNode, "GeometricRotation"))
			transformData.rotation = modelNode.GeometricRotation.value;
		if (Reflect.hasField(modelNode, "GeometricScaling"))
			transformData.scale = modelNode.GeometricScaling.value;

		final transform = generateTransform(transformData);

		return genGeometry(geoNode, skeleton, morphTargets, transform);
	}

	// Generate a BufferGeometry from a node in FBXTree.Objects.Geometry
	function genGeometry(geoNode:Dynamic, skeleton:Skeleton, morphTargets:Array<Dynamic>, preTransform:Matrix3):BufferGeometry {
		final geo = new BufferGeometry();
		if (geoNode.attrName != null)
			geo.name = geoNode.attrName;

		final geoInfo = parseGeoNode(geoNode, skeleton);
		final buffers = genBuffers(geoInfo);

		final positionAttribute = new Float32BufferAttribute(buffers.vertex, 3);
		positionAttribute.applyMatrix4(preTransform);
		geo.setAttribute('position', positionAttribute);

		if (buffers.colors.length > 0) {
			geo.setAttribute('color', new Float32BufferAttribute(buffers.colors, 3));
		}

		if (skeleton != null) {
			geo.setAttribute('skinIndex', new Uint16BufferAttribute(buffers.weightsIndices, 4));
			geo.setAttribute('skinWeight', new Float32BufferAttribute(buffers.vertexWeights, 4));

			// used later to bind the skeleton to the model
			Reflect.setField(geo, "FBX_Deformer", skeleton);
		}

		if (buffers.normal.length > 0) {
			final normalMatrix = new Matrix3().getNormalMatrix(preTransform);
			final normalAttribute = new Float32BufferAttribute(buffers.normal, 3);
			normalAttribute.applyNormalMatrix(normalMatrix);
			geo.setAttribute('normal', normalAttribute);
		}

		for (i in 0...buffers.uvs.length) {
			final uvBuffer = buffers.uvs[i];
			final name = (i == 0) ? 'uv' : 'uv$i';
			geo.setAttribute(name, new Float32BufferAttribute(uvBuffer, 2));
		}

		if (geoInfo.material != null && geoInfo.material.mappingType != "AllSame") {
			// Convert the material indices of each vertex into rendering groups on the geometry.
			var prevMaterialIndex = buffers.materialIndex[0];
			var startIndex = 0;

			for (i in 0...buffers.materialIndex.length) {
				final currentIndex = buffers.materialIndex[i];
				if (currentIndex != prevMaterialIndex) {
					geo.addGroup(startIndex, i - startIndex, prevMaterialIndex);
					prevMaterialIndex = currentIndex;
					startIndex = i;
				}
			}

			// the loop above doesn't add the last group, do that here.
			if (geo.groups.length > 0) {
				final lastGroup = geo.groups[geo.groups.length - 1];
				final lastIndex = lastGroup.start + lastGroup.count;

				if (lastIndex != buffers.materialIndex.length) {
					geo.addGroup(lastIndex, buffers.materialIndex.length - lastIndex, prevMaterialIndex);
				}
			}

			// case where there are multiple materials but the whole geometry is only
			// using one of them
			if (geo.groups.length == 0) {
				geo.addGroup(0, buffers.materialIndex.length, buffers.materialIndex[0]);
			}
		}
		addMorphTargets(geo, geoNode, morphTargets, preTransform);
		return geo;
	}

	function parseGeoNode(geoNode:Dynamic, skeleton:Skeleton) {
		final geoInfo:Dynamic = {};

		geoInfo.vertexPositions = (geoNode.Vertices != null) ? geoNode.Vertices.a : [];
		geoInfo.vertexIndices = (geoNode.PolygonVertexIndex != null) ? geoNode.PolygonVertexIndex.a : [];

		if (geoNode.LayerElementColor != null) {
			geoInfo.color = parseVertexColors(geoNode.LayerElementColor[0]);
		}

		if (geoNode.LayerElementMaterial != null) {
			geoInfo.material = parseMaterialIndices(geoNode.LayerElementMaterial[0]);
		}

		if (geoNode.LayerElementNormal != null) {
			geoInfo.normal = parseNormals(geoNode.LayerElementNormal[0]);
		}

		if (geoNode.LayerElementUV != null) {
			geoInfo.uv = [];
			var i = 0;

			while (geoNode.LayerElementUV[i] != null) {
				if (geoNode.LayerElementUV[i].UV != null) {
					geoInfo.uv.push(parseUVs(geoNode.LayerElementUV[i]));
				}
				i++;
			}
		}

		geoInfo.weightTable = {};

		if (skeleton != null) {
			geoInfo.skeleton = skeleton;

			for (i in 0...skeleton.bones.length) {
				final rawBone = skeleton.bones[i];
				// loop over the bone's vertex indices and weights
				for (j in 0...rawBone.indices.length) {
					final index = rawBone.indices[j];

					if (!Reflect.hasField(geoInfo.weightTable, index))
						Reflect.setField(geoInfo.weightTable, index, []);
					Reflect.field(geoInfo.weightTable, index).push({
						id: i,
						weight: rawBone.weights[j]
					});
				}
			}
		}
		return geoInfo;
	}

	function genBuffers(geoInfo:Dynamic) {
		final buffers:Dynamic = {
			vertex: [],
			normal: [],
			colors: [],
			uvs: [],
			materialIndex: [],
			vertexWeights: [],
			weightsIndices: []
		};

		var polygonIndex = 0;
		var faceLength = 0;
		var displayedWeightsWarning = false;

		// these will hold data for a single face
		var facePositionIndexes:Array<Float> = [];
		var faceNormals:Array<Float> = [];
		var faceColors:Array<Float> = [];
		var faceUVs:Array<Array<Float>> = [];
		var faceWeights:Array<Float> = [];
		var faceWeightIndices:Array<Int> = [];

		final scope = this;
		for (polygonVertexIndex in 0...geoInfo.vertexIndices.length) {
			final vertexIndex = geoInfo.vertexIndices[polygonVertexIndex];
			var materialIndex:Int = 0;
			var endOfFace = false;

			// Face index and vertex index arrays are combined in a single array
			// A cube with quad faces looks like this:
			// PolygonVertexIndex: *24 {
			//  a: 0, 1, 3, -3, 2, 3, 5, -5, 4, 5, 7, -7, 6, 7, 1, -1, 1, 7, 5, -4, 6, 0, 2, -5
			//  }
			// Negative numbers mark the end of a face - first face here is 0, 1, 3, -3
			// to find index of last vertex bit shift the index: ^ - 1
			if (vertexIndex < 0) {
				materialIndex = vertexIndex ^ -1; // equivalent to ( x * -1 ) - 1
				endOfFace = true;
			}

			var weightIndices:Array<Int> = [];
			var weights:Array<Float> = [];

			facePositionIndexes.push(vertexIndex * 3, vertexIndex * 3 + 1, vertexIndex * 3 + 2);

			if (geoInfo.color != null) {
				final data = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.color);
				faceColors.push(data[0], data[1], data[2]);
			}

			if (geoInfo.skeleton != null) {
				if (Reflect.hasField(geoInfo.weightTable, vertexIndex)) {
					for (wt in Reflect.field(geoInfo.weightTable, vertexIndex)) {
						weights.push(wt.weight);
						weightIndices.push(wt.id);
					}
				}
				if (weights.length > 4) {
					if (!displayedWeightsWarning) {
						trace('THREE.FBXLoader: Vertex has more than 4 skinning weights assigned to vertex. Deleting additional weights.');
						displayedWeightsWarning = true;
					}
					final wIndex:Array<Int> = [0, 0, 0, 0];
					final Weight:Array<Float> = [0, 0, 0, 0];
					for (weightIndex in 0...weights.length) {
						var currentWeight = weights[weightIndex];
						var currentIndex = weightIndices[weightIndex];
						for (comparedWeightIndex in 0...Weight.length) {
							if (currentWeight > Weight[comparedWeightIndex]) {
								Weight[comparedWeightIndex] = currentWeight;
								currentWeight = Weight[comparedWeightIndex];
								final tmp = wIndex[comparedWeightIndex];
								wIndex[comparedWeightIndex] = currentIndex;
								currentIndex = tmp;
							}
						}
					}
					weightIndices = wIndex;
					weights = Weight;
				}

				// if the weight array is shorter than 4 pad with 0s
				while (weights.length < 4) {
					weights.push(0);
					weightIndices.push(0);
				}
				for (i in 0...4) {
					faceWeights.push(weights[i]);
					faceWeightIndices.push(weightIndices[i]);
				}
			}
			if (geoInfo.normal != null) {
				final data = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.normal);
				faceNormals.push(data[0], data[1], data[2]);
			}

			if (geoInfo.material != null && geoInfo.material.mappingType != 'AllSame') {
				materialIndex = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.material)[0];
				if (materialIndex < 0) {
					scope.negativeMaterialIndices = true;
					materialIndex = 0; // fallback
				}
			}
			if (geoInfo.uv != null) {
				for (i in 0...geoInfo.uv.length) {
					final uv = geoInfo.uv[i];
					final data = getData(polygonVertexIndex, polygonIndex, vertexIndex, uv);
					if (faceUVs[i] == null) {
						faceUVs[i] = [];
					}
					faceUVs[i].push(data[0]);
					faceUVs[i].push(data[1]);
				}
			}
			faceLength++;
			if (endOfFace) {
				genFace(buffers, geoInfo, facePositionIndexes, materialIndex, faceNormals, faceColors, faceUVs, faceWeights, faceWeightIndices,
					faceLength);
				polygonIndex++;
				faceLength = 0;

				// reset arrays for the next face
				facePositionIndexes = [];
				faceNormals = [];
				faceColors = [];
				faceUVs = [];
				faceWeights = [];
				faceWeightIndices = [];
			}
		}
		return buffers;
	}

	function getData(polygonVertexIndex:Int, polygonIndex:Int, vertexIndex:Int, info:Dynamic):Array<Float> {
		var from = polygonVertexIndex * info.dataSize;
		var to = polygonVertexIndex * info.dataSize + info.dataSize;

		return info.buffer.slice(from, to);
	}

	// See https://www.khronos.org/opengl/wiki/Calculating_a_Surface_Normal
	function getNormalNewell(vertices:Array<Vector3>):Vector3 {
		final normal = new Vector3(0.0, 0.0, 0.0);
		for (i in 0...vertices.length) {
			final current = vertices[i];
			final next = vertices[(i + 1) % vertices.length];
			normal.x += (current.y - next.y) * (current.z + next.z);
			normal.y += (current.z - next.z) * (current.x + next.x);
			normal.z += (current.x - next.x) * (current.y + next.y);
		}
		normal.normalize();
		return normal;
	}

	function getNormalTangentAndBitangent(vertices:Array<Vector3>) {
		final normalVector = getNormalNewell(vertices);
		// Avoid up being equal or almost equal to normalVector
		final up = (Math.abs(normalVector.z) > 0.5) ? new Vector3(0.0, 1.0, 0.0) : new Vector3(0.0, 0.0, 1.0);
		final tangent = up.cross(normalVector).normalize();
		final bitangent = normalVector.clone().cross(tangent).normalize();
		return {
			normal: normalVector,
			tangent: tangent,
			bitangent: bitangent
		};
	}

	function flattenVertex(vertex:Vector3, normalTangent:Vector3, normalBitangent:Vector3):Vector2 {
		return new Vector2(vertex.dot(normalTangent), vertex.dot(normalBitangent));
	}

	// Generate data for a single face in a geometry. If the face is a quad then split it into 2 tris
	function genFace(buffers:Dynamic, geoInfo:Dynamic, facePositionIndexes:Array<Float>, materialIndex:Int, faceNormals:Array<Float>,
			faceColors:Array<Float>, faceUVs:Array<Array<Float>>, faceWeights:Array<Float>, faceWeightIndices:Array<Int>, faceLength:Int) {
		var triangles:Array<Array<Int>>;
		if (faceLength > 3) {
			// Triangulate n-gon using earcut
			final vertices:Array<Vector3> = [];
			for (i in 0...facePositionIndexes.length step 3) {
				vertices.push(new Vector3(geoInfo.vertexPositions[Std.int(facePositionIndexes[i])],
					geoInfo.vertexPositions[Std.int(facePositionIndexes[i + 1])], geoInfo.vertexPositions[Std.int(facePositionIndexes[i + 2])]));
			}
			final ntb = getNormalTangentAndBitangent(vertices);
			final tangent = ntb.tangent;
			final bitangent = ntb.bitangent;

			final triangulationInput:Array<Vector2> = [];
			for (vertex in vertices) {
				triangulationInput.push(flattenVertex(vertex, tangent, bitangent));
			}

			triangles = ShapeUtils.triangulateShape(triangulationInput, []);
		} else {
			// Regular triangle, skip earcut triangulation step
			triangles = [[0, 1, 2]];
		}

		for (triangle in triangles) {
			final i0 = triangle[0];
			final i1 = triangle[1];
			final i2 = triangle[2];
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i0 * 3]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i0 * 3 + 1]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i0 * 3 + 2]]);

			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i1 * 3]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i1 * 3 + 1]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i1 * 3 + 2]]);

			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i2 * 3]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i2 * 3 + 1]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i2 * 3 + 2]]);

			if (geoInfo.skeleton != null) {
				buffers.vertexWeights.push(faceWeights[i0 * 4]);
				buffers.vertexWeights.push(faceWeights[i0 * 4 + 1]);
				buffers.vertexWeights.push(faceWeights[i0 * 4 + 2]);
				buffers.vertexWeights.push(faceWeights[i0 * 4 + 3]);

				buffers.vertexWeights.push(faceWeights[i1 * 4]);
				buffers.vertexWeights.push(faceWeights[i1 * 4 + 1]);
				buffers.vertexWeights.push(faceWeights[i1 * 4 + 2]);
				buffers.vertexWeights.push(faceWeights[i1 * 4 + 3]);

				buffers.vertexWeights.push(faceWeights[i2 * 4]);
				buffers.vertexWeights.push(faceWeights[i2 * 4 + 1]);
				buffers.vertexWeights.push(faceWeights[i2 * 4 + 2]);
				buffers.vertexWeights.push(faceWeights[i2 * 4 + 3]);

				buffers.weightsIndices.push(faceWeightIndices[i0 * 4]);
				buffers.weightsIndices.push(faceWeightIndices[i0 * 4 + 1]);
				buffers.weightsIndices.push(faceWeightIndices[i0 * 4 + 2]);
				buffers.weightsIndices.push(faceWeightIndices[i0 * 4 + 3]);

				buffers.weightsIndices.push(faceWeightIndices[i1 * 4]);
				buffers.weightsIndices.push(faceWeightIndices[i1 * 4 + 1]);
				buffers.weightsIndices.push(faceWeightIndices[i1 * 4 + 2]);
				buffers.weightsIndices.push(faceWeightIndices[i1 * 4 + 3]);

				buffers.weightsIndices.push(faceWeightIndices[i2 * 4]);
				buffers.weightsIndices.push(faceWeightIndices[i2 * 4 + 1]);
				buffers.weightsIndices.push(faceWeightIndices[i2 * 4 + 2]);
				buffers.weightsIndices.push(faceWeightIndices[i2 * 4 + 3]);
			}

			if (geoInfo.color != null) {
				buffers.colors.push(faceColors[i0 * 3]);
				buffers.colors.push(faceColors[i0 * 3 + 1]);
				buffers.colors.push(faceColors[i0 * 3 + 2]);

				buffers.colors.push(faceColors[i1 * 3]);
				buffers.colors.push(faceColors[i1 * 3 + 1]);
				buffers.colors.push(faceColors[i1 * 3 + 2]);

				buffers.colors.push(faceColors[i2 * 3]);
				buffers.colors.push(faceColors[i2 * 3 + 1]);
				buffers.colors.push(faceColors[i2 * 3 + 2]);
			}

			if (geoInfo.material != null && geoInfo.material.mappingType != 'AllSame') {
				buffers.materialIndex.push(materialIndex);
				buffers.materialIndex.push(materialIndex);
				buffers.materialIndex.push(materialIndex);
			}
			if (geoInfo.normal != null) {
				buffers.normal.push(faceNormals[i0 * 3]);
				buffers.normal.push(faceNormals[i0 * 3 + 1]);
				buffers.normal.push(faceNormals[i0 * 3 + 2]);

				buffers.normal.push(faceNormals[i1 * 3]);
				buffers.normal.push(faceNormals[i1 * 3 + 1]);
				buffers.normal.push(faceNormals[i1 * 3 + 2]);

				buffers.normal.push(faceNormals[i2 * 3]);
				buffers.normal.push(faceNormals[i2 * 3 + 1]);
				buffers.normal.push(faceNormals[i2 * 3 + 2]);
			}

			if (geoInfo.uv != null) {
				for (j in 0...geoInfo.uv.length) {
					final uv = geoInfo.uv[j];
					if (buffers.uvs[j] == null) {
						buffers.uvs[j] = [];
					}
					buffers.uvs[j].push(faceUVs[j][i0 * 2]);
					buffers.uvs[j].push(faceUVs[j][i0 * 2 + 1]);

					buffers.uvs[j].push(faceUVs[j][i1 * 2]);
					buffers.uvs[j].push(faceUVs[j][i1 * 2 + 1]);

					buffers.uvs[j].push(faceUVs[j][i2 * 2]);
					buffers.uvs[j].push(faceUVs[j][i2 * 2 + 1]);
				}
			}
		}
	}

	function addMorphTargets(parentGeo:BufferGeometry, parentGeoNode:Dynamic, morphTargets:Array<Dynamic>, preTransform:Matrix3) {
		if (morphTargets.length == 0)
			return;
		parentGeo.morphTargetsRelative = true;
		parentGeo.morphAttributes.position = [];
		// parentGeo.morphAttributes.normal = []; // not implemented
		final scope = this;
		for (morphTarget in morphTargets) {
			for (rawTarget in morphTarget.rawTargets) {
				final morphGeoNode = Reflect.field(fbxTree.Objects.Geometry, rawTarget.geoID);
				if (morphGeoNode != null) {
					genMorphGeometry(parentGeo, parentGeoNode, morphGeoNode, preTransform, rawTarget.name);
				}
			}
		}
	}

	// a morph geometry node is similar to a standard  node, and the node is also contained
	// in FBXTree.Objects.Geometry, however it can only have attributes for position, normal
	// and a special attribute Index defining which vertices of the original geometry are affected
	// Normal and position attributes only have data for the vertices that are affected by the morph
	function genMorphGeometry(parentGeo:BufferGeometry, parentGeoNode:Dynamic, morphGeoNode:Dynamic, preTransform:Matrix3, name:String) {
		final vertexIndices = (parentGeoNode.PolygonVertexIndex != null) ? parentGeoNode.PolygonVertexIndex.a : [];
		final morphPositionsSparse = (morphGeoNode.Vertices != null) ? morphGeoNode.Vertices.a : [];
		final indices = (morphGeoNode.Indexes != null) ? morphGeoNode.Indexes.a : [];
		final length = parentGeo.attributes.position.count * 3;
		final morphPositions = new Float32Array(length);
		for (i in 0...indices.length) {
			final morphIndex = indices[i] * 3;
			morphPositions[morphIndex] = morphPositionsSparse[i * 3];
			morphPositions[morphIndex + 1] = morphPositionsSparse[i * 3 + 1];
			morphPositions[morphIndex + 2] = morphPositionsSparse[i * 3 + 2];
		}
		// TODO: add morph normal support
		final morphGeoInfo = {
			vertexIndices: vertexIndices,
			vertexPositions: morphPositions
		};
		final morphBuffers = genBuffers(morphGeoInfo);
		final positionAttribute = new Float32BufferAttribute(morphBuffers.vertex, 3);
		positionAttribute.name = name != null ? name : morphGeoNode.attrName;
		positionAttribute.applyMatrix4(preTransform);
		parentGeo.morphAttributes.position.push(positionAttribute);
	}

	// Parse normal from FBXTree.Objects.Geometry.LayerElementNormal if it exists
	function parseNormals(NormalNode:Dynamic) {
		final mappingType = NormalNode.MappingInformationType;
		final referenceType = NormalNode.ReferenceInformationType;
		final buffer = NormalNode.Normals.a;
		var indexBuffer:Array<Dynamic> = [];
		if (referenceType == 'IndexToDirect') {
			if (Reflect.hasField(NormalNode, "NormalIndex")) {
				indexBuffer = NormalNode.NormalIndex.a;
			} else if (Reflect.hasField(NormalNode, "NormalsIndex")) {
				indexBuffer = NormalNode.NormalsIndex.a;
			}
		}

		return {
			dataSize: 3,
			buffer: buffer,
			indices: indexBuffer,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Parse UVs from FBXTree.Objects.Geometry.LayerElementUV if it exists
	function parseUVs(UVNode:Dynamic) {
		final mappingType = UVNode.MappingInformationType;
		final referenceType = UVNode.ReferenceInformationType;
		final buffer = UVNode.UV.a;
		var indexBuffer:Array<Dynamic> = [];
		if (referenceType == 'IndexToDirect') {
			indexBuffer = UVNode.UVIndex.a;
		}
		return {
			dataSize: 2,
			buffer: buffer,
			indices: indexBuffer,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Parse Vertex Colors from FBXTree.Objects.Geometry.LayerElementColor if it exists
	function parseVertexColors(ColorNode:Dynamic) {
		final mappingType = ColorNode.MappingInformationType;
		final referenceType = ColorNode.ReferenceInformationType;
		final buffer = ColorNode.Colors.a;
		var indexBuffer:Array<Dynamic> = [];
		if (referenceType == 'IndexToDirect') {
			indexBuffer = ColorNode.ColorIndex.a;
		}

		var c = new Color();

		for (i in 0...buffer.length step 4) {
			c.fromArray(buffer, i).convertSRGBToLinear().toArray(buffer, i);
		}

		return {
			dataSize: 4,
			buffer: buffer,
			indices: indexBuffer,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Parse mapping and material data in FBXTree.Objects.Geometry.LayerElementMaterial if it exists
	function parseMaterialIndices(MaterialNode:Dynamic) {
		final mappingType = MaterialNode.MappingInformationType;
		final referenceType = MaterialNode.ReferenceInformationType;
		if (mappingType == 'NoMappingInformation') {
			return {
				dataSize: 1,
				buffer: [0],
				indices: [0],
				mappingType: 'AllSame',
				referenceType: referenceType
			};
		}
		final materialIndexBuffer = MaterialNode.Materials.a;
		// Since materials are stored as indices, there's a bit of a mismatch between FBX and what
		// we expect.So we create an intermediate buffer that points to the index in the buffer,
		// for conforming with the other functions we've written for other data.
		final materialIndices:Array<Int> = [];
		for (i in 0...materialIndexBuffer.length) {
			materialIndices.push(i);
		}

		return {
			dataSize: 1,
			buffer: materialIndexBuffer,
			indices: materialIndices,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Generate a NurbGeometry from a node in FBXTree.Objects.Geometry
	function parseNurbsGeometry(geoNode:Dynamic):BufferGeometry {
		final order = Std.parseInt(geoNode.Order);

		if (Math.isNaN(order)) {
			trace('THREE.FBXLoader: Invalid Order %s given for geometry ID: %s, geoNode.Order, geoNode.id');
			return new BufferGeometry();
		}

		final degree = order - 1;
		final knots = geoNode.KnotVector.a;
		final controlPoints:Array<Vector4> = [];
		final pointsValues = geoNode.Points.a;

		for (i in 0...pointsValues.length step 4) {
			controlPoints.push(new Vector4().fromArray(pointsValues, i));
		}

		var startKnot:Int = 0;
		var endKnot:Int = 0;

		if (geoNode.Form == 'Closed') {
			controlPoints.push(controlPoints[0]);
		} else if (geoNode.Form == 'Periodic') {
			startKnot = degree;
			endKnot = knots.length - 1 - startKnot;
			for (i in 0...degree) {
				controlPoints.push(controlPoints[i]);
			}
		}

		final curve = new NURBSCurve(degree, knots, controlPoints, startKnot, endKnot);
		final points = curve.getPoints(controlPoints.length * 12);
		return new BufferGeometry().setFromPoints(points);
	}
}