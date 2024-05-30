import js.Lib;
import js.three.LoaderUtils;
import js.three.FileLoader;
import js.three.Loader;
import js.three.MeshBuilder;
import js.three.AnimationBuilder;
import js.three.MMDParser.Parser;

class MMDLoader extends Loader {

  public var loader:FileLoader;
  public var parser:Parser;
  public var meshBuilder:MeshBuilder;
  public var animationBuilder:AnimationBuilder;

  public function new(manager:js.three.LoadingManager) {
    super(manager);
    this.loader = new FileLoader(this.manager);
    this.parser = null;
    this.meshBuilder = new MeshBuilder(this.manager);
    this.animationBuilder = new AnimationBuilder();
  }

  public function setAnimationPath(animationPath:String):MMDLoader {
    this.animationPath = animationPath;
    return this;
  }

  public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
    var builder = this.meshBuilder.setCrossOrigin(this.crossOrigin);
    var resourcePath:String;

    if (this.resourcePath != '') {
      resourcePath = this.resourcePath;
    } else if (this.path != '') {
      resourcePath = this.path;
    } else {
      resourcePath = LoaderUtils.extractUrlBase(url);
    }

    var parser = this._getParser();
    var extractModelExtension = this._extractModelExtension;

    this.loader
      .setMimeType(null)
      .setPath(this.path)
      .setResponseType('arraybuffer')
      .setRequestHeader(this.requestHeader)
      .setWithCredentials(this.withCredentials)
      .load(url, function(buffer:ArrayBuffer) {
        try {
          var modelExtension = extractModelExtension(buffer);

          if (modelExtension != 'pmd' && modelExtension != 'pmx') {
            if (onError != null) onError(new Error('THREE.MMDLoader: Unknown model file extension .' + modelExtension + '.'));
            return;
          }

          var data = modelExtension == 'pmd' ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
          onLoad(builder.build(data, resourcePath, onProgress, onError));
        } catch (e:Dynamic) {
          if (onError != null) onError(e);
        }
      }, onProgress, onError);
  }

  public function loadAnimation(url:String, object:Dynamic, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
    var builder = this.animationBuilder;

    this.loadVMD(url, function(vmd:Dynamic) {
      onLoad(object.isCamera
        ? builder.buildCameraAnimation(vmd)
        : builder.build(vmd, object));
    }, onProgress, onError);
  }

  public function loadWithAnimation(modelUrl:String, vmdUrl:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
    var scope = this;

    this.load(modelUrl, function(mesh:Dynamic) {
      scope.loadAnimation(vmdUrl, mesh, function(animation:Dynamic) {
        onLoad({
          mesh: mesh,
          animation: animation
        });
      }, onProgress, onError);
    }, onProgress, onError);
  }

  public function loadPMD(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
    var parser = this._getParser();

    this.loader
      .setMimeType(null)
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

    this.loader
      .setMimeType(null)
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

  public function loadVMD(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
    var urls = Array.isArray(url) ? url : [url];
    var vmds = [];
    var vmdNum = urls.length;

    var parser = this._getParser();

    this.loader
      .setMimeType(null)
      .setPath(this.animationPath)
      .setResponseType('arraybuffer')
      .setRequestHeader(this.requestHeader)
      .setWithCredentials(this.withCredentials);

    for (i in 0...urls.length) {
      this.loader.load(urls[i], function(buffer:ArrayBuffer) {
        try {
          vmds.push(parser.parseVmd(buffer, true));

          if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
        } catch (e:Dynamic) {
          if (onError != null) onError(e);
        }
      }, onProgress, onError);
    }
  }

  public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
    var parser = this._getParser();

    this.loader
      .setMimeType(isUnicode ? null : 'text/plain; charset=shift_jis')
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
    var decoder = new TextDecoder('utf-8');
    var bytes = new Uint8Array(buffer, 0, 3);
    return decoder.decode(bytes).toLowerCase();
  }

  private function _getParser():Parser {
    if (this.parser == null) {
      this.parser = new Parser();
    }

    return this.parser;
  }

}