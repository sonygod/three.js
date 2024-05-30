import three.AnimationClip;
import three.BufferGeometry;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;
import three.Vector3;

class MD2Loader extends Loader {

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(buffer:Dynamic) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:Dynamic):BufferGeometry {
        var data = new DataView(buffer);
        // http://tfc.duke.free.fr/coding/md2-specs-en.html
        var header = {};
        var headerNames = [
            'ident', 'version',
            'skinwidth', 'skinheight',
            'framesize',
            'num_skins', 'num_vertices', 'num_st', 'num_tris', 'num_glcmds', 'num_frames',
            'offset_skins', 'offset_st', 'offset_tris', 'offset_frames', 'offset_glcmds', 'offset_end'
        ];
        for (i in 0...headerNames.length) {
            header[headerNames[i]] = data.getInt32(i * 4, true);
        }
        if (header.ident != 844121161 || header.version != 8) {
            trace('Not a valid MD2 file');
            return null;
        }
        if (header.offset_end != data.byteLength) {
            trace('Corrupted MD2 file');
            return null;
        }
        // ... rest of the code ...
        return geometry;
    }
}