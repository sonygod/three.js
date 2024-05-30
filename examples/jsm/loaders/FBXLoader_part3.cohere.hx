class GeometryParser {
	public var negativeMaterialIndices:Bool;

	public function new() {
		negativeMaterialIndices = false;
	}

	public function parse(deformers:Deformers):Map<Int, Geometry> {
		var geometryMap = new Map<Int, Geometry>();

		if (fbxTree.Objects.exists("Geometry")) {
			var geoNodes = fbxTree.Objects.Geometry;
			for (key in geoNodes) {
				var nodeID = Std.parseInt(key);
				var relationships = connections.get(nodeID);
				var geo = parseGeometry(relationships, geoNodes[key], deformers);
				geometryMap.set(nodeID, geo);
			}
		}

		// report warnings
		if (negativeMaterialIndices) {
			trace("THREE.FBXLoader: The FBX file contains invalid (negative) material indices. The asset might not render as expected.");
		}

		return geometryMap;
	}

	public function parseGeometry(relationships:Map<Int, Relationship>, geoNode:Dynamic, deformers:Deformers):Geometry {
		switch (geoNode.attrType) {
			case "Mesh":
				return parseMeshGeometry(relationships, geoNode, deformers);
			case "NurbsCurve":
				return parseNurbsGeometry(geoNode);
		}
	}

	public function parseMeshGeometry(relationships:Map<Int, Relationship>, geoNode:Dynamic, deformers:Deformers):Geometry {
		var skeletons = deformers.skeletons;
		var morphTargets = [];

		var modelNodes = relationships.parents.map(function(parent) {
			return fbxTree.Objects.Model[parent.ID];
		});

		// don't create geometry if it is not associated with any models
		if (modelNodes.length == 0) return null;

		var skeleton = relationships.children.fold(null, function(skeleton, child) {
			if (skeletons.exists(child.ID)) skeleton = skeletons[child.ID];
			return skeleton;
		});

		relationships.children.forEach(function(child) {
			if (deformers.morphTargets.exists(child.ID)) {
				morphTargets.push(deformers.morphTargets[child.ID]);
			}
		});

		// Assume one model and get the preRotation from that
		// if there is more than one model associated with the geometry this may cause problems
		var modelNode = modelNodes[0];

		var transformData = { eulerOrder: null, inheritType: null, translation: null, rotation: null, scale: null };

		if (modelNode.exists("RotationOrder")) transformData.eulerOrder = getEulerOrder(modelNode.RotationOrder.value);
		if (modelNode.exists("InheritType")) transformData.inheritType = Std.parseInt(modelNode.InheritType.value);

		if (modelNode.exists("GeometricTranslation")) transformData.translation = modelNode.GeometricTranslation.value;
		if (modelNode.exists("GeometricRotation")) transformData.rotation = modelNode.GeometricRotation.value;
		if (modelNode.exists("GeometricScaling")) transformData.scale = modelNode.GeometricScaling.value;

		var transform = generateTransform(transformData);

		return genGeometry(geoNode, skeleton, morphTargets, transform);
	}

	public function genGeometry(geoNode:Dynamic, skeleton:Skeleton, morphTargets:Array<MorphTarget>, preTransform:Matrix):Geometry {
		var geo = new Geometry();
		if (geoNode.exists("attrName")) geo.name = geoNode.attrName;

		var geoInfo = parseGeoNode(geoNode, skeleton);
		var buffers = genBuffers(geoInfo);

		var positionAttribute = new Float32BufferAttribute(buffers.vertex, 3);
		positionAttribute.applyMatrix4(preTransform);

		geo.setAttribute("position", positionAttribute);

		if (buffers.colors.length > 0) {
			geo.setAttribute("color", new Float32BufferAttribute(buffers.colors, 3));
		}

		if (skeleton != null) {
			geo.setAttribute("skinIndex", new Uint16BufferAttribute(buffers.weightsIndices, 4));
			geo.setAttribute("skinWeight", new Float32BufferAttribute(buffers.vertexWeights, 4));
			geo.FBX_Deformer = skeleton;
		}

		if (buffers.normal.length > 0) {
			var normalMatrix = new Matrix3().getNormalMatrix(preTransform);
			var normalAttribute = new Float32BufferAttribute(buffers.normal, 3);
			normalAttribute.applyNormalMatrix(normalMatrix);

			geo.setAttribute("normal", normalAttribute);
		}

		var i = 0;
		while (i < buffers.uvs.length) {
			var name = i == 0 ? "uv" : "uv" + i;
			geo.setAttribute(name, new Float32BufferAttribute(buffers.uvs[i], 2));
			i++;
		}

		if (geoInfo.material != null && geoInfo.material.mappingType != "AllSame") {
			// Convert the material indices of each vertex into rendering groups on the geometry.
			var prevMaterialIndex = buffers.materialIndex[0];
			var startIndex = 0;

			buffers.materialIndex.forEach(function(currentIndex, i) {
				if (currentIndex != prevMaterialIndex) {
					geo.addGroup(startIndex, i - startIndex, prevMaterialIndex);
					prevMaterialIndex = currentIndex;
					startIndex = i;
				}
			});

			// the loop above doesn't add the last group, do that here.
			if (geo.groups.length > 0) {
				var lastGroup = geo.groups[geo.groups.length - 1];
				var lastIndex = lastGroup.start + lastGroup.count;

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

	public function parseGeoNode(geoNode:Dynamic, skeleton:Skeleton):GeometryInfo {
		var geoInfo = { vertexPositions: [], vertexIndices: [], color: null, material: null, normal: null, uv: [], skeleton: null, weightTable: {} };

		if (geoNode.exists("Vertices")) geoInfo.vertexPositions = geoNode.Vertices.a;
		if (geoNode.exists("PolygonVertexIndex")) geoInfo.vertexIndices = geoNode.PolygonVertexIndex.a;

		if (geoNode.exists("LayerElementColor")) {
			geoInfo.color = parseVertexColors(geoNode.LayerElementColor[0]);
		}

		if (geoNode.exists("LayerElementMaterial")) {
			geoInfo.material = parseMaterialIndices(geoNode.LayerElementMaterial[0]);
		}

		if (geoNode.exists("LayerElementNormal")) {
			geoInfo.normal = parseNormals(geoNode.LayerElementNormal[0]);
		}

		if (geoNode.exists("LayerElementUV")) {
			geoInfo.uv = [];
			var i = 0;
			while (geoNode.LayerElementUV.exists(i)) {
				if (geoNode.LayerElementUV[i].exists("UV")) {
					geoInfo.uv.push(parseUVs(geoNode.LayerElementUV[i]));
				}
				i++;
			}
		}

		if (skeleton != null) {
			geoInfo.skeleton = skeleton;
			skeleton.rawBones.forEach(function(rawBone, i) {
				rawBone.indices.forEach(function(index, j) {
					if (!geoInfo.weightTable.exists(index)) geoInfo.weightTable[index] = [];
					geoInfo.weightTable[index].push({ id: i, weight: rawBone.weights[j] });
				});
			});
		}

		return geoInfo;
	}

	public function genBuffers(geoInfo:GeometryInfo):GeometryBuffers {
		var buffers = {
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
		var facePositionIndexes = [];
		var faceNormals = [];
		var faceColors = [];
		var faceUVs = [];
		var faceWeights = [];
		var faceWeightIndices = [];

		geoInfo.vertexIndices.forEach(function(vertexIndex, polygonVertexIndex) {
			var materialIndex:Int;
			var endOfFace = false;

			// Face index and vertex index arrays are combined in a single array
			// A cube with quad faces looks like this:
			// PolygonVertexIndex: *24 {
			//  a: 0, 1, 3, -3, 2, 3, 5, -5, 4, 5, 7, -7, 6, 7, 1, -1, 1, 7, 5, -4, 6, 0, 2, -5
			//  }
			// Negative numbers mark the end of a face - first face here is 0, 1, 3, -3
			// to find index of last vertex bit shift the index: ^ - 1
			if (vertexIndex < 0) {
				vertexIndex = vertexIndex ^ -1; // equivalent to ( x * -1 ) - 1
				endOfFace = true;
			}

			var weightIndices = [];
			var weights = [];

			facePositionIndexes.push(vertexIndex * 3, vertexIndex * 3 + 1, vertexIndex * 3 + 2);

			if (geoInfo.color != null) {
				var data = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.color);
				faceColors.push(data[0], data[1], data[2]);
			}

			if (geoInfo.skeleton != null) {
				if (geoInfo.weightTable.exists(vertexIndex)) {
					geoInfo.weightTable[vertexIndex].forEach(function(wt) {
						weights.push(wt.weight);
						weightIndices.push(wt.id);
					});
				}

				if (weights.length > 4) {
					if (!displayedWeightsWarning) {
						trace("THREE.FBXLoader: Vertex has more than 4 skinning weights assigned to vertex. Deleting additional weights.");
						displayedWeightsWarning = true;
					}

					var wIndex = [0, 0, 0, 0];
					var Weight = [0, 0, 0, 0];

					weights.forEach(function(weight, weightIndex) {
						var currentWeight = weight;
						var currentIndex = weightIndices[weightIndex];

						Weight.forEach(function(comparedWeight, comparedWeightIndex, comparedWeightArray) {
							if (currentWeight > comparedWeight) {
								comparedWeightArray[comparedWeightIndex] = currentWeight;
								currentWeight = comparedWeight;

								var tmp = wIndex[comparedWeightIndex];
								wIndex[comparedWeightIndex] = currentIndex;
								currentIndex = tmp;
							}
						});
					});

					weightIndices = wIndex;
					weights = Weight;
				}

				// if the weight array is shorter than 4 pad with 0s
				while (weights.length < 4) {
					weights.push(0);
					weightIndices.push(0);
				}

				faceWeights.push(weights[0], weights[1], weights[2], weights[3]);
				faceWeightIndices.push(weightIndices[0], weightIndices[1], weightIndices[2], weightIndices[3]);
			}

			if (geoInfo.normal != null) {
				var data = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.normal);
				faceNormals.push(data[0], data[1], data[2]);
			}

			if (geoInfo.material != null && geoInfo.material.mappingType != "AllSame") {
				materialIndex = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.material)[0];

				if (materialIndex < 0) {
					negativeMaterialIndices = true;
					materialIndex = 0; // fallback
				}
			}

			if (geoInfo.uv != null) {
				geoInfo.uv.forEach(function(uv, i) {
					var data = getData(polygonVertexIndex, polygonIndex, vertexIndex, uv);
					if (faceUVs[i] == null) {
						faceUVs[i] = [];
					}
					faceUVs[i].push(data[0], data[1]);
				});
			}

			faceLength++;

			if (endOfFace) {
				genFace(buffers, geoInfo, facePositionIndexes, materialIndex, faceNormals, faceColors, faceUVs, faceWeights, faceWeightIndices, faceLength);

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
		});

		return buffers;
	}

	// See https://www.khronos.org/opengl/wiki/Calculating_a_Surface_Normal
	public function getNormalNewell(vertices:Array<Float>):Float32Array {
		var normal = new Float32Array([0.0, 0.0, 0.0]);

		for (i in vertices) {
			var current = vertices[i];
			var next = vertices[(i + 1) % vertices.length];

			normal[0] += (current[1] - next[1]) * (current[2] + next[2]);
			normal[1] += (current[2] - next[2]) * (current[0] + next[0]);
			normal[2] += (current[0] - next[0]) * (current[1] + next[1]);
		}

		var length = Math.sqrt(normal[0] * normal[0] + normal[1] * normal[1] + normal[2] * normal[2]);
		if (length != 0) {
			normal[0] /= length;
			normal[1] /= length;
			normal[2] /= length;
		}

		return normal;
	}

	public function getNormalTangentAndBitangent(vertices:Array<Float>):{ normal:Float32Array, tangent:Float32Array, bitangent:Float32Array } {
		var normalVector = getNormalNewell(vertices);
		// Avoid up being equal or almost equal to normalVector
		var up = Math.abs(normalVector[2]) > 0.5 ? new Float32Array([0.0, 1.0, 0.0]) : new Float32Array([0.0, 0.0, 1.0]);
		var tangent = up.cross(normalVector);
		var bitangent = normalVector.cross(tangent);

		return { normal: normalVector, tangent: tangent, bitangent: bitangent };
	}

	public function flattenVertex(vertex:Float32Array, normalTangent:Float32Array, normalBitangent:Float32Array):Float32Array {
		return new Float32Array([
			vertex[0] * normalTangent[0] + vertex[1] * normalTangent[1] + vertex[2] * normalTangent[2],
			vertex[0] * normalBitangent[0] + vertex[1] * normalBitangent[1] + vertex[2] * normalBitangent[2]
		]);
	}

	// Generate data for a single face in a geometry. If the face is a quad then split it into 2 tris
	public function genFace(buffers:GeometryBuffers, geoInfo:GeometryInfo, facePositionIndexes:Array<Int>, materialIndex:Int, faceNormals:Array<Float>, faceColors:Array<Float>, faceUVs:Array<Float>, faceWeights:Array<Float>, faceWeightIndices:Array<Int>, faceLength:Int) {
		var triangles;

		if (faceLength > 3) {
			// Triangulate n-gon using earcut

			var vertices = [];

			for (i in facePositionIndexes) {
				var index = i * 3;
				vertices.push(new Float32Array([
					geoInfo.vertexPositions[facePositionIndexes[index]],
					geoInfo.vertexPositions[facePositionIndexes[index + 1
					,
					geoInfo.vertexPositions[facePositionIndexes[index + 2]]
				]));
			}

			var { tangent, bitangent } = getNormalTangentAndBitangent(vertices);
			var triangulationInput = [];

			for (vertex in vertices) {
				triangulationInput.push(flattenVertex(vertex, tangent, bitangent));
			}

			triangles = ShapeUtils.triangulateShape(triangulationInput, []);
		} else {
			// Regular triangle, skip earcut triangulation step
			triangles = [[0, 1, 2]];
		}

		for (triangle in triangles) {
			var [i0, i1, i2] = triangle;

			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i0 * 3]], geoInfo.vertexPositions[facePositionIndexes[i0 * 3 + 1]], geoInfo.vertexPositions[facePositionIndexes[i0 * 3 + 2]], geoInfo.vertexPositions[facePositionIndexes[i1 * 3]], geoInfo.vertexPositions[facePositionIndexes[i1 * 3 + 1]], geoInfo.vertexPositions[facePositionIndexes[i1 * 3 + 2]], geoInfo.vertexPositions[facePositionIndexes[i2 * 3]], geoInfo.vertexPositions[facePositionIndexes[i2 * 3 + 1]], geoInfo.vertexPositions[facePositionIndexes[i2 * 3 + 2]]);

			if (geoInfo.skeleton != null) {
				buffers.vertexWeights.push(faceWeights[i0 * 4], faceWeights[i0 * 4 + 1], faceWeights[i0 * 4 + 2], faceWeights[i0 * 4 + 3], faceWeights[i1 * 4], faceWeights[i1 * 4 + 1], faceWeights[i1 * 4 + 2], faceWeights[i1 * 4 + 3], faceWeights[i2 * 4], faceWeights[i2 * 4 + 1], faceWeights[i2 * 4 + 2], faceWeights[i2 * 4 + 3]);

				buffers.weightsIndices.push(faceWeightIndices[i0 * 4], faceWeightIndices[i0 * 4 + 1], faceWeightIndices[i0 * 4 + 2], faceWeightIndices[i0 * 4 + 3], faceWeightIndices[i1 * 4], faceWeightIndices[i1 * 4 + 1], faceWeightIndices[i1 * 4 + 2], faceWeightIndices[i1 * 4 + 3], faceWeightIndices[i2 * 4], faceWeightIndices[i2 * 4 + 1], faceWeightIndices[i2 * 4 + 2], faceWeightIndices[i2 * 4 + 3]);
			}

			if (geoInfo.color != null) {
				buffers.colors.push(faceColors[i0 * 3], faceColors[i0 * 3 + 1], faceColors[i0 * 3 + 2], faceColors[i1 * 3], faceColors[i1 * 3 + 1], faceColors[i1 * 3 + 2], faceColors[i2 * 3], faceColors[i2 * 3 + 1], faceColors[i2 * 3 + 2]);
			}

			if (geoInfo.material != null && geoInfo.material.mappingType != "AllSame") {
				buffers.materialIndex.push(materialIndex, materialIndex, materialIndex);
			}

			if (geoInfo.normal != null) {
				buffers.normal.push(faceNormals[i0 * 3], faceNormals[i0 * 3 + 1], faceNormals[i0 * 3 + 2], faceNormals[i1 * 3], faceNormals[i1 * 3 + 1], faceNormals[i1 * 3 + 2], faceNormals[i2 * 3], faceNormals[i2 * 3 + 1], faceNormals[i2 * 3 + 2]);
			}

			if (geoInfo.uv != null) {
				for (uv in geoInfo.uv) {
					if (buffers.uvs[uv] == null) buffers.uvs[uv] = [];

					buffers.uvs[uv].push(faceUVs[uv][i0 * 2], faceUVs[uv][i0 * 2 + 1], faceUVs[uv][i1 * 2], faceUVs[uv][i1 * 2 + 1], faceUVs[uv][i2 * 2], faceUVs[uv][i2 * 2 + 1]);
				}
			}
		}
	}

	public function addMorphTargets(parentGeo:Geometry, parentGeoNode:Dynamic, morphTargets:Array<MorphTarget>, preTransform:Matrix) {
		if (morphTargets.length == 0) return;

		parentGeo.morphTargetsRelative = true;

		parentGeo.morphAttributes.position = [];
		// parentGeo.morphAttributes.normal = []; // not implemented

		morphTargets.forEach(function(morphTarget) {
			morphTarget.rawTargets.forEach(function(rawTarget) {
				var morphGeoNode = fbxTree.Objects.Geometry[rawTarget.geoID];

				if (morphGeoNode != null) {
					genMorphGeometry(parentGeo, parentGeoNode, morphGeoNode, preTransform, rawTarget.name);
				}
			});
		});
	}

	// a morph geometry node is similar to a standard geometry node, and the node is also contained
	// in FBXTree.Objects.Geometry, however it can only have attributes for position, normal
	// and a special attribute Index defining which vertices of the original geometry are affected
	// Normal and position attributes only have data for the vertices that are affected by the morph
	public function genMorphGeometry(parentGeo:Geometry, parentGeoNode:Dynamic, morphGeoNode:Dynamic, preTransform:Matrix, name:String) {
		var vertexIndices = parentGeoNode.exists("PolygonVertexIndex") ? parentGeoNode.PolygonVertexIndex.a : [];

		var morphPositionsSparse = morphGeoNode.exists("Vertices") ? morphGeoNode.Vertices.a : [];
		var indices = morphGeoNode.exists("Indexes") ? morphGeoNode.Indexes.a : [];

		var length = parentGeo.attributes.position.count * 3;
		var morphPositions = new Float32Array(length);

		for (i in indices) {
			var morphIndex = indices[i] * 3;

			morphPositions[morphIndex] = morphPositionsSparse[i * 3];
			morphPositions[morphIndex + 1] = morphPositionsSparse[i * 3 + 1];
			morphPositions[morphIndex + 2] = morphPositionsSparse[i * 3 + 2];
		}

		// TODO: add morph normal support
		var morphGeoInfo = { vertexIndices: vertexIndices, vertexPositions: morphPositions };

		var morphBuffers = genBuffers(morphGeoInfo);

		var positionAttribute = new Float32BufferAttribute(morphBuffers.vertex, 3);
		positionAttribute.name = name != null ? name : morphGeoNode.attrName;

		positionAttribute.applyMatrix4(preTransform);

		parentGeo.morphAttributes.position.push(positionAttribute);
	}

	// Parse normal from FBXTree.Objects.Geometry.LayerElementNormal if it exists
	public function parseNormals(NormalNode:Dynamic):GeometryData {
		var mappingType = NormalNode.MappingInformationType;
		var referenceType = NormalNode.ReferenceInformationType;
		var buffer = NormalNode.Normals.a;
		var indexBuffer = [];
		if (referenceType == "IndexToDirect") {
			if (NormalNode.exists("NormalIndex")) {
				indexBuffer = NormalNode.NormalIndex.a;
			} else if (NormalNode.exists("NormalsIndex")) {
				indexBuffer = NormalNode.NormalsIndex.a;
			}
		}

		return { dataSize: 3, buffer: buffer, indices: indexBuffer, mappingType: mappingType, referenceType: referenceType };
	}

	// Parse UVs from FBXTree.Objects.Geometry.LayerElementUV if it exists
	public function parseUVs(UVNode:Dynamic):GeometryData {
		var mappingType = UVNode.MappingInformationType;
		var referenceType = UVNode.ReferenceInformationType;
		var buffer = UVNode.UV.a;
		var indexBuffer = [];
		if (referenceType == "IndexToDirect") {
			indexBuffer = UVNode.UVIndex.a;
		}

		return { dataSize: 2, buffer: buffer, indices: indexBuffer, mappingType: mappingType, referenceType: referenceType };
	}

	// Parse Vertex Colors from FBXTree.Objects.Geometry.LayerElementColor if it exists
	public function parseVertexColors(ColorNode:Dynamic):GeometryData {
		var mappingType = ColorNode.MappingInformationType;
		var referenceType = ColorNode.ReferenceInformationType;
		var buffer = ColorNode.Colors.a;
		var indexBuffer = [];
		if (referenceType == "IndexToDirect") {
			indexBuffer = ColorNode.ColorIndex.a;
		}

		for (i in buffer) {
			var c = new Color();
			c.fromArray(buffer, i).convertSRGBToLinear().toArray(buffer, i);
		}

		return { dataSize: 4, buffer: buffer, indices: indexBuffer, mappingType: mappingType, referenceType: referenceType };
	}

	// Parse mapping and material data in FBXTree.Objects.Geometry.LayerElementMaterial if it exists
	public function parseMaterialIndices(MaterialNode:Dynamic):GeometryData {
		var mappingType = MaterialNode.MappingInformationType;
		var referenceType = MaterialNode.ReferenceInformationType;

		if (mappingType == "NoMappingInformation") {
			return { dataSize: 1, buffer: [0], indices: [0], mappingType: "AllSame", referenceType: referenceType };
		}

		var materialIndexBuffer = MaterialNode.Materials.a;

		// Since materials are stored as indices, there's a bit of a mismatch between FBX and what
		// we expect.So we create an intermediate buffer that points to the index in the buffer,
		// for conforming with the other functions we've written for other data.
		var materialIndices = [];

		for (i in materialIndexBuffer) {
			materialIndices.push(i);
		}

		return { dataSize: 1, buffer: materialIndexBuffer, indices: materialIndices, mappingType: mappingType, referenceType: referenceType };
	}

	// Generate a NurbGeometry from a node in FBXTree.Objects.Geometry
	public function parseNurbsGeometry(geoNode:Dynamic):Geometry {
		var order = Std.parseInt(geoNode.Order);

		if (order == null) {
			throw "THREE.FBXLoader: Invalid Order ${geoNode.Order} given for geometry ID: ${geoNode.id}";
		}

		var degree = order - 1;

		var knots = geoNode.KnotVector.a;
		var controlPoints = [];
		var pointsValues = geoNode.Points.a;

		for (i in pointsValues) {
			var index = i * 4;
			controlPoints.push(new Float32Array(pointsValues.slice(index, index + 4)));
		}

		var startKnot:Int, endKnot:Int;

		if (geoNode.Form == "Closed") {
			controlPoints.push(controlPoints[0]);
		} else if (geoNode.Form == "Periodic") {
			startKnot = degree;
			endKnot = knots.length - 1 - startKnot;

			for (i in controlPoints) {
				controlPoints.push(controlPoints[i]);
			}
		}

		var curve = new NURBSCurve(degree, knots, controlPoints, startKnot, endKnot);
		var points = curve.getPoints(controlPoints.length * 12);

		return new Geometry().setFromPoints(points);
	}
}