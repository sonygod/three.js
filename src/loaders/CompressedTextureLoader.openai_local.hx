import three.constants.LinearFilter;
import three.loaders.FileLoader;
import three.textures.CompressedTexture;
import three.loaders.Loader;

/**
 * Abstract Base class to block based textures loader (dds, pvr, ...)
 *
 * Sub classes have to implement the parse() method which will be used in load().
 */
class CompressedTextureLoader extends Loader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:Dynamic, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):CompressedTexture {
        var scope = this;
        var images:Array<Dynamic> = [];
        var texture = new CompressedTexture();
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(scope.withCredentials);

        var loaded = 0;

        function loadTexture(i:Int) {
            loader.load(url[i], function(buffer:Dynamic) {
                var texDatas = scope.parse(buffer, true);
                images[i] = {
                    width: texDatas.width,
                    height: texDatas.height,
                    format: texDatas.format,
                    mipmaps: texDatas.mipmaps
                };

                loaded += 1;

                if (loaded == 6) {
                    if (texDatas.mipmapCount == 1) texture.minFilter = LinearFilter;
                    texture.image = images;
                    texture.format = texDatas.format;
                    texture.needsUpdate = true;
                    if (onLoad != null) onLoad(texture);
                }
            }, onProgress, onError);
        }

        if (Type.typeof(url) == TInst(Array)) {
            for (i in 0...url.length) {
                loadTexture(i);
            }
        } else {
            loader.load(url, function(buffer:Dynamic) {
                var texDatas = scope.parse(buffer, true);
                if (texDatas.isCubemap) {
                    var faces = Math.floor(texDatas.mipmaps.length / texDatas.mipmapCount);
                    for (f in 0...faces) {
                        images[f] = { mipmaps: [] };
                        for (i in 0...texDatas.mipmapCount) {
                            images[f].mipmaps.push(texDatas.mipmaps[f * texDatas.mipmapCount + i]);
                            images[f].format = texDatas.format;
                            images[f].width = texDatas.width;
                            images[f].height = texDatas.height;
                        }
                    }
                    texture.image = images;
                } else {
                    texture.image.width = texDatas.width;
                    texture.image.height = texDatas.height;
                    texture.mipmaps = texDatas.mipmaps;
                }

                if (texDatas.mipmapCount == 1) {
                    texture.minFilter = LinearFilter;
                }

                texture.format = texDatas.format;
                texture.needsUpdate = true;

                if (onLoad != null) onLoad(texture);
            }, onProgress, onError);
        }

        return texture;
    }

    // The parse method must be implemented by subclasses
    public function parse(buffer:Dynamic, loadMipmaps:Bool):Dynamic {
        throw 'Subclasses must implement this method.';
    }
}