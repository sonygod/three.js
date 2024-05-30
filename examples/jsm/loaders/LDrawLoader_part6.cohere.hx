class LDrawLoader extends Loader {
    public var materials:Array<Material>;
    public var materialLibrary:Map<String, Material>;
    public var edgeMaterialCache:WeakMap<Material, Material>;
    public var conditionalEdgeMaterialCache:WeakMap<Material, Material>;
    public var partsCache:LDrawPartsGeometryCache;
    public var fileMap:Map<String, String>;
    public var smoothNormals:Bool;
    public var partsLibraryPath:String;
    public var missingColorMaterial:MeshStandardMaterial;
    public var missingEdgeColorMaterial:LineBasicMaterial;
    public var missingConditionalEdgeColorMaterial:LDrawConditionalLineMaterial;

    public function new(manager:LoadingManager) {
        super(manager);
        materials = [];
        materialLibrary = new Map();
        edgeMaterialCache = new WeakMap();
        conditionalEdgeMaterialCache = new WeakMap();
        partsCache = new LDrawPartsGeometryCache(this);
        fileMap = new Map();
        smoothNormals = true;
        partsLibraryPath = "";
        missingColorMaterial = new MeshStandardMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF, roughness: 0.3, metalness: 0 });
        missingEdgeColorMaterial = new LineBasicMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF });
        missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, fog: true, color: 0xFF00FF });
        edgeMaterialCache.set(missingColorMaterial, missingEdgeColorMaterial);
        conditionalEdgeMaterialCache.set(missingEdgeColorMaterial, missingConditionalEdgeColorMaterial);
    }

    public function setPartsLibraryPath(path:String):LDrawLoader {
        partsLibraryPath = path;
        return this;
    }

    public async function preloadMaterials(url:String):Async<Void> {
        var fileLoader = new FileLoader(manager);
        fileLoader.path = path;
        fileLoader.requestHeader = requestHeader;
        fileLoader.withCredentials = withCredentials;
        var text = await fileLoader.loadAsync(url);
        var colorLineRegex = EReg("^0 !COLOUR", "i");
        var lines = text.split([\n\r]);
        var materials = [];
        for (i in 0...lines.length) {
            var line = lines[i];
            if (colorLineRegex.match(line)) {
                var directive = line.replace(colorLineRegex, "");
                var material = parseColorMetaDirective(new LineParser(directive));
                materials.push(material);
            }
        }
        setMaterials(materials);
        return;
    }

    public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var fileLoader = new FileLoader(manager);
        fileLoader.path = path;
        fileLoader.requestHeader = requestHeader;
        fileLoader.withCredentials = withCredentials;
        fileLoader.load(url, function (text) {
            partsCache.parseModel(text, materialLibrary).then(function (group) {
                applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
                computeBuildingSteps(group);
                group.userData.fileName = url;
                onLoad(group);
            }).catch(onError);
        }, onProgress, onError);
    }

    public function parse(text:String, onLoad:Function, onError:Function):Void {
        partsCache.parseModel(text, materialLibrary).then(function (group) {
            applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
            computeBuildingSteps(group);
            group.userData.fileName = "";
            onLoad(group);
        }).catch(onError);
    }

    public function setMaterials(materials:Array<Material>):LDrawLoader {
        materialLibrary = new Map();
        this.materials = [];
        for (i in 0...materials.length) {
            addMaterial(materials[i]);
        }
        addMaterial(parseColorMetaDirective(new LineParser("Main_Colour CODE 16 VALUE #FF8080 EDGE #333333")));
        addMaterial(parseColorMetaDirective(new LineParser("Edge_Colour CODE 24 VALUE #A0A0A0 EDGE #333333")));
        return this;
    }

    public function setFileMap(fileMap:Map<String, String>):LDrawLoader {
        this.fileMap = fileMap;
        return this;
    }

    public function addMaterial(material:Material):LDrawLoader {
        var matLib = materialLibrary;
        if (!matLib.exists(material.userData.code)) {
            materials.push(material);
            matLib.set(material.userData.code, material);
        }
        return this;
    }

    public function getMaterial(colorCode:String):Material {
        if (StringTools.startsWith(colorCode, "0x2")) {
            var color = StringTools.substr(colorCode, 3, null);
            return parseColorMetaDirective(new LineParser("Direct_Color_" + color + " CODE -1 VALUE #" + color + " EDGE #" + color));
        }
        return materialLibrary.get(colorCode) ?? null;
    }

    public function applyMaterialsToMesh(group:Group, parentColorCode:String, materialHierarchy:Map<String, Material>, finalMaterialPass:Bool = false):Void {
        var loader = this;
        var parentIsPassthrough = parentColorCode == MAIN_COLOUR_CODE;
        group.traverse(function (c) {
            if (c is Mesh || c is LineSegments) {
                if (c.material is Array) {
                    for (i in 0...c.material.length) {
                        if (!(c.material[i] is Material)) {
                            c.material[i] = getMaterial(c, c.material[i]);
                        }
                    }
                } else if (!(c.material is Material)) {
                    c.material = getMaterial(c, c.material);
                }
            }
        });
        function getMaterial(c, colorCode) {
            if (parentIsPassthrough && !materialHierarchy.exists(colorCode) && !finalMaterialPass) {
                return colorCode;
            }
            var forEdge = c is LineSegments || c is ConditionalLine;
            var isPassthrough = !forEdge && colorCode == MAIN_COLOUR_CODE || forEdge && colorCode == MAIN_EDGE_COLOUR_CODE;
            if (isPassthrough) {
                colorCode = parentColorCode;
            }
            var material = null;
            if (materialHierarchy.exists(colorCode)) {
                material = materialHierarchy.get(colorCode);
            } else if (finalMaterialPass) {
                material = loader.getMaterial(colorCode);
                if (material == null) {
                    console.log("LDrawLoader: Material properties for code ${colorCode} not available.");
                    material = loader.missingColorMaterial;
                }
            } else {
                return colorCode;
            }
            if (c is LineSegments) {
                material = loader.edgeMaterialCache.get(material);
                if (c is ConditionalLine) {
                    material = loader.conditionalEdgeMaterialCache.get(material);
                }
            }
            return material;
        }
    }

    public function getMainMaterial():Material {
        return getMaterial(MAIN_COLOUR_CODE);
    }

    public function getMainEdgeMaterial():Material {
        var mat = getMaterial(MAIN_EDGE_COLOUR_CODE);
        return mat ? edgeMaterialCache.get(mat) : null;
    }

    public function parseColorMetaDirective(lineParser:LineParser):Material {
        var code:Int;
        var fillColor = "#FF00FF";
        var edgeColor = "#FF00FF";
        var alpha = 1;
        var isTransparent = false;
        var luminance = 0;
        var finishType = FINISH_TYPE_DEFAULT;
        var edgeMaterial:Material;
        var name = lineParser.getToken();
        if (name == null) {
            throw new Error("LDrawLoader: Material name was expected after !COLOUR tag " + lineParser.getLineNumberString() + ".");
        }
        while (true) {
            var token = lineParser.getToken();
            if (token == null) {
                break;
            }
            if (!parseLuminance(token)) {
                switch (token.toUpperCase()) {
                    case "CODE":
                        code = Std.parseInt(lineParser.getToken());
                        break;
                    case "VALUE":
                        fillColor = lineParser.getToken();
                        if (StringTools.startsWith(fillColor, "0x")) {
                            fillColor = "#" + StringTools.substr(fillColor, 2, null);
                        } else if (!StringTools.startsWith(fillColor, "#")) {
                            throw new Error("LDrawLoader: Invalid color while parsing material " + lineParser.getLineNumberString() + ".");
                        }
                        break;
                    case "EDGE":
                        edgeColor = lineParser.getToken();
                        if (StringTools.startsWith(edgeColor, "0x")) {
                            edgeColor = "#" + StringTools.substr(edgeColor, 2, null);
                        } else if (!StringTools.startsWith(edgeColor, "#")) {
                            edgeMaterial = getMaterial(edgeColor);
                            if (edgeMaterial == null) {
                                throw new Error("LDrawLoader: Invalid edge color while parsing material " + lineParser.getLineNumberString() + ".");
                            }
                            edgeMaterial = edgeMaterialCache.get(edgeMaterial);
                        }
                        break;
                    case "ALPHA":
                        alpha = Std.parseInt(lineParser.getToken());
                        if (alpha == null) {
                            throw new Error("LDrawLoader: Invalid alpha value in material definition " + lineParser.getLineNumberString() + ".");
                        }
                        alpha = Math.max(0, Math.min(1, alpha / 255));
                        if (alpha < 1) {
                            isTransparent = true;
                        }
                        break;
                    case "LUMINANCE":
                        if (!parseLuminance(lineParser.getToken())) {
                            throw new Error("LDrawLoader: Invalid luminance value in material definition " + lineParser.getLineNumberString() + ".");
                        }
                        break;
                    case "CHROME":
                        finishType = FINISH_TYPE_CHROME;
                        break;
                    case "PEARLESCENT":
                        finishType = FINISH_TYPE_PEARLESCENT;
                        break;
                    case "RUBBER":
                        finishType = FINISH_TYPE_RUBBER;
                        break;
                    case "MATTE_METALLIC":
                        finishType = FINISH_TYPE_MATTE_METALLIC;
                        break;
                    case "METAL":
                        finishType = FINISH_TYPE_METAL;
                        break;
                    case "MATERIAL":
                        // Not implemented
                        lineParser.setToEnd();
                        break;
                    default:
                        throw new Error("LDrawLoader: Unknown token " + token + " while parsing material " + lineParser.getLineNumberString() + ".");
                }
            }
        }
        var material:Material;
        switch (finishType) {
            case FINISH_TYPE_DEFAULT:
                material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0 });
                break;
            case FINISH_TYPE_PEARLESCENT:
                material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0.25 });
                break;
            case FINISH_TYPE_CHROME:
                material = new MeshStandardMaterial({ roughness: 0, metalness: 1 });
                break;
            case FINISH_TYPE_RUBBER:
                material = new MeshStandardMaterial({ roughness: 0.9, metalness: 0 });
                break;
            case FINISH_TYPE_MATTE_METALLIC:
                material = new MeshStandardMaterial({ roughness: 0.8, metalness: 0.4 });
                break;
            case FINISH_TYPE_METAL:
                material = new MeshStandardMaterial({ roughness: 0.2, metalness: 0.85 });
                break;
            default:
                break;
        }
        material.color.setStyle(fillColor, COLOR_SPACE_LDRAW);
        material.transparent = isTransparent;
        material.premultipliedAlpha = true;
        material.opacity = alpha;
        material.depthWrite = !isTransparent;
        material.polygonOffset = true;
        material.polygonOffsetFactor = 1;
        if (luminance != 0) {
            material.emissive.setStyle(fillColor, COLOR_SPACE_LDRAW).multiplyScalar(luminance);
        }
        if (edgeMaterial == null) {
            edgeMaterial = new LineBasicMaterial({
                color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
                transparent: isTransparent,
                opacity: alpha,
                depthWrite: !isTransparent
            });
            edgeMaterial.color;
            edgeMaterial.userData.code = code;
            edgeMaterial.name = name + " - Edge";
            conditionalEdgeMaterialCache.set(edgeMaterial, new LDrawConditionalLineMaterial({
                fog: true,
                transparent: isTransparent,
                depthWrite: !isTransparent,
                color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
                opacity: alpha,
            }));
        }
        material.userData.code = code;
        material.name = name;
        edgeMaterialCache.set(material, edgeMaterial);
        addMaterial(material);
        return material;
        function parseLuminance(token) {
            var lum:Int;
            if (StringTools.startsWith(token, "LUMINANCE")) {
                lum = Std.parseInt(StringTools.substr(token, 9, null));
            } else {
                lum = Std.parseInt(token);
            }
            if (lum == null) {
                return false;
            }
            luminance = Math.max(0, Math.min(1, lum / 255));
            return true;
        }
    }

    public function computeBuildingSteps(model:Group):Void {
        var stepNumber = 0;
        model.traverse(function (c) {
            if (c is Group) {
                if (c.userData.startingBuildingStep) {
                    stepNumber++;
                }
                c.userData.buildingStep = stepNumber;
            }
        });
        model.userData.numBuildingSteps = stepNumber + 1;
    }
}