package three.js.examples.jlm.loaders;

import three.js.Color;
import three.js.DefaultLoadingManager;
import three.js.FileLoader;
import three.js.FrontSide;
import three.js.Loader;
import three.js.LoaderUtils;
import three.js.MeshPhongMaterial;
import three.js.RepeatWrapping;
import three.js.SRGBColorSpace;
import three.js.TextureLoader;
import three.js.Vector2;

/**
 * Loads a Wavefront .mtl file specifying materials
 */

class MTLLoader extends Loader {

    public function new(manager:Loader) {
        super(manager);
    }

    /**
     * Loads and parses a MTL asset from a URL.
     *
     * @param url - URL to the MTL file.
     * @param onLoad - Callback invoked with the loaded object.
     * @param onProgress - Callback for download progress.
     * @param onError - Callback for download errors.
     *
     * @see setPath setResourcePath
     *
     * @note In order for relative texture references to resolve correctly
     * you must call setResourcePath() explicitly prior to load.
     */
    public function load(url:String, onLoad:Void->Void, onProgress:Void->Void, onError:Void->Void):Void {
        var scope:MTLLoader = this;
        var path:String = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;

        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(scope.parse(text, path));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    Console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function setMaterialOptions(value:Dynamic):MTLLoader {
        this.materialOptions = value;
        return this;
    }

    /**
     * Parses a MTL file.
     *
     * @param text - Content of MTL file
     * @param path - Path to resolve relative URLs
     * @return MaterialCreator
     *
     * @see setPath setResourcePath
     *
     * @note In order for relative texture references to resolve correctly
     * you must call setResourcePath() explicitly prior to parse.
     */
    public function parse(text:String, path:String):MaterialCreator {
        var lines:Array<String> = text.split('\n');
        var info:Dynamic = {};
        var delimiter_pattern:EReg = ~/[\s]+/;
        var materialsInfo:Dynamic = {};

        for (i in 0...lines.length) {
            var line:String = lines[i].trim();

            if (line.length == 0 || line.charAt(0) == '#') {
                // Blank line or comment ignore
                continue;
            }

            var pos:Int = line.indexOf(' ');
            var key:String = (pos >= 0) ? line.substring(0, pos) : line;
            key = key.toLowerCase();

            var value:String = (pos >= 0) ? line.substring(pos + 1) : '';
            value = value.trim();

            if (key == 'newmtl') {
                // New material
                info = {name: value};
                materialsInfo[value] = info;
            } else {
                if (key == 'ka' || key == 'kd' || key == 'ks' || key == 'ke') {
                    var ss:Array<String> = value.split(delimiter_pattern, 3);
                    info[key] = [Std.parseFloat(ss[0]), Std.parseFloat(ss[1]), Std.parseFloat(ss[2])];
                } else {
                    info[key] = value;
                }
            }
        }

        var materialCreator:MaterialCreator = new MaterialCreator(this.resourcePath != null ? this.resourcePath : path, this.materialOptions);
        materialCreator.setCrossOrigin(this.crossOrigin);
        materialCreator.setManager(this.manager);
        materialCreator.setMaterials(materialsInfo);
        return materialCreator;
    }
}

/**
 * Create a new MTLLoader.MaterialCreator
 * @param baseUrl - Url relative to which textures are loaded
 * @param options - Set of options on how to construct the materials
 *                  side: Which side to apply the material
 *                        FrontSide (default), THREE.BackSide, THREE.DoubleSide
 *                  wrap: What type of wrapping to apply for textures
 *                        RepeatWrapping (default), THREE.ClampToEdgeWrapping, THREE.MirroredRepeatWrapping
 *                  normalizeRGB: RGBs need to be normalized to 0-1 from 0-255
 *                                Default: false, assumed to be already normalized
 *                  ignoreZeroRGBs: Ignore values of RGBs (Ka,Kd,Ks) that are all 0's
 *                                    Default: false
 * @constructor
 */
class MaterialCreator {
    public var baseUrl:String;
    public var options:Dynamic;
    public var materialsInfo:Dynamic;
    public var materials:Dynamic;
    public var materialsArray:Array<Dynamic>;
    public var nameLookup:Dynamic;

    public var crossOrigin:String;
    public var manager:Loader;
    public var side:FrontSide;
    public var wrap:RepeatWrapping;

    public function new(baseUrl:String = '', options:Dynamic = {}) {
        this.baseUrl = baseUrl;
        this.options = options;
        this.materialsInfo = {};
        this.materials = {};
        this.materialsArray = [];
        this.nameLookup = {};

        this.crossOrigin = 'anonymous';
        this.side = (options.side != null) ? options.side : FrontSide;
        this.wrap = (options.wrap != null) ? options.wrap : RepeatWrapping;
    }

    public function setCrossOrigin(value:String):MaterialCreator {
        this.crossOrigin = value;
        return this;
    }

    public function setManager(value:Loader):Void {
        this.manager = value;
    }

    public function setMaterials(materialsInfo:Dynamic):Void {
        this.materialsInfo = this.convert(materialsInfo);
        this.materials = {};
        this.materialsArray = [];
        this.nameLookup = {};
    }

    public function convert(materialsInfo:Dynamic):Dynamic {
        if (this.options == null) return materialsInfo;

        var converted:Dynamic = {};

        for (mn in materialsInfo) {
            // Convert materials info into normalized form based on options

            var mat:Dynamic = materialsInfo[mn];

            var covmat:Dynamic = {};

            converted[mn] = covmat;

            for (prop in mat) {
                // ...

                // Diffuse color (color under white light) using RGB values
                // ...
            }
        }

        return converted;
    }

    // ...
}