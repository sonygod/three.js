import js.html.File;
import js.html.FileReader;
import js.html.XMLHttpRequest;

class LDrawLoader extends Loader {

    public var materials:Array<Material> = [];
    public var materialLibrary:Map<String, Material> = new Map<String, Material>();
    public var edgeMaterialCache:Map<Material, Material> = new Map<Material, Material>();
    public var conditionalEdgeMaterialCache:Map<Material, Material> = new Map<Material, Material>();

    public var partsCache:LDrawPartsGeometryCache;
    public var fileMap:Map<String, String> = new Map<String, String>();

    public var smoothNormals:Bool = true;
    public var partsLibraryPath:String = '';

    public var missingColorMaterial:MeshStandardMaterial;
    public var missingEdgeColorMaterial:LineBasicMaterial;
    public var missingConditionalEdgeColorMaterial:LDrawConditionalLineMaterial;

    public function new(manager:LoaderManager) {
        super(manager);

        partsCache = new LDrawPartsGeometryCache(this);

        setMaterials([]);

        missingColorMaterial = new MeshStandardMaterial({
            name: Loader.DEFAULT_MATERIAL_NAME,
            color: 0xFF00FF,
            roughness: 0.3,
            metalness: 0
        });

        missingEdgeColorMaterial = new LineBasicMaterial({
            name: Loader.DEFAULT_MATERIAL_NAME,
            color: 0xFF00FF
        });

        missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial({
            name: Loader.DEFAULT_MATERIAL_NAME,
            fog: true,
            color: 0xFF00FF
        });

        edgeMaterialCache.set(missingColorMaterial, missingEdgeColorMaterial);
        conditionalEdgeMaterialCache.set(missingEdgeColorMaterial, missingConditionalEdgeColorMaterial);
    }

    public function setPartsLibraryPath(path:String):LDrawLoader {
        this.partsLibraryPath = path;
        return this;
    }

    public function preloadMaterials(url:String, onLoad:Null<(Array<Material>) -> Void>, onError:Null<(Dynamic) -> Void>) {
        var fileLoader:FileLoader = new FileLoader(manager);
        fileLoader.setPath(path);
        fileLoader.setRequestHeader(requestHeader);
        fileLoader.setWithCredentials(withCredentials);

        var request:XMLHttpRequest = new XMLHttpRequest();
        request.onreadystatechange = function(_) {
            if (request.readyState === 4) {
                if (request.status === 200) {
                    var text:String = request.responseText;
                    var colorLineRegex:EReg = new EReg("^0 !COLOUR", "");
                    var lines:Array<String> = text.split(/\[\n\r\]/g);
                    var materials:Array<Material> = [];
                    for (line in lines) {
                        if (colorLineRegex.match(line)) {
                            var directive:String = line.replace(colorLineRegex, '');
                            var material:Material = parseColorMetaDirective(new LineParser(directive));
                            materials.push(material);
                        }
                    }

                    if (onLoad != null) onLoad(materials);
                    setMaterials(materials);
                } else {
                    if (onError != null) onError(request.status);
                }
            }
        };

        request.open("GET", url, true);
        request.send();
    }

    public function load(url:String, onLoad:Null<(Group) -> Void>, onProgress:Null<(ProgressEvent) -> Void>, onError:Null<(Dynamic) -> Void>) {
        var fileLoader:FileLoader = new FileLoader(manager);
        fileLoader.setPath(path);
        fileLoader.setRequestHeader(requestHeader);
        fileLoader.setWithCredentials(withCredentials);

        var request:XMLHttpRequest = new XMLHttpRequest();
        request.onreadystatechange = function(_) {
            if (request.readyState === 4) {
                if (request.status === 200) {
                    var text:String = request.responseText;
                    partsCache.parseModel(text, materialLibrary).then(function(group:Group) {
                        applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
                        computeBuildingSteps(group);
                        group.userData.fileName = url;
                        if (onLoad != null) onLoad(group);
                    }).catch(function(error) {
                        if (onError != null) onError(error);
                    });
                } else {
                    if (onError != null) onError(request.status);
                }
            } else if (request.readyState === 3 && onProgress != null) {
                onProgress(request);
            }
        };

        request.open("GET", url, true);
        request.send();
    }

    // ... rest of the code, following a similar pattern to the load method
}