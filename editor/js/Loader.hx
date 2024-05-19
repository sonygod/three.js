package three.js.editor.js;

import three.js.THREE;

class Loader {
    public var texturePath:String;
    public var editor:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
    }

    public function loadItemList(items:Array<Dynamic>) {
        LoaderUtils.getFilesFromItemList(items, function(files:Array<Dynamic>, filesMap:Dynamic) {
            loadFiles(files, filesMap);
        });
    }

    public function loadFiles(files:Array<Dynamic>, filesMap:Dynamic) {
        if (files.length > 0) {
            filesMap = filesMap || LoaderUtils.createFilesMap(files);
            var manager:THREE.LoadingManager = new THREE.LoadingManager();
            manager.setURLModifier(function(url:String) {
                url = url.replace(/^(\.?\/)/, ''); // remove './'
                var file:Dynamic = filesMap[url];
                if (file != null) {
                    console.log('Loading', url);
                    return URL.createObjectURL(file);
                }
                return url;
            });
            manager.addHandler(/\.tga$/i, new TGALoader());
            for (i in 0...files.length) {
                loadFile(files[i], manager);
            }
        }
    }

    public function loadFile(file:Dynamic, manager:THREE.LoadingManager) {
        var filename:String = file.name;
        var extension:String = filename.split('.').pop().toLowerCase();

        switch (extension) {
            case '3dm':
                // ...
                break;
            case '3ds':
                // ...
                break;
            // ...
        }
    }

    // ...
}

// ...

class AddObjectCommand {
    public var editor:Dynamic;
    public var object:THREE.Object3D;

    public function new(editor:Dynamic, object:THREE.Object3D) {
        this.editor = editor;
        this.object = object;
    }
}

// ...