package three.utils.build;

import haxe.Json;
import haxe.ds.StringMap;

class RollupConfig {
  public function new() {}

  public function glsl():Dynamic {
    return {
      transform: function(code:String, id:String):Dynamic {
        if (!~/\.glsl\.js$/.match(id)) return null;

        var magicString = new MagicString(code);
        magicString.replace~/\/\* glsl \*\/\`(.*?)\`/sg, function(match:String, p1:String) {
          p1 = p1.trim();
          p1 = ~/[\r]/g.replace(p1, '');
          p1 = ~/[ \t]*\/\/.*\n/g.replace(p1, '');
          p1 = ~/[ \t]*\/\*[\s\S]*?\*\//g.replace(p1, '');
          p1 = ~/(\n){2,}/g.replace(p1, '\n');
          return Json.stringify(p1);
        });

        return {
          code: magicString.toString(),
          map: magicString.generateMap()
        };
      }
    };
  }

  public function header():Dynamic {
    return {
      renderChunk: function(code:String):Dynamic {
        var magicString = new MagicString(code);
        magicString.prepend('/**
 * @license
 * Copyright 2010-2024 Three.js Authors
 * SPDX-License-Identifier: MIT
 */\n');

        return {
          code: magicString.toString(),
          map: magicString.generateMap()
        };
      }
    };
  }

  public function getConfig(args:Dynamic):Array<Dynamic> {
    var builds:Array<Dynamic> = [
      {
        input: 'src/Three.js',
        plugins: [glsl(), header()],
        output: [{
          format: 'esm',
          file: 'build/three.module.js'
        }]
      },
      {
        input: 'src/Three.js',
        plugins: [glsl(), header(), terser()],
        output: [{
          format: 'esm',
          file: 'build/three.module.min.js'
        }]
      },
      {
        input: 'src/Three.js',
        plugins: [glsl(), header()],
        output: [{
          format: 'cjs',
          name: 'THREE',
          file: 'build/three.cjs',
          indent: '\t'
        }]
      }
    ];

    return args.configOnlyModule ? [builds[0]] : builds;
  }
}

class MagicString {
  public var str:String;
  public function new(str:String) {
    this.str = str;
  }

  public function replace(pattern:EReg, func:String->String):MagicString {
    // implementation omitted for brevity
    return this;
  }

  public function prepend(str:String):MagicString {
    this.str = str + this.str;
    return this;
  }

  public function generateMap():StringMap<String> {
    // implementation omitted for brevity
    return new StringMap<String>();
  }

  public function toString():String {
    return this.str;
  }
}

class Terser {
  // implementation omitted for brevity
}