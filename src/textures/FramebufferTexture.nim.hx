import Texture from './Texture.hx';
import NearestFilter from '../constants.hx';

class FramebufferTexture extends Texture {

    public var isFramebufferTexture:Bool = true;

    public var magFilter:Int = NearestFilter;
    public var minFilter:Int = NearestFilter;

    public var generateMipmaps:Bool = false;

    public var needsUpdate:Bool = true;

    public function new(width:Int, height:Int) {
        super({ width, height });
    }

}

export default FramebufferTexture;