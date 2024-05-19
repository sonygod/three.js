package three.js.examples.jsm.loaders;

import js.html.Group;
import js.html.Loader;
import js.html.LDrawParsedCache;
import js.html.Promise;
import js.html.Set;

class LDrawPartsGeometryCache {
    private var loader:Loader;
    private var parseCache:LDrawParsedCache;
    private var cache:Map<String, Promise<Group>>;

    public function new(loader:Loader) {
        this.loader = loader;
        this.parseCache = new LDrawParsedCache(loader);
        this.cache = new Map<String, Promise<Group>>();
    }

    private function processIntoMesh(info:Any):Promise<Group> {
        var loader = this.loader;
        var parseCache = this.parseCache;
        var faceMaterials = new Set<String>();

        var processInfoSubobjects = function(info:Any, subobject:Any = null):Promise<Void> {
            var subobjects:Array<Any> = info.subobjects;
            var promises:Array<Promise<Void>> = [];

            for (i in 0...subobjects.length) {
                var subobject = subobjects[i];
                var promise = parseCache.ensureDataLoaded(subobject.fileName).then(function() {
                    var subobjectInfo = parseCache.getData(subobject.fileName, false);
                    if (!isPrimitiveType(subobjectInfo.type)) {
                        return loadModel(subobject.fileName).catchError(function(error) {
                            console.warn(error);
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

            return Promise.all(promises).then(function(subobjectInfos:Array<Any>) {
                for (i in 0...subobjectInfos.length) {
                    var subobject = info.subobjects[i];
                    var subobjectInfo = subobjectInfos[i];

                    if (subobjectInfo == null) {
                        continue;
                    }

                    if (subobjectInfo.isGroup) {
                        var subobjectGroup:Group = subobjectInfo;
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

                    // transform the primitives into the local space of the parent piece and append them to
                    // to the parent primitives list.
                    var parentLineSegments:Array<Any> = info.lineSegments;
                    var parentConditionalSegments:Array<Any> = info.conditionalSegments;
                    var parentFaces:Array<Any> = info.faces;

                    var lineSegments:Array<Any> = subobjectInfo.lineSegments;
                    var conditionalSegments:Array<Any> = subobjectInfo.conditionalSegments;

                    var faces:Array<Any> = subobjectInfo.faces;
                    var matrix:Matrix4 = subobject.matrix;
                    var inverted:Bool = subobject.inverted;
                    var matrixScaleInverted:Bool = matrix.determinant() < 0;
                    var colorCode:Int = subobject.colorCode;

                    var lineColorCode:Int = colorCode == MAIN_COLOUR_CODE ? MAIN_EDGE_COLOUR_CODE : colorCode;
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

                        if (matrixScaleInverted != inverted) {
                            tri.vertices.reverse();
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

        for (i in 0...info.faces.length) {
            faceMaterials.add(info.faces[i].colorCode);
        }

        return processInfoSubobjects(info).then(function(info:Any) {
            if (loader.smoothNormals) {
                var checkSubSegments:Bool = faceMaterials.size > 1;
                generateFaceNormals(info.faces);
                smoothNormals(info.faces, info.lineSegments, checkSubSegments);
            }

            var group:Group = info.group;
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
        });
    }

    public function hasCachedModel(fileName:String):Bool {
        return fileName != null && fileName.toLowerCase() in cache;
    }

    public function getCachedModel(fileName:String):Promise<Group> {
        if (fileName != null && hasCachedModel(fileName)) {
            var key:String = fileName.toLowerCase();
            return cache.get(key);
        } else {
            return Promise.resolve(null);
        }
    }

    public function loadModel(fileName:String):Promise<Group> {
        var parseCache = this.parseCache;
        var key:String = fileName.toLowerCase();
        if (hasCachedModel(fileName)) {
            return getCachedModel(fileName);
        } else {
            return parseCache.ensureDataLoaded(fileName).then(function() {
                var info = parseCache.getData(fileName);
                return processIntoMesh(info);
            }).then(function(group:Group) {
                if (isPartType(info.type)) {
                    cache.set(key, group.clone());
                }

                return group.clone();
            });
        }
    }

    public function parseModel(text:String):Promise<Group> {
        var parseCache = this.parseCache;
        var info = parseCache.parse(text);
        if (isPartType(info.type) && hasCachedModel(info.fileName)) {
            return getCachedModel(info.fileName);
        }

        return processIntoMesh(info);
    }
}