package three.js.manual.examples.resources;

class EditorSettings {
  static function dirname(path:String):String {
    var ndx:Int = path.lastIndexOf('/');
    return path.substring(0, ndx + 1);
  }

  static function getPrefix(url:String):String {
    var u:URL = new URL(url, js.Browser.window.location.href);
    var prefix:String = u.origin + dirname(u.pathname);
    return prefix;
  }

  static function getRootPrefix(url:String):String {
    var u:URL = new URL(url, js.Browser.window.location.href);
    return u.origin;
  }

  static function removeDotDotSlash(url:String):String {
    var parts:Array<String> = url.split('/');
    while (true) {
      var dotDotNdx:Int = parts.indexOf('..');
      if (dotDotNdx < 0) {
        break;
      }
      parts.splice(dotDotNdx - 1, 2);
    }
    var newUrl:String = parts.join('/');
    return newUrl;
  }

  static function fixSourceLinks(url:String, source:String):String {
    var srcRE:EReg = ~/src=("|')(.*?)(")()/g;
    var linkRE:EReg = ~/href=("|')(.*?)(")()/g;
    var imageSrcRE:EReg = ~/((?:image|img)\.src = )("|')(.*?)(")()/g;
    var loaderLoadRE:EReg = ~/loader\.load[a-z]*\(\s*)('|")(.*?)('|")/ig;
    var loaderArrayLoadRE:EReg = ~/loader\.load[a-z]*\(\[([\s\S]*?)\]/ig;
    var loadFileRE:EReg = ~/loadFile\s*\(\s*)('|")(.*?)('|")/ig;
    var threejsUrlRE:EReg = ~/(.*?)('|")([^"']*?)('|")([^'"]*?)(\/\*\s+threejs.org:\s+url\s+\*\/)/ig;
    var arrayLineRE:EReg = ~/^(\s*["|'])([\s\S]*?)(["|']*$)/;
    var urlPropRE:EReg = ~/url:\s*("|")(.*?)("|")/g;
    var workerRE:EReg = ~/new\s+Worker\s*\(\s*)('|")(.*?)('|")/g;
    var importScriptsRE:EReg = ~/importScripts\s*\(\s*)('|")(.*?)('|")/g;
    var moduleRE:EReg = ~/import.*?)("|")(.*?)("|")/g;

    var prefix:String = getPrefix(url);
    var rootPrefix:String = getRootPrefix(url);

    function addCorrectPrefix(url:String):String {
      return (url.startsWith('/')) ? rootPrefix + url : removeDotDotSlash((prefix + url).replace(/\/\.\//g, '/'));
    }

    function addPrefix(url:String):String {
      return url.indexOf('://') < 0 && !url.startsWith('data:') && url.charAt(0) != '?' ? removeDotDotSlash(addCorrectPrefix(url)) : url;
    }

    function makeLinkFDedQuotes(match:String, fn:String, q1:String, url:String, q2:String):String {
      return fn + q1 + addPrefix(url) + q2;
    }

    function makeTaggedFDedQuotes(match:String, start:String, q1:String, url:String, q2:String, suffix:String):String {
      return start + q1 + addPrefix(url) + q2 + suffix;
    }

    function makeFDedQuotesModule(match:String, start:String, q1:String, url:String, q2:String):String {
      return start + q1 + (url.startsWith('.') ? addPrefix(url) : url) + q2;
    }

    function makeArrayLinksFDed(match:String, prefix:String, arrayStr:String, suffix:String):String {
      var lines:Array<String> = arrayStr.split(',').map(function(line:String):String {
        var m:ERegMatch = arrayLineRE.match(line);
        return m ? m.matched(1) + addPrefix(m.matched(2)) + m.matched(3) : line;
      });
      return prefix + lines.join(',') + suffix;
    }

    source = source.replace(srcRE, makeTaggedFDedQuotes);
    source = source.replace(linkRE, makeTaggedFDedQuotes);
    source = source.replace(imageSrcRE, makeTaggedFDedQuotes);
    source = source.replace(urlPropRE, makeLinkFDedQuotes);
    source = source.replace(loadFileRE, makeLinkFDedQuotes);
    source = source.replace(loaderLoadRE, makeLinkFDedQuotes);
    source = source.replace(workerRE, makeLinkFDedQuotes);
    source = source.replace(importScriptsRE, makeLinkFDedQuotes);
    source = source.replace(loaderArrayLoadRE, makeArrayLinksFDed);
    source = source.replace(threejsUrlRE, makeTaggedFDedQuotes);
    source = source.replace(moduleRE, makeFDedQuotesModule);

    return source;
  }

  static function extraHTMLParsing(html:String /*, htmlParts:Object<String, HTMLPart>*/):String {
    return html;
  }

  static function fixJSForCodeSite(js:String):String {
    var moduleRE:EReg = ~/import.*?)("|")(.*?)("|")/g;

    if (!version) {
      try {
        var res:js.lib.Promise<js.html.Response> = js.Browser.fetch('https://raw.githubusercontent.com/mrdoob/three.js/master/package.json');
        var json:Dynamic = res.json();
        version = json.version;
      } catch (e:Dynamic) {
        console.error(e);
      }
    }

    function addVersion(href:String):String {
      if (href.startsWith(window.location.origin)) {
        if (href.includes('/build/three.module.js')) {
          return 'https://cdn.jsdelivr.net/npm/three@${version}';
        } else if (href.includes('/examples/jsm/')) {
          var url:URL = new URL(href);
          return 'https://cdn.jsdelivr.net/npm/three@${version}${url.pathname}${url.search}${url.hash}';
        }
      }
      return href;
    }

    function addVersionToURL(match:String, start:String, q1:String, url:String, q2:String):String {
      return start + q1 + addVersion(url) + q2;
    }

    if (version != null) {
      js = js.replace(moduleRE, addVersionToURL);
    }

    return js;
  }

  public static var lessonEditorSettings:Dynamic = {
    extraHTMLParsing: extraHTMLParsing,
    fixSourceLinks: fixSourceLinks,
    fixJSForCodeSite: fixJSForCodeSite,
    runOnResize: false,
    lessonSettings: {
      glDebug: false,
    },
    tags: ['three.js'],
    name: 'three.js',
    icon: '/files/icon.svg',
  };
}