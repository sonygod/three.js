import js.Promise;
import three.core.Object3D;
import three.objects.Group;
import three.materials.Material;

class LDrawPartsGeometryCache {

    var loader: LDrawLoader;
    var parseCache: LDrawParsedCache;
    var _cache: haxe.ds.StringMap<Promise<Object3D>>;

    public function new(loader: LDrawLoader) {
        this.loader = loader;
        this.parseCache = new LDrawParsedCache(loader);
        this._cache = new haxe.ds.StringMap<Promise<Object3D>>();
    }

    public function processIntoMesh(info: LDrawFileInfo): Promise<Object3D> {
        var loader = this.loader;
        var parseCache = this.parseCache;
        var faceMaterials = new haxe.ds.StringMap<Void>();

        var processInfoSubobjects = function(info: LDrawFileInfo, subobject: LDrawSubobject = null): Promise<LDrawFileInfo> {
            var subobjects = info.subobjects;
            var promises = new Array<Promise<Object3D>>();

            for (subobject in subobjects) {
                var promise = parseCache.ensureDataLoaded(subobject.fileName).then(function() {
                    var subobjectInfo = parseCache.getData(subobject.fileName, false);
                    if (!isPrimitiveType(subobjectInfo.type)) {
                        return this.loadModel(subobject.fileName).catch(function(error) {
                            console.warn(error);
                            return null;
                        });
                    }

                    return processInfoSubobjects(parseCache.getData(subobject.fileName), subobject);
                }.bind(this));

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
                for (var i = 0; i < subobjectInfos.length; i++) {
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

                    var lineColorCode = colorCode == MAIN_COLOUR_CODE ? MAIN_EDGE_COLOUR_CODE : colorCode;
                    for (var i = 0; i < lineSegments.length; i++) {
                        var ls = lineSegments[i];
                        var vertices = ls.vertices;
                        vertices[0].applyMatrix4(matrix);
                        vertices[1].applyMatrix4(matrix);
                        ls.colorCode = ls.colorCode == MAIN_EDGE_COLOUR_CODE ? lineColorCode : ls.colorCode;
                        if (ls.material == null) ls.material = getMaterialFromCode(ls.colorCode, ls.colorCode, info.materials, true);

                        parentLineSegments.push(ls);
                    }

                    for (var i = 0; i < conditionalSegments.length; i++) {
                        var os = conditionalSegments[i];
                        var vertices = os.vertices;
                        var controlPoints = os.controlPoints;
                        vertices[0].applyMatrix4(matrix);
                        vertices[1].applyMatrix4(matrix);
                        controlPoints[0].applyMatrix4(matrix);
                        controlPoints[1].applyMatrix4(matrix);
                        os.colorCode = os.colorCode == MAIN_EDGE_COLOUR_CODE ? lineColorCode : os.colorCode;
                        if (os.material == null) os.material = getMaterialFromCode(os.colorCode, os.colorCode, info.materials, true);

                        parentConditionalSegments.push(os);
                    }

                    for (var i = 0; i < faces.length; i++) {
                        var tri = faces[i];
                        var vertices = tri.vertices;
                        for (var i = 0; i < vertices.length; i++) {
                            vertices[i].applyMatrix4(matrix);
                        }

                        tri.colorCode = tri.colorCode == MAIN_COLOUR_CODE ? colorCode : tri.colorCode;
                        if (tri.material == null) tri.material = getMaterialFromCode(tri.colorCode, colorCode, info.materials, false);
                        faceMaterials.set(tri.colorCode, null);

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

                return info;
            });
        };

        for (var i = 0; i < info.faces.length; i++) {
            faceMaterials.set(info.faces[i].colorCode, null);
        }

        return processInfoSubobjects(info).then(function() {
            if (loader.smoothNormals) {
                var checkSubSegments = faceMaterials.keys().length > 1;
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
        }.bind(this));
    }

    public function hasCachedModel(fileName: String): Bool {
        return fileName != null && _cache.exists(fileName.toLowerCase());
    }

    public function getCachedModel(fileName: String): Promise<Object3D> {
        if (fileName != null && this.hasCachedModel(fileName)) {
            var key = fileName.toLowerCase();
            return _cache.get(key).then(function(group) {
                return group.clone();
            });
        } else {
            return Promise.resolve(null);
        }
    }

    public function loadModel(fileName: String): Promise<Object3D> {
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
                    _cache.set(key, promise);
                }

                return promise.then(function(group) {
                    return group.clone();
                });
            }.bind(this));
        }
    }

    public function parseModel(text: String): Promise<Object3D> {
        var parseCache = this.parseCache;
        var info = parseCache.parse(text);
        if (isPartType(info.type) && this.hasCachedModel(info.fileName)) {
            return this.getCachedModel(info.fileName);
        }

        return this.processIntoMesh(info);
    }
}