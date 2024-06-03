import js.html.FileReader;
import js.html.Blob;
import js.html.File;
import js.html.XMLHttpRequest;

class TDSLoader {
    public var debug:Bool;
    public var group:Group;
    public var materials:Array<MeshPhongMaterial>;
    public var meshes:Array<Mesh>;

    public function new() {
        this.debug = false;
        this.group = null;
        this.materials = [];
        this.meshes = [];
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var path = (this.path === '') ? LoaderUtils.extractUrlBase(url) : this.path;

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.responseType = "blob";
        xhr.onload = function(e) {
            var reader = new FileReader();
            reader.onload = function(event) {
                var data = event.target.result;
                try {
                    onLoad(scope.parse(data, path));
                } catch (e) {
                    if (onError) {
                        onError(e);
                    } else {
                        trace(e);
                    }
                }
            };
            reader.readAsArrayBuffer(xhr.response);
        };
        xhr.onerror = onError;
        xhr.send();
    }

    public function parse(data:Dynamic, path:String):Group {
        this.group = new Group();
        this.materials = [];
        this.meshes = [];

        this.readFile(data, path);

        for (i in 0...this.meshes.length) {
            this.group.add(this.meshes[i]);
        }

        return this.group;
    }

    // The rest of the methods would need to be implemented similarly
}