import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Image;
import three.core.Color;
import three.core.LoadingManager;
import three.loaders.TextureLoader;
import three.materials.Material;
import three.materials.MeshBasicMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.MeshToonMaterial;
import three.textures.Texture;
import three.utils.SRGBColorSpace;

class MaterialBuilder {
    public var manager: LoadingManager;
    public var textureLoader: TextureLoader;
    public var tgaLoader: dynamic; // assuming TGALoader is a dynamic type
    public var crossOrigin: String;
    public var resourcePath: String;

    public function new(manager: LoadingManager) {
        this.manager = manager;
        this.textureLoader = new TextureLoader(this.manager);
        this.tgaLoader = null;
        this.crossOrigin = 'anonymous';
        this.resourcePath = undefined;
    }

    public function setCrossOrigin(crossOrigin: String): MaterialBuilder {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function setResourcePath(resourcePath: String): MaterialBuilder {
        this.resourcePath = resourcePath;
        return this;
    }

    public function build(data: Dynamic, geometry: Dynamic): Array<MeshToonMaterial> {
        var materials: Array<MeshToonMaterial> = [];
        var textures: Map<String, Texture> = new Map<String, Texture>();

        // similar to the JavaScript code, the rest of the function would be implemented
        // assuming the existence of the necessary classes and methods in Haxe

        return materials;
    }

    private function _getTGALoader(): dynamic {
        // assuming the implementation of _getTGALoader method
    }

    private function _isDefaultToonTexture(name: String): Bool {
        // assuming the implementation of _isDefaultToonTexture method
    }

    private function _loadTexture(filePath: String, textures: Map<String, Texture>, params: Dynamic = null): Texture {
        // assuming the implementation of _loadTexture method
    }

    private function _getRotatedImage(image: Image): js.html.ImageData {
        var canvas: CanvasElement = js.html.Document.createElement("canvas");
        var context: CanvasRenderingContext2D = canvas.getContext("2d");

        var width: Int = image.width;
        var height: Int = image.height;

        canvas.width = width;
        canvas.height = height;

        context.clearRect(0, 0, width, height);
        context.translate(width / 2.0, height / 2.0);
        context.rotate(0.5 * Math.PI);
        context.translate(-width / 2.0, -height / 2.0);
        context.drawImage(image, 0, 0);

        return context.getImageData(0, 0, width, height);
    }

    private function _checkImageTransparency(map: Texture, geometry: Dynamic, groupIndex: Int): Void {
        // assuming the implementation of _checkImageTransparency method
    }
}