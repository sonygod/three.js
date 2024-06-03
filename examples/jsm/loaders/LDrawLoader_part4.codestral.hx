class LDrawParsedCache {

    public var loader: LDrawLoader;
    private var _cache: haxe.ds.StringMap<Dynamic>;

    public function new(loader: LDrawLoader) {
        this.loader = loader;
        this._cache = new haxe.ds.StringMap<Dynamic>();
    }

    public function cloneResult(original: Dynamic): Dynamic {
        var result: Dynamic = {};

        result.faces = original.faces.map(function(face: Dynamic) {
            return {
                colorCode: face.colorCode,
                material: face.material,
                vertices: face.vertices.map(function(v: Vector3) return v.clone()),
                normals: new Array<Vector3>(face.vertices.length).map(function(_) return null),
                faceNormal: null
            };
        });

        result.conditionalSegments = original.conditionalSegments.map(function(face: Dynamic) {
            return {
                colorCode: face.colorCode,
                material: face.material,
                vertices: face.vertices.map(function(v: Vector3) return v.clone()),
                controlPoints: face.controlPoints.map(function(v: Vector3) return v.clone())
            };
        });

        result.lineSegments = original.lineSegments.map(function(face: Dynamic) {
            return {
                colorCode: face.colorCode,
                material: face.material,
                vertices: face.vertices.map(function(v: Vector3) return v.clone())
            };
        });

        result.type = original.type;
        result.category = original.category;
        result.keywords = original.keywords;
        result.author = original.author;
        result.subobjects = original.subobjects;
        result.fileName = original.fileName;
        result.totalFaces = original.totalFaces;
        result.startingBuildingStep = original.startingBuildingStep;
        result.materials = original.materials;
        result.group = null;

        return result;
    }

    public async function fetchData(fileName: String): Promise<String> {
        var triedLowerCase: Bool = false;
        var locationState: Int = FILE_LOCATION_TRY_PARTS;
        while (locationState !== FILE_LOCATION_NOT_FOUND) {
            var subobjectURL: String = fileName;
            switch (locationState) {
                case FILE_LOCATION_AS_IS:
                    locationState += 1;
                    break;
                case FILE_LOCATION_TRY_PARTS:
                    subobjectURL = 'parts/' + subobjectURL;
                    locationState += 1;
                    break;
                case FILE_LOCATION_TRY_P:
                    subobjectURL = 'p/' + subobjectURL;
                    locationState += 1;
                    break;
                case FILE_LOCATION_TRY_MODELS:
                    subobjectURL = 'models/' + subobjectURL;
                    locationState += 1;
                    break;
                case FILE_LOCATION_TRY_RELATIVE:
                    subobjectURL = fileName.substring(0, fileName.lastIndexOf('/') + 1) + subobjectURL;
                    locationState += 1;
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

            var fileLoader: FileLoader = new FileLoader(this.loader.manager);
            fileLoader.setPath(this.loader.partsLibraryPath);
            fileLoader.setRequestHeader(this.loader.requestHeader);
            fileLoader.setWithCredentials(this.loader.withCredentials);

            try {
                var text: String = await fileLoader.loadAsync(subobjectURL);
                return text;
            } catch (_error: Dynamic) {
                continue;
            }
        }

        throw new Error('LDrawLoader: Subobject "' + fileName + '" could not be loaded.');
    }

    public function parse(text: String, fileName: Null<String> = null): Dynamic {
        var faces: Array<Dynamic> = [];
        var lineSegments: Array<Dynamic> = [];
        var conditionalSegments: Array<Dynamic> = [];
        var subobjects: Array<Dynamic> = [];
        var materials: haxe.ds.StringMap<Material> = new haxe.ds.StringMap<Material>();

        var getLocalMaterial = function(colorCode: String): Null<Material> {
            return materials.exists(colorCode) ? materials.get(colorCode) : null;
        };

        var type: String = 'Model';
        var category: Null<String> = null;
        var keywords: Null<Array<String>> = null;
        var author: Null<String> = null;
        var totalFaces: Int = 0;

        var lines: Array<String> = text.split('\n');
        var parsingEmbeddedFiles: Bool = false;
        var currentEmbeddedFileName: Null<String> = null;
        var currentEmbeddedText: Null<String> = null;

        var bfcCertified: Bool = false;
        var bfcCCW: Bool = true;
        var bfcInverted: Bool = false;
        var bfcCull: Bool = true;

        var startingBuildingStep: Bool = false;

        for (lineIndex in 0...lines.length) {
            var line: String = lines[lineIndex];

            if (line.length === 0) continue;

            if (parsingEmbeddedFiles) {
                if (line.startsWith('0 FILE ')) {
                    if (currentEmbeddedFileName != null) {
                        this.setData(currentEmbeddedFileName, currentEmbeddedText);
                    }

                    currentEmbeddedFileName = line.substring(7);
                    currentEmbeddedText = '';
                } else {
                    currentEmbeddedText += line + '\n';
                }

                continue;
            }

            var lp: LineParser = new LineParser(line, lineIndex + 1);
            lp.seekNonSpace();

            if (lp.isAtTheEnd()) {
                continue;
            }

            var lineType: String = lp.getToken();

            var material: Null<Material>;
            var colorCode: String;
            var segment: Dynamic;
            var ccw: Bool;
            var doubleSided: Bool;
            var v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, c0: Vector3, c1: Vector3;

            switch (lineType) {
                case '0':
                    var meta: String = lp.getToken();

                    if (meta != null) {
                        switch (meta) {
                            case '!LDRAW_ORG':
                                type = lp.getToken();
                                break;
                            case '!COLOUR':
                                material = this.loader.parseColorMetaDirective(lp);
                                if (material != null) {
                                    materials.set(material.userData.code, material);
                                } else {
                                    trace('LDrawLoader: Error parsing material' + lp.getLineNumberString());
                                }
                                break;
                            case '!CATEGORY':
                                category = lp.getToken();
                                break;
                            case '!KEYWORDS':
                                var newKeywords: Array<String> = lp.getRemainingString().split(',');
                                if (newKeywords.length > 0) {
                                    if (keywords == null) {
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
                                    var token: String = lp.getToken();

                                    switch (token) {
                                        case 'CERTIFY':
                                        case 'NOCERTIFY':
                                            bfcCertified = token === 'CERTIFY';
                                            bfcCCW = true;
                                            break;
                                        case 'CW':
                                        case 'CCW':
                                            bfcCCW = token === 'CCW';
                                            break;
                                        case 'INVERTNEXT':
                                            bfcInverted = true;
                                            break;
                                        case 'CLIP':
                                        case 'NOCLIP':
                                            bfcCull = token === 'CLIP';
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
                                break;
                        }
                    }
                    break;
                case '1':
                    colorCode = lp.getToken();
                    material = getLocalMaterial(colorCode);

                    var posX: Float = Float.parse(lp.getToken());
                    var posY: Float = Float.parse(lp.getToken());
                    var posZ: Float = Float.parse(lp.getToken());
                    var m0: Float = Float.parse(lp.getToken());
                    var m1: Float = Float.parse(lp.getToken());
                    var m2: Float = Float.parse(lp.getToken());
                    var m3: Float = Float.parse(lp.getToken());
                    var m4: Float = Float.parse(lp.getToken());
                    var m5: Float = Float.parse(lp.getToken());
                    var m6: Float = Float.parse(lp.getToken());
                    var m7: Float = Float.parse(lp.getToken());
                    var m8: Float = Float.parse(lp.getToken());

                    var matrix: Matrix4 = new Matrix4();
                    matrix.set(m0, m1, m2, posX, m3, m4, m5, posY, m6, m7, m8, posZ, 0, 0, 0, 1);

                    var fileName: String = lp.getRemainingString().trim().replace(new EReg('\\\\', 'g'), '/');

                    if (this.loader.fileMap.exists(fileName)) {
                        fileName = this.loader.fileMap.get(fileName);
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
                case '2':
                    colorCode = lp.getToken();
                    material = getLocalMaterial(colorCode);
                    v0 = lp.getVector();
                    v1 = lp.getVector();

                    segment = {
                        material: material,
                        colorCode: colorCode,
                        vertices: [v0, v1],
                    };

                    lineSegments.push(segment);

                    break;
                case '5':
                    colorCode = lp.getToken();
                    material = getLocalMaterial(colorCode);
                    v0 = lp.getVector();
                    v1 = lp.getVector();
                    c0 = lp.getVector();
                    c1 = lp.getVector();

                    segment = {
                        material: material,
                        colorCode: colorCode,
                        vertices: [v0, v1],
                        controlPoints: [c0, c1],
                    };

                    conditionalSegments.push(segment);

                    break;
                case '3':
                    colorCode = lp.getToken();
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
                        normals: [null, null, null],
                    });
                    totalFaces++;

                    if (doubleSided) {
                        faces.push({
                            material: material,
                            colorCode: colorCode,
                            faceNormal: null,
                            vertices: [v2, v1, v0],
                            normals: [null, null, null],
                        });
                        totalFaces++;
                    }

                    break;
                case '4':
                    colorCode = lp.getToken();
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
                        normals: [null, null, null, null],
                    });
                    totalFaces += 2;

                    if (doubleSided) {
                        faces.push({
                            material: material,
                            colorCode: colorCode,
                            faceNormal: null,
                            vertices: [v3, v2, v1, v0],
                            normals: [null, null, null, null],
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

    public function getData(fileName: String, clone: Bool = true): Null<Dynamic> {
        var key: String = fileName.toLowerCase();
        var result: Dynamic = this._cache.get(key);
        if (result == null || result is Promise) {
            return null;
        }

        if (clone) {
            return this.cloneResult(result);
        } else {
            return result;
        }
    }

    public async function ensureDataLoaded(fileName: String): Promise<Void> {
        var key: String = fileName.toLowerCase();
        if (!this._cache.exists(key)) {
            this._cache.set(key, this.fetchData(fileName).then(function(text: String) {
                var info: Dynamic = this.parse(text, fileName);
                this._cache.set(key, info);
                return info;
            }));
        }

        await this._cache.get(key);
    }

    public function setData(fileName: String, text: String): Void {
        var key: String = fileName.toLowerCase();
        this._cache.set(key, this.parse(text, fileName));
    }
}