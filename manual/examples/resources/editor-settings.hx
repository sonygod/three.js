package three.js.manual.examples.resources;

import js.html.URL;
import js.Browser;
import js.html.Window;

class EditorSettings {

  static function dirname(path:String):String {
    var ndx = path.lastIndexOf('/');
    return path.substring(0, ndx + 1);
  }

  static function getPrefix(url:String):String {
    var u = new URL(url, Browser.window.location.href);
    var prefix = u.origin + dirname(u.pathname);
    return prefix;
  }

  static function getRootPrefix(url:String):String {
    var u = new URL(url, Browser.window.location.href);
    return u.origin;
  }

  static function removeDotDotSlash(url:String):String {
    var parts:Array<String> = url.split('/');
    while (true) {
      var dotDotNdx = parts.indexOf('../');
      if (dotDotNdx < 0) break;
      parts.splice(dotDotNdx - 1, 2);
    }
    var newUrl = parts.join('/');
    return newUrl;
  }

  static function fixSourceLinks(url:String, source:String):String {
    var srcRE = ~/src=("|')(.*?)("|")/g;
    var linkRE = ~/href=("|')(.*?)("|")/g;
    var imageSrcRE = ~/((?:image|img)\.src = )("|')(.*?)("|")/g;
    var loaderLoadRE = ~/loader\.load[a-z]*\(\s*)('|")(.*?)('|")/ig;
    var loaderArrayLoadRE = ~/loader\.load[a-z]*\(\[([\s\S]*?)\]/ig;
    var loadFileRE = ~/loadFile\s*\(\s*)('|")(.*?)('|")/ig;
    var threejsUrlRE = ~/.*?("|")([^"']*?)("|")([^'"]*?)(\/\*\s+threejs\.org:\s+url\s+\*\/)/ig;
    var arrayLineRE = ~/^\s*["|']([\s\S]*?)["|']$/;
    var urlPropRE = ~/url:\s*("|")(.*?)("|")/g;
    var workerRE = ~/new\s+Worker\s*\(\s*)('|")(.*?)('|")/g;
    var importScriptsRE = ~/importScripts\s*\(\s*)('|")(.*?)('|")/g;
    var moduleRE = ~/import.*?("|")(.*?)("|")/g;
    var prefix = getPrefix(url);
    var rootPrefix = getRootPrefix(url);

    function addCorrectPrefix(url:String):String {
      return (url.startsWith('/')) ? rootPrefix + url : removeDotDotSlash((prefix + url).replace ~/\/\.\/\/g, '/');
    }

    function addPrefix(url:String):String {
      return (url.indexOf('://') < 0 && !url.startsWith('data:') && url.charAt(0) != '?')
        ? removeDotDotSlash(addCorrectPrefix(url))
        : url;
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
        var m:Array<String> = arrayLineRE.match(line);
        return m != null ? m[1] + addPrefix(m[2]) + m[3] : line;
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

  static function extraHTMLParsing(html:String /*, htmlParts:Object<String, HTMLPart> */):String {
    return html;
  }

  static async function fixJSForCodeSite(js:String):String {
    var moduleRE = ~/import.*?("|")(.*?)("|")/g;

    var version:String = null;

    if (version == null) {
      try {
        var res = await Browser.fetch('https://raw.githubusercontent.com/mrdoob/three.js/master/package.json');
        var json = await res.json();
        version = json.version;
      } catch (e:Any) {
        trace(e);
      }
    }

    function addVersion(href:String):String {
      if (href.startsWith(Browser.window.location.origin)) {
        if (href.includes('/build/three.module.js')) {
          return 'https://cdn.jsdelivr.net/npm/three@$version';
        } else if (href.includes('/examples/jsm/')) {
          var url = new URL(href);
          return 'https://cdn.jsdelivr.net/npm/three@$version${url.pathname}${url.search}${url.hash}';
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

  public static var lessonEditorSettings:Any = {
    extraHTMLParsing: extraHTMLParsing,
    fixSourceLinks: fixSourceLinks,
    fixJSForCodeSite: fixJSForCodeSite,
    runOnResize: false,
    lessonSettings: {
      glDebug: false
    },
    tags: ['three.js'],
    name: 'three.js',
    icon: '/files/icon.svg'
  };
}