package three.js.examples.jsm.loaders;

import three.DataTextureLoader;
import three.LinearFilter;
import three.LinearMipmapLinearFilter;

import js.lib.utif.UTIF;

class TIFFLoader extends DataTextureLoader
{
    public function new(manager:Dynamic)
    {
        super(manager);
    }

    public function parse(buffer:Dynamic):Dynamic
    {
        var ifds:Array<Dynamic> = UTIF.decode(buffer);
        UTIF.decodeImage(buffer, ifds[0]);
        var rgba:Array<Int> = UTIF.toRGBA8(ifds[0]);

        return {
            width: ifds[0].width,
            height: ifds[0].height,
            data: rgba,
            flipY: true,
            magFilter: LinearFilter,
            minFilter: LinearMipmapLinearFilter
        };
    }
}