package three.loaders;

import three.constants.LinearFilter;
import three.loaders.FileLoader;
import three.textures.CompressedTexture;
import three.loaders.Loader;

class CompressedTextureLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:Array<String>, onLoad:CompressedTexture->Void, onProgress:Float->Void, onError:String->Void):CompressedTexture {
        var scope = this;
        var images:Array<Dynamic> = [];
        var texture = new CompressedTexture();

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        var loaded:Int = 0;

        function loadTexture(i:Int) {
            loader.load(url[i], function(buffer:ArrayBuffer) {
                var texDatas:Dynamic = scope.parse(buffer, true);

                images[i] = {
                    width: texDatas.width,
                    height: texDatas.height,
                    format: texDatas.format,
                    mipmaps: texDatas.mipmaps
                };

                loaded++;

                if (loaded == 6) {
                    if (texDatas.mipmapCount == 1) texture.minFilter = LinearFilter;

                    texture.image = images;
                    texture.format = texDatas.format;
                    texture.needsUpdate = true;

                    if (onLoad != null) onLoad(texture);
                }
            }, onProgress, onError);
        }

        if (url.length > 1) {
            for (i in 0...url.length) {
                loadTexture(i);
            }
        } else {
            loader.load(url[0], function(buffer:ArrayBuffer) {
                var texDatas:Dynamic = scope.parse(buffer, true);

                if (texDatas.isCubemap) {
                    var faces:Int = texDatas.mipmaps.length / texDatas.mipmapCount;

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
}