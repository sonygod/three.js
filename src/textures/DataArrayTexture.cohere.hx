import js.Browser.Window;
import js.html.CanvasElement;
import js.html.ImageElement;
import js.typed_arrays.ArrayBufferView;
import js.webgl.WebGLRenderingContext;
import js.webgl.WebGLTexture;

class DataArrayTexture extends Texture {
    public var isDataArrayTexture:Bool = true;
    public var image:Image = { data: null, width: 1, height: 1, depth: 1 };
    public var magFilter:Int = NearestFilter;
    public var minFilter:Int = NearestFilter;
    public var wrapR:Int = ClampToEdgeWrapping;
    public var generateMipmaps:Bool = false;
    public var flipY:Bool = false;
    public var unpackAlignment:Int;
    public var layerUpdates:Set<Int> = new Set();

    public function new(data:ArrayBufferView<Dynamic> = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);
        image.data = data;
        image.width = width;
        image.height = height;
        image.depth = depth;
    }

    public function addLayerUpdate(layerIndex:Int) {
        layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates() {
        layerUpdates.clear();
    }
}