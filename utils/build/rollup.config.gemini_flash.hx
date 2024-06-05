import haxe.io.Bytes;
import haxe.io.StringTools;
import js.lib.MagicString;

class GlslPlugin {

  public function transform(code:String, id:String):Dynamic {
    if (!StringTools.endsWith(id, ".glsl.js")) return;

    var magicString = new MagicString(code);

    magicString.replaceAll(
      /\/\* glsl \*\/\`(.*?)\`/,
      function(match, p1):String {
        return StringTools.stringify(
          StringTools.trim(p1)
            .replace("\r", "")
            .replace(/[ \t]*\/\/.*\n/g, "") // remove //
            .replace(/[ \t]*\/\*[\s\S]*?\*\//g, "") // remove /* */
            .replace("\n{2,}", "\n") // # \n+ to \n
        );
      }
    );

    return {
      code: magicString.toString(),
      map: magicString.generateMap()
    };
  }

}

class HeaderPlugin {

  public function renderChunk(code:String):Dynamic {
    var magicString = new MagicString(code);
    magicString.prepend(`/**
 * @license
 * Copyright 2010-2024 Three.js Authors
 * SPDX-License-Identifier: MIT
 */\n`);

    return {
      code: magicString.toString(),
      map: magicString.generateMap()
    };
  }

}

class Build {

  public var input:String;
  public var plugins:Array<Dynamic>;
  public var output:Array<Dynamic>;

  public function new(input:String, plugins:Array<Dynamic>, output:Array<Dynamic>) {
    this.input = input;
    this.plugins = plugins;
    this.output = output;
  }

}

var builds = [
  new Build("src/Three.js", [new GlslPlugin(), new HeaderPlugin()], [
    {
      format: "esm",
      file: "build/three.module.js"
    }
  ]),
  new Build("src/Three.js", [new GlslPlugin(), new HeaderPlugin(), {
    transform(code:String, id:String):Dynamic {
      // Implement Terser here using Haxelib or a custom implementation
      // ...
      return {code: code, map: null};
    }
  }], [
    {
      format: "esm",
      file: "build/three.module.min.js"
    }
  ]),
  new Build("src/Three.js", [new GlslPlugin(), new HeaderPlugin()], [
    {
      format: "cjs",
      name: "THREE",
      file: "build/three.cjs",
      indent: "\t"
    }
  ])
];

public function main(args:Dynamic):Dynamic {
  return args.configOnlyModule ? builds[0] : builds;
}