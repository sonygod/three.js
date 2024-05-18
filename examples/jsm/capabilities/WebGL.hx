package three.js.examples.jm.capabilities;

import js.Browser;
import js.html.CanvasElement;
import js.html.WebGLRenderingContext;
import js.html.WebGL2RenderingContext;

class WebGL {
  public static function isWebGLAvailable():Bool {
    try {
      var canvas:CanvasElement = Browser.document.createCanvasElement();
      return (window.WebGLRenderingContext != null && (canvas.getContext('webgl') != null || canvas.getContext('experimental-webgl') != null));
    } catch (e:Dynamic) {
      return false;
    }
  }

  public static function isWebGL2Available():Bool {
    try {
      var canvas:CanvasElement = Browser.document.createCanvasElement();
      return (window.WebGL2RenderingContext != null && canvas.getContext('webgl2') != null);
    } catch (e:Dynamic) {
      return false;
    }
  }

  public static function isColorSpaceAvailable(colorSpace:String):Bool {
    try {
      var canvas:CanvasElement = Browser.document.createCanvasElement();
      var ctx:WebGL2RenderingContext = window.WebGL2RenderingContext != null ? canvas.getContext('webgl2') : null;
      ctx.drawingBufferColorSpace = colorSpace;
      return ctx.drawingBufferColorSpace == colorSpace;
    } catch (e:Dynamic) {
      return false;
    }
  }

  public static function getWebGLErrorMessage():js.html.Element {
    return getErrorMessage(1);
  }

  public static function getWebGL2ErrorMessage():js.html.Element {
    return getErrorMessage(2);
  }

  public static function getErrorMessage(version:Int):js.html.Element {
    var names:Array<String> = [null, 'WebGL', 'WebGL 2'];
    var contexts:Array<Dynamic> = [null, window.WebGLRenderingContext, window.WebGL2RenderingContext];

    var message:String = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';

    var element:js.html.Element = Browser.document.createElement('div');
    element.id = 'webglmessage';
    element.style.fontFamily = 'monospace';
    element.style.fontSize = '13px';
    element.style.fontWeight = 'normal';
    element.style.textAlign = 'center';
    element.style.background = '#fff';
    element.style.color = '#000';
    element.style.padding = '1.5em';
    element.style.width = '400px';
    element.style.margin = '5em auto 0';

    if (contexts[version] != null) {
      message = message.replace('$0', 'graphics card');
    } else {
      message = message.replace('$0', 'browser');
    }

    message = message.replace('$1', names[version]);

    element.innerHTML = message;

    return element;
  }
}