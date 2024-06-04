class LessonEditorSettings {
  public var extraHTMLParsing: (html:String) -> String;
  public var fixSourceLinks: (url:String, source:String) -> String;
  public var fixJSForCodeSite: (js:String) -> String;
  public var runOnResize: Bool;
  public var lessonSettings: {glDebug:Bool};
  public var tags: Array<String>;
  public var name: String;
  public var icon: String;

  public function new(extraHTMLParsing: (html:String) -> String, fixSourceLinks: (url:String, source:String) -> String, fixJSForCodeSite: (js:String) -> String, runOnResize: Bool, lessonSettings: {glDebug:Bool}, tags: Array<String>, name: String, icon: String) {
    this.extraHTMLParsing = extraHTMLParsing;
    this.fixSourceLinks = fixSourceLinks;
    this.fixJSForCodeSite = fixJSForCodeSite;
    this.runOnResize = runOnResize;
    this.lessonSettings = lessonSettings;
    this.tags = tags;
    this.name = name;
    this.icon = icon;
  }
}

class Main {
  static function main() {
    var version:String;
    var lessonEditorSettings = new LessonEditorSettings(
      extraHTMLParsing,
      fixSourceLinks,
      fixJSForCodeSite,
      false,
      {glDebug:false},
      ["three.js"],
      "three.js",
      "/files/icon.svg"
    );
    js.Browser.window.lessonEditorSettings = lessonEditorSettings;
  }

  static function dirname(path:String):String {
    var ndx = path.lastIndexOf("/");
    return path.substring(0, ndx + 1);
  }

  static function getPrefix(url:String):String {
    var u = new js.html.URL(url, js.Browser.window.location.href);
    var prefix = u.origin + dirname(u.pathname);
    return prefix;
  }

  static function getRootPrefix(url:String):String {
    var u = new js.html.URL(url, js.Browser.window.location.href);
    return u.origin;
  }

  static function removeDotDotSlash(url:String):String {
    var parts = url.split("/");
    while (true) {
      var dotDotNdx = parts.indexOf("..");
      if (dotDotNdx < 0) {
        break;
      }
      parts.splice(dotDotNdx - 1, 2);
    }
    var newUrl = parts.join("/");
    return newUrl;
  }

  static function fixSourceLinks(url:String, source:String):String {
    var srcRE = /(src=)(")(.*?)(")()/g;
    var linkRE = /(href=)(")(.*?)(")()/g;
    var imageSrcRE = /((?:image|img)\.src = )(")(.*?)(")()/g;
    var loaderLoadRE = /(loader\.load[a-z]*\s*\(\s*)('|")(.*?)('|")/ig;
    var loaderArrayLoadRE = /(loader\.load[a-z]*\(\[)([\s\S]*?)(\])/ig;
    var loadFileRE = /(loadFile\s*\(\s*)('|")(.*?)('|")/ig;
    var threejsUrlRE = /(.*?)('|")([^"']*?)('|")([^'"]*?)(\/\*\s+threejs.org:\s+url\s+\*\/)/ig;
    var arrayLineRE = /^(\s*["|'])([\s\S]*?)(["|']*$)/;
    var urlPropRE = /(url:\s*)('|")(.*?)('|")/g;
    var workerRE = /(new\s+Worker\s*\(\s*)('|")(.*?)('|")/g;
    var importScriptsRE = /(importScripts\s*\(\s*)('|")(.*?)('|")/g;
    var moduleRE = /(import.*?)('|")(.*?)('|")/g;
    var prefix = getPrefix(url);
    var rootPrefix = getRootPrefix(url);

    var addCorrectPrefix = function(url:String):String {
      if (url.startsWith("/")) {
        return rootPrefix + url;
      } else {
        return removeDotDotSlash((prefix + url).replace(/\/.\//g, "/"));
      }
    };

    var addPrefix = function(url:String):String {
      if (url.indexOf("://") < 0 && !url.startsWith("data:") && url[0] != "?") {
        return removeDotDotSlash(addCorrectPrefix(url));
      } else {
        return url;
      }
    };

    var makeLinkFDedQuotes = function(match:String, fn:String, q1:String, url:String, q2:String):String {
      return fn + q1 + addPrefix(url) + q2;
    };

    var makeTaggedFDedQuotes = function(match:String, start:String, q1:String, url:String, q2:String, suffix:String):String {
      return start + q1 + addPrefix(url) + q2 + suffix;
    };

    var makeFDedQuotesModule = function(match:String, start:String, q1:String, url:String, q2:String):String {
      return start + q1 + (url.startsWith(".") ? addPrefix(url) : url) + q2;
    };

    var makeArrayLinksFDed = function(match:String, prefix:String, arrayStr:String, suffix:String):String {
      var lines = arrayStr.split(",").map(function(line:String) {
        var m = arrayLineRE.exec(line);
        if (m != null) {
          return m[1] + addPrefix(m[2]) + m[3];
        } else {
          return line;
        }
      });
      return prefix + lines.join(",") + suffix;
    };

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

  static function extraHTMLParsing(html:String):String {
    return html;
  }

  static function fixJSForCodeSite(js:String):String {
    var moduleRE = /(import.*?)('|")(.*?)('|")/g;

    if (version == null) {
      try {
        var res = js.Lib.fetch("https://raw.githubusercontent.com/mrdoob/three.js/master/package.json");
        var json = js.Lib.parseJSON(res.responseText);
        version = json.version;
      } catch (e:Dynamic) {
        js.Lib.console.error(e);
      }
    }

    var addVersion = function(href:String):String {
      if (href.startsWith(js.Browser.window.location.origin)) {
        if (href.includes("/build/three.module.js")) {
          return "https://cdn.jsdelivr.net/npm/three@" + version;
        } else if (href.includes("/examples/jsm/")) {
          var url = new js.html.URL(href);
          return "https://cdn.jsdelivr.net/npm/three@" + version + url.pathname + url.search + url.hash;
        }
      }
      return href;
    };

    var addVersionToURL = function(match:String, start:String, q1:String, url:String, q2:String):String {
      return start + q1 + addVersion(url) + q2;
    };

    if (version != null) {
      js = js.replace(moduleRE, addVersionToURL);
    }

    return js;
  }
}