import js.html.Window;
import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.HTMLDivElement;
import js.html.navigator.GPU;

class GPUShaderStage {
  public static var VERTEX:Int = 1;
  public static var FRAGMENT:Int = 2;
  public static var COMPUTE:Int = 4;
}

class WebGPU {
  static var isAvailable:Bool = Browser.navigator.gpu != null;

  static function init() {
    if (Window.window != null && isAvailable) {
      isAvailable = Browser.navigator.gpu.requestAdapter().then(adapter => {
        return adapter != null;
      });
    }
  }

  static function isAvailable():Bool {
    return isAvailable;
  }

  static function getStaticAdapter():Dynamic {
    return isAvailable;
  }

  static function getErrorMessage():Element {
    var message = 'Your browser does not support <a href="https://gpuweb.github.io/gpuweb/" style="color:blue">WebGPU</a> yet';
    var element = Document.window.document.createElement('div');
    element.id = 'webgpumessage';
    element.style.fontFamily = 'monospace';
    element.style.fontSize = '13px';
    element.style.fontWeight = 'normal';
    element.style.textAlign = 'center';
    element.style.background = '#fff';
    element.style.color = '#000';
    element.style.padding = '1.5em';
    element.style.maxWidth = '400px';
    element.style.margin = '5em auto 0';
    element.innerHTML = message;
    return element;
  }
}

WebGPU.init();

class WebGPUMain {
  static function main() {
    if (!WebGPU.isAvailable()) {
      Document.window.document.body.appendChild(WebGPU.getErrorMessage());
    }
  }
}

WebGPUMain.main();