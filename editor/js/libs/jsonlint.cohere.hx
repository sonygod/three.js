import haxe.Json;

class JsonLint {
    public static function parse(json:String):Dynamic {
        return Json.parse(json);
    }
}