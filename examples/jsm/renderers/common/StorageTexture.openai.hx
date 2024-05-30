package three.js.examples.jsm.renderers.common;

import js.three.Texture;
import js.three.LinearFilter;

class StorageTexture extends Texture {
    
    public var image : { width : Int, height : Int };
    
    public function new( ?width : Int = 1, ?height : Int = 1 ) {
        super();
        
        image = { width : width, height : height };
        
        magFilter = LinearFilter;
        minFilter = LinearFilter;
        
        isStorageTexture = true;
    }
}