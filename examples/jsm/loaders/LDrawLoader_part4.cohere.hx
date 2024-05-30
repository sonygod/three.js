class LDrawParsedCache {
    private var _cache:StringMap<LDModel>;
    private var loader:LDLoader;

    public function new(loader:LDLoader) {
        this.loader = loader;
        _cache = {};
    }

    public function cloneResult(original:LDModel):LDModel {
        var result = {
            faces: [],
            conditionalSegments: [],
            lineSegments: [],
            type: original.type,
            category: original.category,
            keywords: original.keywords,
            author: original.author,
            subobjects: original.subobjects,
            fileName: original.fileName,
            totalFaces: original.totalFaces,
            startingBuildingStep: original.startingBuildingStep,
            materials: original.materials,
            group: null
        };

        for (face in original.faces) {
            var newFace = {
                colorCode: face.colorCode,
                material: face.material,
                vertices: [],
                normals: [],
                faceNormal: null
            };

            for (vertex in face.vertices) {
                newFace.vertices.push(vertex.clone());
            }

            for (_ in face.normals) {
                newFace.normals.push(null);
            }

            result.faces.push(newFace);
        }

        for (face in original.conditionalSegments) {
            var newFace = {
                colorCode: face.colorCode,
                material: face.material,
                vertices: [],
                controlPoints: []
            };

            for (vertex in face.vertices) {
                newFace.vertices.push(vertex.clone());
            }

            for (controlPoint in face.controlPoints) {
                newFace.controlPoints.push(controlPoint.clone());
            }

            result.conditionalSegments.push(newFace);
        }

        for (face in original.lineSegments) {
            var newFace = {
                colorCode: face.colorCode,
                material: face.material,
                vertices: []
            };

            for (vertex in face.vertices) {
                newFace.vertices.push(vertex.clone());
            }

            result.lineSegments.push(newFace);
        }

        return result;
    }

    public async function fetchData(fileName:String):String {
        var triedLowerCase = false;
        var locationState = FILE_LOCATION_TRY_PARTS;
        while (locationState != FILE_LOCATION_NOT_FOUND) {
            var subobjectURL = fileName;
            switch (locationState) {
                case FILE_LOCATION_AS_IS:
                    locationState++;
                    break;
                case FILE_LOCATION_TRY_PARTS:
                    subobjectURL = 'parts/' + subobjectURL;
                    locationState++;
                    break;
                case FILE_LOCATION_TRY_P:
                    subobjectURL = 'p/' + subobjectURL;
                    locationState++;
                    break;
                case FILE_LOCATION_TRY_MODELS:
                    subobjectURL = 'models/' + subobjectURL;
                    locationState++;
                    break;
                case FILE_LOCATION_TRY_RELATIVE:
                    subobjectURL = fileName.substring(0, fileName.lastIndexOf('/' + 1)) + subobjectURL;
                    locationState++;
                    break;
                case FILE_LOCATION_TRY_ABSOLUTE:
                    if (triedLowerCase) {
                        locationState = FILE_LOCATION_NOT_FOUND;
                    } else {
                        fileName = fileName.toLowerCase();
                        subobjectURL = fileName;
                        triedLowerCase = true;
                        locationState = FILE_LOCATION_TRY_PARTS;
                    }
                    break;
            }

            var fileLoader = new FileLoader(loader.manager);
            fileLoader.path = loader.partsLibraryPath;
            fileLoader.requestHeader = loader.requestHeader;
            fileLoader.withCredentials = loader.withCredentials;

            try {
                var text = await fileLoader.loadAsync(subobjectURL);
                return text;
            } catch (_) {
                continue;
            }
        }

        throw new Error('LDrawLoader: Subobject "' + fileName + '" could not be loaded.');
    }

    public function parse(text:String, fileName:String = null):LDModel {
        var loader = this.loader;
        var faces:Array<LDFace> = [];
        var lineSegments:Array<LDLineSegment> = [];
        var conditionalSegments:Array<LDLineSegment> = [];
        var subobjects:Array<LDSubobject> = [];
        var materials:StringMap<LDMaterial> = {};

        function getLocalMaterial(colorCode:Int) :LDMaterial {
            return materials.get(colorCode) as LDLMaterial ? null;
        }

        var type = 'Model';
        var category:String = null;
        var keywords:Array<String> = null;
        var author:String = null;
        var totalFaces = 0;

        if (text.indexOf('\r\n') != -1) {
            text = text.replace(/\r\n/g, '\n');
        }

        var lines = text.split('\n');
        var numLines = lines.length;

        var parsingEmbeddedFiles = false;
        var currentEmbeddedFileName:String = null;
        var currentEmbeddedText:String = null;

        var bfcCertified = false;
        var bfcCCW = true;
        var bfcInverted = false;
        var bfcCull = true;

        var startingBuildingStep = false;

        for (lineIndex in 0...numLines) {
            var line = lines[lineIndex];
            if (line.length == 0) {
                continue;
            }

            if (parsingEmbeddedFiles) {
                if (line.startsWith('0 FILE ')) {
                    this.setData(currentEmbeddedFileName, currentEmbeddedText);
                    currentEmbeddedFileName = line.substring(7);
                    currentEmbeddedText = '';
                } else {
                    currentEmbeddedText += line + '\n';
                }
                continue;
            }

            var lp = new LineParser(line, lineIndex + 1);
            lp.seekNonSpace();

            if (lp.isAtTheEnd()) {
                continue;
            }

            var lineType = lp.getToken();

            var material:LDMaterial;
            var colorCode:Int;
            var segment:LDLineSegment;
            var ccw:Bool;
            var doubleSided:Bool;
            var v0:Vector3D<Float>, v1:Vector3D<Float>, v2:Vector3D<Float>, v3:Vector3D<Float>, c0:Vector3D<Float>, c1:Vector3D<Float>;

            switch (lineType) {
                case '0': // Comment or META
                    var meta = lp.getToken();
                    if (meta) {
                        switch (meta) {
                            case '!LDRAW_ORG':
                                type = lp.getToken();
                                break;
                            case '!COLOUR':
                                material = loader.parseColorMetaDirective(lp);
                                if (material) {
                                    materials[material.userData.code] = material;
                                } else {
                                    trace('LDrawLoader: Error parsing material' + lp.getLineNumberString());
                                }
                                break;
                            case '!CATEGORY':
                                category = lp.getToken();
                                break;
                            case '!KEYWORDS':
                                var newKeywords = lp.getRemainingString().split(',');
                                if (newKeywords.length > 0) {
                                    if (!keywords) {
                                        keywords = [];
                                    }
                                    for (keyword in newKeywords) {
                                        keywords.push(keyword.trim());
                                    }
                                }
                                break;
                            case 'FILE':
                                if (lineIndex > 0) {
                                    parsingEmbeddedFiles = true;
                                    currentEmbeddedFileName = lp.getRemainingString();
                                    currentEmbeddedText = '';
                                    bfcCertified = false;
                                    bfcCCW = true;
                                }
                                break;
                            case 'BFC':
                                while (!lp.isAtTheEnd()) {
                                    var token = lp.getToken();
                                    switch (token) {
                                        case 'CERTIFY':
                                        case 'NOCERTIFY':
                                            bfcCertified = token == 'CERTIFY';
                                            bfcCCW = true;
                                            break;
                                        case 'CW':
                                        case 'CCW':
                                            bfcCCW = token == 'CCW';
                                            break;
                                        case 'INVERTNEXT':
                                            bfcInverted = true;
                                            break;
                                        case 'CLIP':
                                        case 'NOCLIP':
                                            bfcCull = token == 'CLIP';
                                            break;
                                        default:
                                            trace('THREE.LDrawLoader: BFC directive "' + token + '" is unknown.');
                                            break;
                                    }
                                }
                                break;
                            case 'STEP':
                                startingBuildingStep = true;
                                break;
                            case 'Author:':
                                author = lp.getToken();
                                break;
                            default:
                                // Other meta directives are not implemented
                                break;
                        }
                    }
                    break;
                case '1': // Sub-object file
                    colorCode = lp.getToken() as Int;
                    material = getLocalMaterial(colorCode);
                    var posX = lp.getFloat();
                    var posY = lp.getFloat();
                    var posZ = lp.getFloat();
                    var m0 = lp.getFloat();
                    var m1 = lp.getFloat();
                    var m2 = lp.getFloat();
                    var m3 = lp.getFloat();
                    var m4 = lp.getFloat();
                    var m5 = lp.getFloat();
                    var m6 = lp.getFloat();
                    var m7 = lp.getFloat();
                    var m8 = lp.getFloat();

                    var matrix = new Matrix4(
                        m0, m1, m2, posX,
                        m3, m4, m5, posY,
                        m6, m7, m8, posZ,
                        0, 0, 0, 1
                    );

                    var fileName = lp.getRemainingString().trim().replace(/\\/g, '/');

                    if (loader.fileMap.exists(fileName)) {
                        fileName = loader.fileMap[fileName];
                    } else {
                        if (fileName.startsWith('s/')) {
                            fileName = 'parts/' + fileName;
                        } else if (fileName.startsWith('48/')) {
                            fileName = 'p/' + fileName;
                        }
                    }

                    subobjects.push({
                        material: material,
                        colorCode: colorCode,
                        matrix: matrix,
                        fileName: fileName,
                        inverted: bfcInverted,
                        startingBuildingStep: startingBuildingStep
                    });

                    startingBuildingStep = false;
                    bfcInverted = false;
                    break;
                case '2': // Line segment
                    colorCode = lp.getToken() as Int;
                    material = getLocalMaterial(colorCode);
                    v0 = lp.getVector();
                    v1 = lp.getVector();

                    segment = {
                        material: material,
                        colorCode: colorCode,
                        vertices: [v0, v1]
                    };

                    lineSegments.push(segment);
                    break;
                case '5': // Conditional Line segment
                    colorCode = lp.getToken() as Int;
                    material = getLocalMaterial(colorCode);
                    v0 = lp.getVector();
                    v1 = lp.getVector();
                    c0 = lp.getVector();
                    c1 = lp.getVector();

                    segment = {
                        material: material,
                        colorCode: colorCode,
                        vertices: [v0, v1],
                        controlPoints: [c0, c1]
                    };

                    conditionalSegments.push(segment);
                    break;
                case '3': // Triangle
                    colorCode = lp.getToken() as Int;
                    material = getLocalMaterial(colorCode);
                    ccw = bfcCCW;
                    doubleSided = !bfcCertified || !bfcCull;

                    if (ccw) {
                        v0 = lp.getVector();
                        v1 = lp.getVector();
                        v2 = lp.getVector();
                    } else {
                        v2 = lp.getVector();
                        v1 = lp.getVector();
                        v0 = lp.getVector();
                    }

                    faces.push({
                        material: material,
                        colorCode: colorCode,
                        faceNormal: null,
                        vertices: [v0, v1, v2],
                        normals: [null, null, null]
                    });
                    totalFaces++;

                    if (doubleSided) {
                        faces.push({
                            material: material,
                            colorCode: colorCode,
                            faceNormal: null,
                            vertices: [v2, v1, v0],
                            normals: [null, null, null]
                        });
                        totalFaces++;
                    }
                    break;
                case '4': // Quadrilateral
                    colorCode = lp.getToken() as Int;
                    material = getLocalMaterial(colorCode);
                    ccw = bfcCCW;
                    doubleSided = !bfcCertified || !bfcCull;

                    if (ccw) {
                        v0 = lp.getVector();
                        v1 = lp.getVector();
                        v2 = lp.getVector();
                        v3 = lp.getVector();
                    } else {
                        v3 = lp.getVector();
                        v2 = lp.getVector();
                        v1 = lp.getVector();
                        v0 = lp.getVector();
                    }

                    faces.push({
                        material: material,
                        colorCode: colorCode,
                        faceNormal: null,
                        vertices: [v0, v1, v2, v3],
                        normals: [null, null, null, null]
                    });
                    totalFaces += 2;

                    if (doubleSided) {
                        faces.push({
                            material: material,
                            colorCode: colorCode,
                            faceNormal: null,
                            vertices: [v3, v2, v1, v0],
                            normals: [null, null, null, null]
                        });
                        totalFaces += 2;
                    }
                    break;
                default:
                    throw new Error('LDrawLoader: Unknown line type "' + lineType + '"' + lp.getLineNumberString() + '.');
            }
        }

        if (parsingEmbeddedFiles) {
            this.setData(currentEmbeddedFileName, currentEmbeddedText);
        }

        return {
            faces: faces,
            conditionalSegments: conditionalSegments,
            lineSegments: lineSegments,
            type: type,
            category: category,
            keywords: keywords,
            author: author,
            subobjects: subobjects,
            totalFaces: totalFaces,
            startingBuildingStep: startingBuildingStep,
            materials: materials,
            fileName: fileName,
            group: null
        };
    }

    public function getData(fileName:String, clone:Bool = true):LDModel {
        var key = fileName.toLowerCase();
        var result = _cache.get(key);
        if (result == null || result is Promise) {
            return null;
        }

        if (clone) {
            return cloneResult(result);
        } else {
            return result;
        }
    }

    public async function ensureDataLoaded(fileName:String):Void {
        var key = fileName.toLowerCase();
        if (!_cache.exists(key)) {
            _cache[key] = fetchData(fileName).then(text -> {
                var info = parse(text, fileName);
                _cache[key] = info;
                return info;
            });
        }

        await _cache[key];
    }

    public function setData(fileName:String, text:String):Void {
        var key = fileName.toLowerCase();
        _cache[key] = parse(text, fileName);
    }
}