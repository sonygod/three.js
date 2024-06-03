import js.html.Loader;
import js.html.FileLoader;
import MeshBuilder;
import AnimationBuilder;
import MMDParser.Parser;
import LoaderUtils;

class MMDLoader extends Loader {

    public var loader:FileLoader;
    public var parser:Parser;
    public var meshBuilder:MeshBuilder;
    public var animationBuilder:AnimationBuilder;
    public var animationPath:String;

    public function new(manager:Dynamic) {
        super(manager);

        loader = new FileLoader(this.manager);
        parser = null;
        meshBuilder = new MeshBuilder(this.manager);
        animationBuilder = new AnimationBuilder();
    }

    public function setAnimationPath(animationPath:String):MMDLoader {
        this.animationPath = animationPath;
        return this;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var builder = meshBuilder.setCrossOrigin(this.crossOrigin);

        var resourcePath = this.resourcePath !== '' ? this.resourcePath :
                           this.path !== '' ? this.path :
                           LoaderUtils.extractUrlBase(url);

        var parser = this._getParser();
        var extractModelExtension = this._extractModelExtension;

        loader.setMimeType(null)
             .setPath(this.path)
             .setResponseType('arraybuffer')
             .setRequestHeader(this.requestHeader)
             .setWithCredentials(this.withCredentials)
             .load(url, function(buffer:ArrayBuffer) {
                 try {
                     var modelExtension = extractModelExtension(buffer);
                     if (modelExtension !== 'pmd' && modelExtension !== 'pmx') {
                         if (onError != null) onError(new Error("Unknown model file extension ." + modelExtension + "."));
                         return;
                     }
                     var data = modelExtension === 'pmd' ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
                     onLoad(builder.build(data, resourcePath, onProgress, onError));
                 } catch (e:Dynamic) {
                     if (onError != null) onError(e);
                 }
             }, onProgress, onError);
    }

    public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var builder = this.animationBuilder;
        this.loadVMD(url, function(vmd:Dynamic) {
            onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
        }, onProgress, onError);
    }

    public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var scope = this;
        this.load(modelUrl, function(mesh:Dynamic) {
            scope.loadAnimation(vmdUrl, mesh, function(animation:Dynamic) {
                onLoad({mesh: mesh, animation: animation});
            }, onProgress, onError);
        }, onProgress, onError);
    }

    public function loadPMD(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var parser = this._getParser();
        loader.setMimeType(null)
              .setPath(this.path)
              .setResponseType('arraybuffer')
              .setRequestHeader(this.requestHeader)
              .setWithCredentials(this.withCredentials)
              .load(url, function(buffer:ArrayBuffer) {
                  try {
                      onLoad(parser.parsePmd(buffer, true));
                  } catch (e:Dynamic) {
                      if (onError != null) onError(e);
                  }
              }, onProgress, onError);
    }

    public function loadPMX(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var parser = this._getParser();
        loader.setMimeType(null)
              .setPath(this.path)
              .setResponseType('arraybuffer')
              .setRequestHeader(this.requestHeader)
              .setWithCredentials(this.withCredentials)
              .load(url, function(buffer:ArrayBuffer) {
                  try {
                      onLoad(parser.parsePmx(buffer, true));
                  } catch (e:Dynamic) {
                      if (onError != null) onError(e);
                  }
              }, onProgress, onError);
    }

    public function loadVMD(url:Dynamic, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var urls = Array.isArray(url) ? url : [url];
        var vmds = [];
        var vmdNum = urls.length;
        var parser = this._getParser();

        loader.setMimeType(null)
              .setPath(this.animationPath)
              .setResponseType('arraybuffer')
              .setRequestHeader(this.requestHeader)
              .setWithCredentials(this.withCredentials);

        for (var i = 0; i < urls.length; i++) {
            var url = urls[i];
            loader.load(url, function(buffer:ArrayBuffer) {
                try {
                    vmds.push(parser.parseVmd(buffer, true));
                    if (vmds.length === vmdNum) onLoad(parser.mergeVmds(vmds));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
        }
    }

    public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var parser = this._getParser();
        loader.setMimeType(isUnicode ? null : 'text/plain; charset=shift_jis')
              .setPath(this.animationPath)
              .setResponseType('text')
              .setRequestHeader(this.requestHeader)
              .setWithCredentials(this.withCredentials)
              .load(url, function(text:String) {
                  try {
                      onLoad(parser.parseVpd(text, true));
                  } catch (e:Dynamic) {
                      if (onError != null) onError(e);
                  }
              }, onProgress, onError);
    }

    private function _extractModelExtension(buffer:ArrayBuffer):String {
        var decoder = new js.html.TextDecoder('utf-8');
        var bytes = new js.html.Uint8Array(buffer, 0, 3);
        return decoder.decode(bytes).toLowerCase();
    }

    private function _getParser():Parser {
        if (this.parser == null) {
            this.parser = new Parser();
        }
        return this.parser;
    }
}