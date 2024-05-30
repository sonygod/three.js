package three.js.loaders.mmd;

import three.js.loaders.TextureLoader;
import three.js.loaders.TGALoader;
import three.js.textures.Texture;
import three.js.materials.MMDToonMaterial;
import three.js.utils.Color;
import three.js.utils.SRGBColorSpace;

class MaterialBuilder {
    public var manager:Dynamic;
    public var textureLoader:TextureLoader;
    public var tgaLoader:TGALoader;
    public var crossOrigin:String;
    public var resourcePath:String;

    public function new(manager:Dynamic) {
        this.manager = manager;
        this.textureLoader = new TextureLoader(manager);
        this.tgaLoader = null; // lazy generation
        this.crossOrigin = 'anonymous';
        this.resourcePath = undefined;
    }

    public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function setResourcePath(resourcePath:String):MaterialBuilder {
        this.resourcePath = resourcePath;
        return this;
    }

    public function build(data:Dynamic, geometry:Dynamic, ?onProgress:Void->Void, ?onError:Void->Void):Array<MMDToonMaterial> {
        var materials:Array<MMDToonMaterial> = [];
        var textures:Object = {};

        this.textureLoader.setCrossOrigin(this.crossOrigin);

        for (i in 0...data.metadata.materialCount) {
            var material:Dynamic = data.materials[i];
            var params:Object = { userData: { MMD: {} } };

            if (material.name != undefined) params.name = material.name;

            params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], SRGBColorSpace);
            params.opacity = material.diffuse[3];
            params.specular = new Color().setRGB(material.specular[0], material.specular[1], material.specular[2], SRGBColorSpace);
            params.shininess = material.shininess;
            params.emissive = new Color().setRGB(material.ambient[0], material.ambient[1], material.ambient[2], SRGBColorSpace);
            params.transparent = params.opacity != 1.0;

            // ... (rest of the code)

            materials.push(new MMDToonMaterial(params));
        }

        return materials;
    }

    private function _getTGALoader():TGALoader {
        if (this.tgaLoader == null) {
            if (TGALoader == undefined) {
                throw new Error('THREE.MMDLoader: Import TGALoader');
            }
            this.tgaLoader = new TGALoader(this.manager);
        }
        return this.tgaLoader;
    }

    private function _isDefaultToonTexture(name:String):Bool {
        if (name.length != 10) return false;
        return ~/toon(10|0[0-9])\.bmp/.test(name);
    }

    private function _loadTexture(filePath:String, textures:Object, ?params:Object, ?onProgress:Void->Void, ?onError:Void->Void):Texture {
        // ... (rest of the code)
    }

    private function _getRotatedImage(image:Dynamic):Dynamic {
        // ... (rest of the code)
    }

    private function _checkImageTransparency(map:Dynamic, geometry:Dynamic, groupIndex:Int):Void {
        // ... (rest of the code)
    }
}