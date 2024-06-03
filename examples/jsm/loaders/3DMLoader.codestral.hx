import js.html.WebWorker;
import js.html.FileReader;
import js.html.Blob;
import js.html.File;
import js.html.ArrayBuffer;
import js.html.XMLHttpRequest;
import js.html.URL;
import js.html.Worker;

import three.BufferGeometryLoader;
import three.CanvasTexture;
import three.ClampToEdgeWrapping;
import three.Color;
import three.DirectionalLight;
import three.DoubleSide;
import three.FileLoader;
import three.LinearFilter;
import three.Line;
import three.LineBasicMaterial;
import three.Loader;
import three.Matrix4;
import three.Mesh;
import three.MeshPhysicalMaterial;
import three.MeshStandardMaterial;
import three.Object3D;
import three.PointLight;
import three.Points;
import three.PointsMaterial;
import three.RectAreaLight;
import three.RepeatWrapping;
import three.SpotLight;
import three.Sprite;
import three.SpriteMaterial;
import three.TextureLoader;

@:keep
class Rhino3dmLoader extends Loader {

    var libraryPath:String;
    var libraryPending:Dynamic;
    var libraryBinary:Dynamic;
    var libraryConfig:Dynamic;

    var url:String;

    var workerLimit:Int;
    var workerPool:Array<Worker>;
    var workerNextTaskID:Int;
    var workerSourceURL:String;
    var workerConfig:Dynamic;

    var materials:Array<Dynamic>;
    var warnings:Array<Dynamic>;

    public function new(manager:Dynamic = null) {
        super(manager);

        libraryPath = '';
        libraryPending = null;
        libraryBinary = null;
        libraryConfig = {};

        url = '';

        workerLimit = 4;
        workerPool = [];
        workerNextTaskID = 1;
        workerSourceURL = '';
        workerConfig = {};

        materials = [];
        warnings = [];
    }

    public function setLibraryPath(path:String):Rhino3dmLoader {
        libraryPath = path;
        return this;
    }

    public function setWorkerLimit(workerLimit:Int):Rhino3dmLoader {
        this.workerLimit = workerLimit;
        return this;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var loader = new FileLoader(manager);
        loader.setPath(path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(requestHeader);

        this.url = url;

        loader.load(url, function(buffer:ArrayBuffer) {
            // Check for an existing task using this buffer. A transferred buffer cannot be transferred
            // again from this thread.
            if (_taskCache.has(buffer)) {
                var cachedTask = _taskCache.get(buffer);
                return cachedTask.promise.then(onLoad).catch(onError);
            }

            decodeObjects(buffer, url)
                .then(function(result) {
                    result.userData.warnings = warnings;
                    onLoad(result);
                })
                .catch(function(e) { onError(e); });
        }, onProgress, onError);
    }

    // rest of the class methods...
}

@:keep
class Rhino3dmWorker {

    var libraryPending:Dynamic;
    var libraryConfig:Dynamic;
    var rhino:Dynamic;
    var taskID:Int;

    public function new() {
        // onmessage function and its helper functions here...
    }
}

// _taskCache and other global variables should be defined here or imported if they are defined elsewhere