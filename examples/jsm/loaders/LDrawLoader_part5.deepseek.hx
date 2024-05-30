class LDrawPartsGeometryCache {

	var loader:Dynamic;
	var parseCache:LDrawParsedCache;
	var _cache:Map<String, Dynamic>;

	public function new(loader:Dynamic) {
		this.loader = loader;
		this.parseCache = new LDrawParsedCache(loader);
		this._cache = new Map();
	}

	public function processIntoMesh(info:Dynamic):Promise<Dynamic> {
		var loader = this.loader;
		var parseCache = this.parseCache;
		var faceMaterials = new Set();

		var processInfoSubobjects = function(info:Dynamic, subobject:Dynamic = null):Promise<Dynamic> {
			var subobjects = info.subobjects;
			var promises = [];

			for (i in subobjects) {
				var subobject = subobjects[i];
				var promise = parseCache.ensureDataLoaded(subobject.fileName).then(function() {
					var subobjectInfo = parseCache.getData(subobject.fileName, false);
					if (!isPrimitiveType(subobjectInfo.type)) {
						return this.loadModel(subobject.fileName).catch(function(error) {
							trace(error);
							return null;
						});
					}
					return processInfoSubobjects(parseCache.getData(subobject.fileName), subobject);
				});
				promises.push(promise);
			}

			var group = new Group();
			group.userData.category = info.category;
			group.userData.keywords = info.keywords;
			group.userData.author = info.author;
			group.userData.type = info.type;
			group.userData.fileName = info.fileName;
			info.group = group;

			return Promise.all(promises).then(function(subobjectInfos) {
				for (i in subobjectInfos) {
					var subobject = info.subobjects[i];
					var subobjectInfo = subobjectInfos[i];

					if (subobjectInfo == null) {
						continue;
					}

					if (subobjectInfo.isGroup) {
						var subobjectGroup = subobjectInfo;
						subobject.matrix.decompose(subobjectGroup.position, subobjectGroup.quaternion, subobjectGroup.scale);
						subobjectGroup.userData.startingBuildingStep = subobject.startingBuildingStep;
						subobjectGroup.name = subobject.fileName;

						loader.applyMaterialsToMesh(subobjectGroup, subobject.colorCode, info.materials);
						subobjectGroup.userData.colorCode = subobject.colorCode;

						group.add(subobjectGroup);
						continue;
					}

					if (subobjectInfo.group.children.length) {
						group.add(subobjectInfo.group);
					}

					var parentLineSegments = info.lineSegments;
					var parentConditionalSegments = info.conditionalSegments;
					var parentFaces = info.faces;

					var lineSegments = subobjectInfo.lineSegments;
					var conditionalSegments = subobjectInfo.conditionalSegments;
					var faces = subobjectInfo.faces;
					var matrix = subobject.matrix;
					var inverted = subobject.inverted;
					var matrixScaleInverted = matrix.determinant() < 0;
					var colorCode = subobject.colorCode;

					var lineColorCode = colorCode == MAIN_COLOUR_CODE ? MAIN_EDGE_COLOUR_CODE : colorCode;
					for (i in lineSegments) {
						var ls = lineSegments[i];
						var vertices = ls.vertices;
						vertices[0].applyMatrix4(matrix);
						vertices[1].applyMatrix4(matrix);
						ls.colorCode = ls.colorCode == MAIN_EDGE_COLOUR_CODE ? lineColorCode : ls.colorCode;
						ls.material = ls.material || getMaterialFromCode(ls.colorCode, ls.colorCode, info.materials, true);

						parentLineSegments.push(ls);
					}

					for (i in conditionalSegments) {
						var os = conditionalSegments[i];
						var vertices = os.vertices;
						var controlPoints = os.controlPoints;
						vertices[0].applyMatrix4(matrix);
						vertices[1].applyMatrix4(matrix);
						controlPoints[0].applyMatrix4(matrix);
						controlPoints[1].applyMatrix4(matrix);
						os.colorCode = os.colorCode == MAIN_EDGE_COLOUR_CODE ? lineColorCode : os.colorCode;
						os.material = os.material || getMaterialFromCode(os.colorCode, os.colorCode, info.materials, true);

						parentConditionalSegments.push(os);
					}

					for (i in faces) {
						var tri = faces[i];
						var vertices = tri.vertices;
						for (i in vertices) {
							vertices[i].applyMatrix4(matrix);
						}

						tri.colorCode = tri.colorCode == MAIN_COLOUR_CODE ? colorCode : tri.colorCode;
						tri.material = tri.material || getMaterialFromCode(tri.colorCode, colorCode, info.materials, false);
						faceMaterials.add(tri.colorCode);

						if (matrixScaleInverted != inverted) {
							vertices.reverse();
						}

						parentFaces.push(tri);
					}

					info.totalFaces += subobjectInfo.totalFaces;
				}

				if (subobject) {
					loader.applyMaterialsToMesh(group, subobject.colorCode, info.materials);
					group.userData.colorCode = subobject.colorCode;
				}

				return info;
			});
		};

		for (i in info.faces) {
			faceMaterials.add(info.faces[i].colorCode);
		}

		return processInfoSubobjects(info).then(function(info) {
			if (loader.smoothNormals) {
				var checkSubSegments = faceMaterials.size > 1;
				generateFaceNormals(info.faces);
				smoothNormals(info.faces, info.lineSegments, checkSubSegments);
			}

			var group = info.group;
			if (info.faces.length > 0) {
				group.add(createObject(this.loader, info.faces, 3, false, info.totalFaces));
			}

			if (info.lineSegments.length > 0) {
				group.add(createObject(this.loader, info.lineSegments, 2));
			}

			if (info.conditionalSegments.length > 0) {
				group.add(createObject(this.loader, info.conditionalSegments, 2, true));
			}

			return group;
		});
	}

	public function hasCachedModel(fileName:String):Bool {
		return fileName != null && fileName.toLowerCase() in this._cache;
	}

	public function getCachedModel(fileName:String):Promise<Dynamic> {
		if (fileName != null && this.hasCachedModel(fileName)) {
			var key = fileName.toLowerCase();
			var group = this._cache[key];
			return group.clone();
		} else {
			return null;
		}
	}

	public function loadModel(fileName:String):Promise<Dynamic> {
		var parseCache = this.parseCache;
		var key = fileName.toLowerCase();
		if (this.hasCachedModel(fileName)) {
			return this.getCachedModel(fileName);
		} else {
			return parseCache.ensureDataLoaded(fileName).then(function() {
				var info = parseCache.getData(fileName);
				var promise = this.processIntoMesh(info);

				if (this.hasCachedModel(fileName)) {
					return this.getCachedModel(fileName);
				}

				if (isPartType(info.type)) {
					this._cache[key] = promise;
				}

				return promise.then(function(group) {
					return group.clone();
				});
			});
		}
	}

	public function parseModel(text:String):Promise<Dynamic> {
		var parseCache = this.parseCache;
		var info = parseCache.parse(text);
		if (isPartType(info.type) && this.hasCachedModel(info.fileName)) {
			return this.getCachedModel(info.fileName);
		}

		return this.processIntoMesh(info);
	}
}