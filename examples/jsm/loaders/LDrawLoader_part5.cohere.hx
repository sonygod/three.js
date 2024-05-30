class LDrawPartsGeometryCache {
    private var _cache:StringMap<Group>;
    private var parseCache:LDrawParsedCache;
    private var loader:any;

    public function new(loader:any) {
        this._cache = StringMap.build();
        this.parseCache = new LDrawParsedCache(loader);
        this.loader = loader;
    }

    async function processIntoMesh(info:any):Async<Group> {
        var loader = this.loader;
        var parseCache = this.parseCache;
        var faceMaterials = new Set<Int>();

        async function processInfoSubobjects(info:any, subobject:any = null):Async<Void> {
            var subobjects = info.subobjects;
            var promises = [];

            for (sub in subobjects) {
                var subobject = subobjects[sub];
                var promise = parseCache.ensureDataLoaded(subobject.fileName).andThen(function() {
                    var subobjectInfo = parseCache.getData(subobject.fileName, false);
                    if (!isPrimitiveType(subobjectInfo.type)) {
                        return this.loadModel(subobject.fileName).catch($bind(trace, 'Error loading model: $it'));
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
            for (sub in subobjects) {
                var subobject = info.subobjects[sub];
                var subobjectInfo = subobjectInfos[sub];

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

                if (subobjectInfo.group.children.length > 0) {
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

                var lineColorCode = if (colorCode == MAIN_COLOUR_CODE) MAIN_EDGE_COLOUR_CODE else colorCode;
                for (ls in lineSegments) {
                    var ls = lineSegments[ls];
                    var vertices = ls.vertices;
                    vertices[0].applyMatrix4(matrix);
                    vertices[1].applyMatrix4(matrix);
                    ls.colorCode = if (ls.colorCode == MAIN_EDGE_COLOUR_CODE) lineColorCode else ls.colorCode;
                    ls.material = ls.material ?? getMaterialFromCode(ls.colorCode, ls.colorCode, info.materials, true);

                    parentLineSegments.push(ls);
                }

                for (os in conditionalSegments) {
                    var os = conditionalSegments[os];
                    var vertices = os.vertices;
                    var controlPoints = os.controlPoints;
                    vertices[0].applyMatrix4(matrix);
                    vertices[1].applyMatrix4(matrix);
                    controlPoints[0].applyMatrix4(matrix);
                    controlPoints[1].applyMatrix4(matrix);
                    os.colorCode = if (os.colorCode == MAIN_EDGE_COLOUR_CODE) lineColorCode else os.colorCode;
                    os.material = os.material ?? getMaterialFromCode(os.colorCode, os.colorCode, info.materials, true);

                    parentConditionalSegments.push(os);
                }

                for (tri in faces) {
                    var tri = faces[tri];
                    var vertices = tri.vertices;
                    for (v in vertices) {
                        vertices[v].applyMatrix4(matrix);
                    }

                    tri.colorCode = if (tri.colorCode == MAIN_COLOUR_CODE) colorCode else tri.colorCode;
                    tri.material = tri.material ?? getMaterialFromCode(tri.colorCode, colorCode, info.materials, false);
                    faceMaterials.add(tri.colorCode);

                    if (matrixScaleInverted != inverted) {
                        vertices.reverse();
                    }

                    parentFaces.push(tri);
                }

                info.totalFaces += subobjectInfo.totalFaces;
            }

            if (subobject != null) {
                loader.applyMaterialsToMesh(group, subobject.colorCode, info.materials);
                group.userData.colorCode = subobject.colorCode;
            }
        }

        for (face in info.faces) {
            faceMaterials.add(info.faces[face].colorCode);
        }

        await processInfoSubobjects(info);

        if (loader.smoothNormals) {
            var checkSubSegments = faceMaterials.size > 1;
            generateFaceNormals(info.faces);
            smoothNormals(info.faces, info.lineSegments, checkSubSegments);
        }

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
        return fileName != null && fileName.toLowerCase() in this._cache;
    }

    async function getCachedModel(fileName:String):Async<Group> {
        if (fileName != null && this.hasCachedModel(fileName)) {
            var key = fileName.toLowerCase();
            return await this._cache.get(key).clone();
        } else {
            return null;
        }
    }

    async function loadModel(fileName:String):Async<Group> {
        var parseCache = this.parseCache;
        var key = fileName.toLowerCase();
        if (this.hasCachedModel(fileName)) {
            return this.getCachedModel(fileName);
        } else {
            await parseCache.ensureDataLoaded(fileName);

            var info = parseCache.getData(fileName);
            var promise = this.processIntoMesh(info);

            if (this.hasCachedModel(fileName)) {
                return this.getCachedModel(fileName);
            }

            if (isPartType(info.type)) {
                this._cache[key] = promise;
            }

            return await promise.clone();
        }
    }

    async function parseModel(text:String):Async<Group> {
        var parseCache = this.parseCache;
        var info = parseCache.parse(text);
        if (isPartType(info.type) && this.hasCachedModel(info.fileName)) {
            return this.getCachedModel(info.fileName);
        }

        return this.processIntoMesh(info);
    }
}