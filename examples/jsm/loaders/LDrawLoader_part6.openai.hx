package three.js.examples.jsm.loaders;

import three.js.loaders.Loader;
import three.js.materials.Material;
import three.js.materials.MeshStandardMaterial;
import three.js.materials.LineBasicMaterial;
import three.js.materials.LineSegments;
import three.js.parsers.LDrawPartsGeometryCache;
import three.js.parsers.LDrawConditionalLineMaterial;
import three.js.loaders.FileLoader;
import three.js.loaders.FileLoaderOptions;

class LDrawLoader extends Loader {
    // Array of THREE.Material
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

    public function new(manager:Loader) {
        super(manager);
        materials = [];
        materialLibrary = new Map<String, Material>();
        edgeMaterialCache = new WeakMap<Material, Material>();
        conditionalEdgeMaterialCache = new WeakMap<Material, Material>();
        partsCache = new LDrawPartsGeometryCache(this);
        fileMap = new Map<String, String>();
        smoothNormals = true;
        partsLibraryPath = '';
        missingColorMaterial = new MeshStandardMaterial({name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF, roughness: 0.3, metalness: 0});
        missingEdgeColorMaterial = new LineBasicMaterial({name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF});
        missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial({name: Loader.DEFAULT_MATERIAL_NAME, fog: true, color: 0xFF00FF});
        edgeMaterialCache.set(missingColorMaterial, missingEdgeColorMaterial);
        conditionalEdgeMaterialCache.set(missingEdgeColorMaterial, missingConditionalEdgeColorMaterial);
    }

    public function setPartsLibraryPath(path:String):LDrawLoader {
        partsLibraryPath = path;
        return this;
    }

    public function preloadMaterials(url:String):Promise<Void> {
        var fileLoader = new FileLoader(manager);
        fileLoader.setPath(path);
        fileLoader.setRequestHeader(requestHeader);
        fileLoader.setWithCredentials(withCredentials);

        return fileLoader.loadAsync(url).then(function(text:String):Void {
            var colorLineRegex = ~/^0 !COLOUR/;
            var lines:Array<String> = text.split ~/[\n\r]/g;
            var materials:Array<Material> = [];
            for (i in 0...lines.length) {
                var line = lines[i];
                if (colorLineRegex.match(line)) {
                    var directive = line.replace(colorLineRegex, '');
                    var material = parseColorMetaDirective(new LineParser(directive));
                    materials.push(material);
                }
            }

            setMaterials(materials);
        });
    }

    public function load(url:String, onLoad: Group->Void, onProgress:ProgressEvent->Void, onError:Error->Void):Void {
        var fileLoader = new FileLoader(manager);
        fileLoader.setPath(path);
        fileLoader.setRequestHeader(requestHeader);
        fileLoader.setWithCredentials(withCredentials);

        fileLoader.load(url, function(text:String):Void {
            partsCache.parseModel(text, materialLibrary).then(function(group:Group):Void {
                applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
                computeBuildingSteps(group);
                group.userData.fileName = url;
                onLoad(group);
            }).catchError(onError);
        }, onProgress, onError);
    }

    public function parse(text:String, onLoad:Group->Void, onError:Error->Void):Void {
        partsCache.parseModel(text, materialLibrary).then(function(group:Group):Void {
            applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
            computeBuildingSteps(group);
            group.userData.fileName = '';
            onLoad(group);
        }).catchError(onError);
    }

    public function setMaterials(materials:Array<Material>):LDrawLoader {
        materialLibrary = new Map<String, Material>();
        this.materials = [];
        for (material in materials) {
            addMaterial(material);
        }

        addMaterial(parseColorMetaDirective(new LineParser('Main_Colour CODE 16 VALUE #FF8080 EDGE #333333')));
        addMaterial(parseColorMetaDirective(new LineParser('Edge_Colour CODE 24 VALUE #A0A0A0 EDGE #333333')));

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
        if (colorCode.startsWith('0x2')) {
            var color = colorCode.substring(3);
            return parseColorMetaDirective(new LineParser('Direct_Colour_' + color + ' CODE -1 VALUE #' + color + ' EDGE #' + color + ''));
        }

        return materialLibrary.get(colorCode) || null;
    }

    public function applyMaterialsToMesh(group:Group, parentColorCode:String, materialHierarchy:Map<String, Material>, ?finalMaterialPass:Bool=false):Void {
        // find any missing materials as indicated by a color code string and replace it with a material from the current material lib
        function getMaterial(c:Object3D, colorCode:String):Material {
            if (parentIsPassthrough && !materialHierarchy.exists(colorCode) && !finalMaterialPass) {
                return colorCode;
            }

            let material:Material = materialHierarchy.get(colorCode);
            if (material == null) {
                material = getMaterial(c, parentColorCode);
            }

            if (c.isLineSegments || c.isConditionalLine) {
                material = edgeMaterialCache.get(material);
                if (c.isConditionalLine) {
                    material = conditionalEdgeMaterialCache.get(material);
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
        return mat != null ? edgeMaterialCache.get(mat) : null;
    }

    public function parseColorMetaDirective(lineParser:LineParser):Material {
        // parses a color definition and returns a THREE.Material
        // ...
    }

    public function computeBuildingSteps(model:Group):Void {
        // sets userdata.buildingStep number in Group objects and userdata.numBuildingSteps number in the root Group object.
        // ...
    }
}