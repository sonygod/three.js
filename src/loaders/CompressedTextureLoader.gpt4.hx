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

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:Array<String>, onLoad:CompressedTexture -> Void, onProgress:Dynamic -> Void, onError:Dynamic -> Void):CompressedTexture {
        var scope = this;
        var images:Array<Dynamic> = [];
        var texture = new CompressedTexture();
        var loader = new FileLoader(this.manager);

        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(scope.withCredentials);

        var loaded:Int = 0;

        function loadTexture(i:Int):Void {
            loader.load(url[i], function(buffer:Dynamic):Void {
                var texDatas = scope.parse(buffer, true);

                images[i] = {
                    width: texDatas.width,
                    height: texDatas.height,
                    format: texDatas.format,
                    mipmaps: texDatas.mipmaps
                };

                loaded += 1;

                if (loaded == 6) {
                    if (texDatas.mipmapCount == 1) {
                        texture.minFilter = LinearFilter;
                    }

                    texture.image = images;
                    texture.format = texDatas.format;
                    texture.needsUpdate = true;

                    if (onLoad != null) {
                        onLoad(texture);
                    }
                }
            }, onProgress, onError);
        }

        if (url != null && url.length > 0) {
            for (i in 0...url.length) {
                loadTexture(i);
            }
        } else {
            // compressed cubemap texture stored in a single DDS file
            loader.load(url[0], function(buffer:Dynamic):Void {
                var texDatas = scope.parse(buffer, true);

                if (texDatas.isCubemap) {
                    var faces = Std.int(texDatas.mipmaps.length / texDatas.mipmapCount);

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

                if (onLoad != null) {
                    onLoad(texture);
                }
            }, onProgress, onError);
        }

        return texture;
    }

    // Abstract method to be implemented by subclasses
    public function parse(buffer:Dynamic, loadMipmaps:Bool):Dynamic {
        return null; // Placeholder implementation
    }
}