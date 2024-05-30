package three.js.loaders;

import haxe.ds.StringMap;
import js.html.FileLoader;
import js.html.Promise;

class LDrawParsedCache {
    public var loader:LDrawLoader;
    public var cache:StringMap<Dynamic>;

    public function new(loader:LDrawLoader) {
        this.loader = loader;
        this.cache = new StringMap();
    }

    public function cloneResult(original:Dynamic):Dynamic {
        var result = {};

        // vertices are transformed and normals computed before being converted to geometry
        // so these pieces must be cloned.
        result.faces = original.faces.map(function(face:Dynamic) {
            return {
                colorCode: face.colorCode,
                material: face.material,
                vertices: face.vertices.map(function(v:Dynamic) {
                    return v.clone();
                }),
                normals: face.normals.map(function() {
                    return null;
                }),
                faceNormal: null
            };
        });

        result.conditionalSegments = original.conditionalSegments.map(function(face:Dynamic) {
            return {
                colorCode: face.colorCode,
                material: face.material,
                vertices: face.vertices.map(function(v:Dynamic) {
                    return v.clone();
                }),
                controlPoints: face.controlPoints.map(function(v:Dynamic) {
                    return v.clone();
                })
            };
        });

        result.lineSegments = original.lineSegments.map(function(face:Dynamic) {
            return {
                colorCode: face.colorCode,
                material: face.material,
                vertices: face.vertices.map(function(v:Dynamic) {
                    return v.clone();
                })
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

    public function fetchData(fileName:String):Promise<String> {
        var triedLowerCase = false;
        var locationState = FILE_LOCATION_TRY_PARTS;
        while (locationState != FILE_LOCATION_NOT_FOUND) {
            var subobjectURL = fileName;
            switch (locationState) {
                case FILE_LOCATION_AS_IS:
                    locationState = locationState + 1;
                    break;
                case FILE_LOCATION_TRY_PARTS:
                    subobjectURL = 'parts/' + subobjectURL;
                    locationState = locationState + 1;
                    break;
                case FILE_LOCATION_TRY_P:
                    subobjectURL = 'p/' + subobjectURL;
                    locationState = locationState + 1;
                    break;
                case FILE_LOCATION_TRY_MODELS:
                    subobjectURL = 'models/' + subobjectURL;
                    locationState = locationState + 1;
                    break;
                case FILE_LOCATION_TRY_RELATIVE:
                    subobjectURL = fileName.substring(0, fileName.lastIndexOf('/') + 1) + subobjectURL;
                    locationState = locationState + 1;
                    break;
                case FILE_LOCATION_TRY_ABSOLUTE:
                    if (triedLowerCase) {
                        // Try absolute path
                        locationState = FILE_LOCATION_NOT_FOUND;
                    } else {
                        // Next attempt is lower case
                        fileName = fileName.toLowerCase();
                        subobjectURL = fileName;
                        triedLowerCase = true;
                        locationState = FILE_LOCATION_TRY_PARTS;
                    }
                    break;
            }

            var loader = this.loader;
            var fileLoader = new FileLoader(loader.manager);
            fileLoader.setPath(loader.partsLibraryPath);
            fileLoader.setRequestHeader(loader.requestHeader);
            fileLoader.setWithCredentials(loader.withCredentials);

            return fileLoader.loadAsync(subobjectURL).then(function(text:String) {
                return text;
            }).catchError(function(_) {
                return null;
            });
        }

        throw new Error('LDrawLoader: Subobject "' + fileName + '" could not be loaded.');
    }

    public function parse(text:String, fileName:String = null):Dynamic {
        var loader = this.loader;

        // final results
        var faces:Array<Dynamic> = [];
        var lineSegments:Array<Dynamic> = [];
        var conditionalSegments:Array<Dynamic> = [];
        var subobjects:Array<Dynamic> = [];
        var materials:StringMap<Material> = new StringMap();

        var getLocalMaterial = function(colorCode:String):Material {
            return materials.get(colorCode) || null;
        };

        var type:String = 'Model';
        var category:String = null;
        var keywords:Array<String> = null;
        var author:String = null;
        var totalFaces:Int = 0;

        // split into lines
        if (text.indexOf('\r\n') != -1) {
            // This is faster than String.split with regex that splits on both
            text = text.replace(/\r\n/g, '\n');
        }

        var lines:Array<String> = text.split('\n');
        var numLines:Int = lines.length;

        var parsingEmbeddedFiles:Bool = false;
        var currentEmbeddedFileName:String = null;
        var currentEmbeddedText:String = '';

        var bfcCertified:Bool = false;
        var bfcCCW:Bool = true;
        var bfcInverted:Bool = false;
        var bfcCull:Bool = true;

        var startingBuildingStep:Bool = false;

        // Parse all line commands
        for (i in 0...numLines) {
            var line:String = lines[i];

            if (parsingEmbeddedFiles) {
                if (line.startsWith('0 FILE ')) {
                    // Save previous embedded file in the cache
                    this.setData(currentEmbeddedFileName, currentEmbeddedText);

                    // New embedded text file
                    currentEmbeddedFileName = line.substring(7);
                    currentEmbeddedText = '';

                } else {
                    currentEmbeddedText += line + '\n';
                }

                continue;
            }

            var lp:LineParser = new LineParser(line, i + 1);
            lp.seekNonSpace();

            if (lp.isAtTheEnd()) {
                // Empty line
                continue;
            }

            // Parse the line type
            var lineType:String = lp.getToken();

            var material:Material;
            var colorCode:String;
            var segment:Dynamic;
            var ccw:Bool;
            var doubleSided:Bool;
            var v0:Vector3;
            var v1:Vector3;
            var v2:Vector3;
            var v3:Vector3;
            var c0:Vector3;
            var c1:Vector3;

            switch (lineType) {
                // Line type 0: Comment or META
                case '0':
                    // Parse meta directive
                    var meta:String = lp.getToken();

                    if (meta != null) {
                        switch (meta) {
                            case '!LDRAW_ORG':
                                type = lp.getToken();
                                break;

                            case '!COLOUR':
                                material = loader.parseColorMetaDirective(lp);
                                if (material != null) {
                                    materials.set(material.userData.code, material);
                                } else {
                                    console.warn('LDrawLoader: Error parsing material' + lp.getLineNumberString());
                                }
                                break;

                            case '!CATEGORY':
                                category = lp.getToken();
                                break;

                            case '!KEYWORDS':
                                var newKeywords:Array<String> = lp.getRemainingString().split(',');
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
                                if (i > 0) {
                                    // Start embedded text files parsing
                                    parsingEmbeddedFiles = true;
                                    currentEmbeddedFileName = lp.getRemainingString();
                                    currentEmbeddedText = '';

                                    bfcCertified = false;
                                    bfcCCW = true;
                                }
                                break;

                            case 'BFC':
                                // Changes to the backface culling state
                                while (!lp.isAtTheEnd()) {
                                    var token:String = lp.getToken();

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
                                            console.warn('THREE.LDrawLoader: BFC directive "' + token + '" is unknown.');
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

                    // Line type 1: Sub-object file
                case '1':
                    colorCode = lp.getToken();
                    material = getLocalMaterial(colorCode);

                    var posX:Float = parseFloat(lp.getToken());
                    var posY:Float = parseFloat(lp.getToken());
                    var posZ:Float = parseFloat(lp.getToken());
                    var m0:Float = parseFloat(lp.getToken());
                    var m1:Float = parseFloat(lp.getToken());
                    var m2:Float = parseFloat(lp.getToken());
                    var m3:Float = parseFloat(lp.getToken());
                    var m4:Float = parseFloat(lp.getToken());
                    var m5:Float = parseFloat(lp.getToken());
                    var m6:Float = parseFloat(lp.getToken());
                    var m7:Float = parseFloat(lp.getToken());
                    var m8:Float = parseFloat(lp.getToken());

                    var matrix:Matrix4 = new Matrix4().set(
                        m0, m1, m2, posX,
                        m3, m4, m5, posY,
                        m6, m7, m8, posZ,
                        0, 0, 0, 1
                    );

                    var fileName:String = lp.getRemainingString().trim().replace(/\\/g, '/');
                    if (loader.fileMap[fileName] != null) {
                        // Found the subobject path in the preloaded file path map
                        fileName = loader.fileMap[fileName];
                    } else {
                        // Standardized subfolders
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

                    // Line type 2: Line segment
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

                    // Line type 5: Conditional Line segment
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
                        controlPoints: [c0, c1]
                    };

                    conditionalSegments.push(segment);

                    break;

                    // Line type 3: Triangle
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

                    // Line type 4: Quadrilateral
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

    public function getData(fileName:String, clone:Bool = true):Dynamic {
        var key:String = fileName.toLowerCase();
        var result:Dynamic = this.cache.get(key);
        if (result == null || result is Promise) {
            return null;
        }

        if (clone) {
            return this.cloneResult(result);
        } else {
            return result;
        }
    }

    public function ensureDataLoaded(fileName:String):Promise<Void> {
        var key:String = fileName.toLowerCase();
        if (!this.cache.exists(key)) {
            this.cache.set(key, this.fetchData(fileName).then(text -> {
                var info:Dynamic = this.parse(text, fileName);
                this.cache.set(key, info);
                return info;
            }));
        }

        return this.cache.get(key);
    }

    public function setData(fileName:String, text:String):Void {
        var key:String = fileName.toLowerCase();
        this.cache.set(key, this.parse(text, fileName));
    }
}