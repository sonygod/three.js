Here is the converted Haxe code:
```
package three.js.examples.jm.loaders;

import js.lib.Promise;
import js.lib.Uint8Array;
import js.html.ArrayBuffer;
import opentype.Opentype;

class TTFLoader extends Loader {
  public var reversed:Bool;

  public function new(manager:Loader) {
    super(manager);
    this.reversed = false;
  }

  public function load(url:String, onLoad:Dynamic->Void, onProgress:ProgressEvent->Void, onError:Error->Void) {
    var scope:TTFLoader = this;
    var loader:FileLoader = new FileLoader(this.manager);
    loader.setPath(this.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(this.requestHeader);
    loader.setWithCredentials(this.withCredentials);
    loader.load(url, function(buffer:ArrayBuffer) {
      try {
        onLoad(scope.parse(buffer));
      } catch (e:Error) {
        if (onError != null) {
          onError(e);
        } else {
          js.Lib.console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }

  private function parse(arrayBuffer:ArrayBuffer):Dynamic {
    function convert(font:opentype.Font, reversed:Bool):Dynamic {
      var round:Float->Int = Math.round;
      var glyphs:Dynamic<String> = {};
      var scale:Float = (100000) / (font.unitsPerEm * 72);
      var glyphIndexMap:Dynamic<String> = font.encoding.cmap.glyphIndexMap;
      var unicodes:Array<String> = [for (k in glyphIndexMap.keys()) k];

      for (i in 0...unicodes.length) {
        var unicode:String = unicodes[i];
        var glyph:opentype.Glyph = font.glyphs.glyphs[glyphIndexMap[unicode]];

        if (unicode != null) {
          var token:Dynamic = {
            ha: round(glyph.advanceWidth * scale),
            x_min: round(glyph.xMin * scale),
            x_max: round(glyph.xMax * scale),
            o: ''
          };

          if (reversed) {
            glyph.path.commands = reverseCommands(glyph.path.commands);
          }

          for (command in glyph.path.commands) {
            if (command.type.toLowerCase() == 'c') {
              command.type = 'b';
            }

            token.o += command.type.toLowerCase() + ' ';

            if (command.x != null && command.y != null) {
              token.o += round(command.x * scale) + ' ' + round(command.y * scale) + ' ';
            }

            if (command.x1 != null && command.y1 != null) {
              token.o += round(command.x1 * scale) + ' ' + round(command.y1 * scale) + ' ';
            }

            if (command.x2 != null && command.y2 != null) {
              token.o += round(command.x2 * scale) + ' ' + round(command.y2 * scale) + ' ';
            }
          }

          glyphs[String.fromCharCode(glyph.unicode)] = token;
        }
      }

      return {
        glyphs: glyphs,
        familyName: font.getEnglishName('fullName'),
        ascender: round(font.ascender * scale),
        descender: round(font.descender * scale),
        underlinePosition: font.tables.post.underlinePosition,
        underlineThickness: font.tables.post.underlineThickness,
        boundingBox: {
          xMin: font.tables.head.xMin,
          xMax: font.tables.head.xMax,
          yMin: font.tables.head.yMin,
          yMax: font.tables.head.yMax
        },
        resolution: 1000,
        original_font_information: font.tables.name
      };
    }

    function reverseCommands(commands:Array<opentype.PathCommand>):Array<opentype.PathCommand> {
      var paths:Array<Array<opentype.PathCommand>> = [];
      var path:Array<opentype.PathCommand>;

      for (c in commands) {
        if (c.type.toLowerCase() == 'm') {
          path = [c];
          paths.push(path);
        } else if (c.type.toLowerCase() != 'z') {
          path.push(c);
        }
      }

      var reversed:Array<opentype.PathCommand> = [];

      for (p in paths) {
        var result:opentype.PathCommand = {
          type: 'm',
          x: p[p.length - 1].x,
          y: p[p.length - 1].y
        };

        reversed.push(result);

        for (i in p.length - 1...0) {
          var command:opentype.PathCommand = p[i];
          var result:opentype.PathCommand = {type: command.type};

          if (command.x2 != null && command.y2 != null) {
            result.x1 = command.x2;
            result.y1 = command.y2;
            result.x2 = command.x1;
            result.y2 = command.y1;
          } else if (command.x1 != null && command.y1 != null) {
            result.x1 = command.x1;
            result.y1 = command.y1;
          }

          result.x = p[i - 1].x;
          result.y = p[i - 1].y;
          reversed.push(result);
        }
      }

      return reversed;
    }

    return convert(opentype.parse(new Uint8Array(arrayBuffer)), this.reversed);
  }
}
```
Note that I had to make some assumptions about the Haxe types and syntax, as the original JavaScript code is quite complex and uses some advanced features. Please review the converted code carefully to ensure it meets your requirements.