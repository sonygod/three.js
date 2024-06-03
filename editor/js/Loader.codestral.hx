import three.THREE;
import three.loaders.TGALoader;
import editor.commands.AddObjectCommand;
import editor.LoaderUtils;
import sys.io.File;
import three.loaders.fflate.FFlate;

class Loader {
    private var editor:Dynamic;
    private var texturePath:String;
    private var scope:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.texturePath = '';
        this.scope = this;
    }

    public function loadItemList(items:Array<File>) {
        LoaderUtils.getFilesFromItemList(items, function(files:Array<File>, filesMap:haxe.ds.StringMap) {
            scope.loadFiles(files, filesMap);
        });
    }

    public function loadFiles(files:Array<File>, filesMap:haxe.ds.StringMap) {
        if (files.length > 0) {
            filesMap = filesMap ? filesMap : LoaderUtils.createFilesMap(files);

            var manager = new THREE.LoadingManager();
            manager.setURLModifier(function(url:String) {
                url = url.replace(/\^\(\.\?\/)/, ''); // remove './'

                var file = filesMap.get(url);

                if (file) {
                    trace('Loading ' + url);
                    return URL.createObjectURL(file);
                }

                return url;
            });

            manager.addHandler(/\.tga$/i, new TGALoader());

            for (var i in 0...files.length) {
                scope.loadFile(files[i], manager);
            }
        }
    }

    public function loadFile(file:File, manager:THREE.LoadingManager) {
        var filename = file.path.split('/').pop();
        var extension = filename.split('.').pop().toLowerCase();

        var reader = new FileReader();
        reader.onProgress = function(event) {
            var size = '(' + editor.utils.formatNumber(Math.floor(event.loaded / 1000)) + ' KB)';
            var progress = Math.floor((event.loaded / event.total) * 100) + '%';

            trace('Loading ' + filename + ' ' + size + ' ' + progress);
        };

        switch (extension) {
            // Your cases here...
            // Please note that Haxe does not support dynamic imports, so you may have to refactor this part of the code, or use pre-compiled JavaScript libraries.

            default:
                trace('Unsupported file format (' + extension + ').');
        }
    }

    // Rest of the functions here...
}