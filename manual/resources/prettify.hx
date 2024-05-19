// Copyright (C) 2006 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import js.Browser;

class PrettyPrint {

    static function createSimpleLexer(shortcutStylePatterns:Array<Dynamic>, fallthroughStylePatterns:Array<Dynamic>):Dynamic {
        //...
    }

    static function sourceDecorator(options:Dynamic):Dynamic {
        //...
    }

    static function decorateSource(sourceCode:String, basePos:Int, decorate:Dynamic):Array<Dynamic> {
        //...
    }

    static function recombineTagsAndDecorations(job:Dynamic):Void {
        //...
    }

    static function registerLangHandler(handler:Dynamic, fileExtensions:Array<String>) {
        //...
    }

    static function langHandlerForExtension(extension:String, source:String):Dynamic {
        //...
    }

    static function applyDecorator(job:Dynamic) {
        //...
    }

    static function $prettyPrintOne(sourceCodeHtml:String, opt_langExtension:String, opt_numberLines:Dynamic):String {
        //...
    }

    static function $prettyPrint(opt_whenDone:Dynamic, opt_root:Dynamic = null) {
        //...
    }

}