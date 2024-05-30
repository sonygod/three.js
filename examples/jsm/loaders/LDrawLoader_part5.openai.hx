import js.html.Group;
import js.three.Group;
import js.three.Material;
import js.three.Mesh;
import js.three.Object3D;
import js.three.Vector3;

class LDrawPartsGeometryCache {
	var loader:LDrawLoader;
	var parseCache:LDrawParsedCache;
	var cache:Map<String, Group>;

	public function new(loader:LDrawLoader) {
		this.loader = loader;
		this.parseCache = new LDrawParsedCache(loader);
		this.cache = new Map<String, Group>();
	}

	async function processIntoMesh(info:LDrawFileInfo):Promise<Group> {
		var loader = this.loader;
		var parseCache = this.parseCache;
		var faceMaterials = new Set<String>();

		async function processInfoSubobjects(info:LDrawFileInfo, subobject:LDrawFileInfo = null):PromiseVoid {
			var subobjects = info.subobjects;
			var promises = new Array<Promise<Void>>();

			for (i in 0...subobjects.length) {
				var subobject = subobjects[i];
				var promise = parseCache.ensureDataLoaded(subobject.fileName).then(() -> {
					var subobjectInfo = parseCache.getData(subobject.fileName, false);
					if (!isPrimitiveType(subobjectInfo.type)) {
						return loadModel(subobject.fileName).catchError((error) -> {
							trace("Error loading subobject: " + error);
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

			var subobjectInfos = await Promise.all(promises);
			for (i in 0...subobjectInfos.length) {
				var subobject = info.subobjects[i];
				var subobjectInfo = subobjectInfos[i];

				if (subobjectInfo == null) {
					// the subobject failed to load
					continue;
				}

				// if the subobject was loaded as a separate group then apply the parent scopes materials
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

				// add the subobject group if it has children in case it has both children and primitives
				if (subobjectInfo.group.children.length > 0) {
					group.add(subobjectInfo.group);
				}

				// transform the primitives into the local space of the parent piece and append them to
				// to the parent primitives list.
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
				for (j in 0...lineSegments.length) {
					var ls = lineSegments[j];
					ls.vertices[0].applyMatrix4(matrix);
					ls.vertices[1].applyMatrix4(matrix);
					ls.colorCode = ls.colorCode == MAIN_EDGE_COLOUR_CODE ? lineColorCode : ls.colorCode;
					ls.material = ls.material || getMaterialFromCode(ls.colorCode, ls.colorCode, info.materials, true);

					parentLineSegments.push(ls);
				}

				for (j in 0...conditionalSegments.length) {
					var os = conditionalSegments[j];
					os.vertices[0].applyMatrix4(matrix);
					os.vertices[1].applyMatrix4(matrix);
					os.controlPoints[0].applyMatrix4(matrix);
					os.controlPoints[1].applyMatrix4(matrix);
					os.colorCode = os.colorCode == MAIN_EDGE_COLOUR_CODE ? lineColorCode : os.colorCode;
					os.material = os.material || getMaterialFromCode(os.colorCode, os.colorCode, info.materials, true);

					parentConditionalSegments.push(os);
				}

				for (j in 0...faces.length) {
					var tri = faces[j];
					tri.vertices[0].applyMatrix4(matrix);
					tri.vertices[1].applyMatrix4(matrix);
					tri.vertices[2].applyMatrix4(matrix);
					tri.colorCode = tri.colorCode == MAIN_COLOUR_CODE ? colorCode : tri.colorCode;
					tri.material = tri.material || getMaterialFromCode(tri.colorCode, colorCode, info.materials, false);
					faceMaterials.add(tri.colorCode);

					// If the scale of the object is negated then the triangle winding order
					// needs to be flipped.
					if (matrixScaleInverted != inverted) {
						tri.vertices.reverse();
					}

					parentFaces.push(tri);
				}

				info.totalFaces += subobjectInfo.totalFaces;
			}

			// Apply the parent subobjects pass through material code to this object. This is done several times due
			// to material scoping.
			if (subobject != null) {
				loader.applyMaterialsToMesh(group, subobject.colorCode, info.materials);
				group.userData.colorCode = subobject.colorCode;
			}

			return group;
		}

		// Track material use to see if we need to use the normal smooth slow path for hard edges.
		for (i in 0...info.faces.length) {
			faceMaterials.add(info.faces[i].colorCode);
		}

		await processInfoSubobjects(info);

		if (loader.smoothNormals) {
			var checkSubSegments = faceMaterials.size > 1;
			generateFaceNormals(info.faces);
			smoothNormals(info.faces, info.lineSegments, checkSubSegments);
		}

		// Add the primitive objects and metadata.
		var group = info.group;
		if (info.faces.length > 0) {
			group.add(createObject(loader, info.faces, 3, false, info.totalFaces));
		}

		if (info.lineSegments.length > 0) {
			group.add(createObject(loader, info.lineSegments, 2));
		}

		if (info.conditionalSegments.length > 0) {
			group.add(createObject(loader, info.conditionalSegments, 2, true));
		}

		return group;
	}

	function hasCachedModel(fileName:String):Bool {
		return fileName != null && cache.exists(fileName.toLowerCase());
	}

	async function getCachedModel(fileName:String):Promise<Group> {
		if (fileName != null && hasCachedModel(fileName)) {
			var key = fileName.toLowerCase();
			var group = await cache.get(key);
			return group.clone();
		} else {
			return null;
		}
	}

	// Loads and parses the model with the given file name. Returns a cached copy if available.
.async function loadModel(fileName:String):Promise<Group> {
		var parseCache = this.parseCache;
		var key = fileName.toLowerCase();
		if (hasCachedModel(fileName)) {
			// Return cached model if available.
			return getCachedModel(fileName);
		} else {
			// Otherwise parse a new model.
			// Ensure the file data is loaded and pre parsed.
			await parseCache.ensureDataLoaded(fileName);

			var info = parseCache.getData(fileName);
			var promise = processIntoMesh(info);

			// Now that the file has loaded it's possible that another part parse has been waiting in parallel
			// so check the cache again to see if it's been added since the last async operation so we don't
			// do unnecessary work.
			if (hasCachedModel(fileName)) {
				return getCachedModel(fileName);
			}

			// Cache object if it's a part so it can be reused later.
			if (isPartType(info.type)) {
				cache.set(key, promise);
			}

			// return a copy
			var group = await promise;
			return group.clone();
		}
	}

	// parses the given model text into a renderable object. Returns cached copy if available.
	async function parseModel(text:String):Promise<Group> {
		var parseCache = this.parseCache;
		var info = parseCache.parse(text);
		if (isPartType(info.type) && hasCachedModel(info.fileName)) {
			return getCachedModel(info.fileName);
		}

		return processIntoMesh(info);
	}
}