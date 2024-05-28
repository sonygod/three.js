import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import js.Browser;

class MeshPhongMaterial extends Material {
    public var isMeshPhongMaterial:Bool;
    public var type:String;
    public var color:Color;
    public var specular:Color;
    public var shininess:Int;
    public var map:Dynamic;
    public var lightMap:Dynamic;
    public var lightMapIntensity:Float;
    public var aoMap:Dynamic;
    public var aoMapIntensity:Float;
    public var emissive:Color;
    public var emissiveIntensity:Float;
    public var emissiveMap:Dynamic;
    public var bumpMap:Dynamic;
    public var bumpScale:Float;
    public var normalMap:Dynamic;
    public var normalMapType:Int;
    public var normalScale:Vector2;
    public var displacementMap:Dynamic;
    public var displacementScale:Float;
    public var displacementBias:Float;
    public var specularMap:Dynamic;
    public var alphaMap:Dynamic;
    public var envMap:Dynamic;
    public var envMapRotation:Euler;
    public var combine:Int;
    public var reflectivity:Float;
    public var refractionRatio:Float;
    public var wireframe:Bool;
    public var wireframeLinewidth:Int;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;
    public var flatShading:Bool;
    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();
        isMeshPhongMaterial = true;
        type = 'MeshPhongMaterial';
        color = new Color(0xFFFFFF);
        specular = new Color(0x111111);
        shininess = 30;
        map = null;
        lightMap = null;
        lightMapIntensity = 1.0;
        aoMap = null;
        aoMapIntensity = 1.0;
        emissive = new Color(0x000000);
        emissiveIntensity = 1.0;
        emissiveMap = null;
        bumpMap = null;
        bumpScale = 1;
        normalMap = null;
        normalMapType = TangentSpaceNormalMap;
        normalScale = new Vector2(1, 1);
        displacementMap = null;
        displacementScale = 1;
        displacementBias = 0;
        specularMap = null;
        alphaMap = null;
        envMap = null;
        envMapRotation = new Euler();
        combine = MultiplyOperation;
        reflectivity = 1;
        refractionRatio = 0.98;
        wireframe = false;
        wireframeLinewidth = 1;
        wireframeLinecap = 'round';
        wireframeLinejoin = 'round';
        flatShading = false;
        fog = true;
        setValues(parameters);
    }

    public function copy(source:Dynamic) : Dynamic {
        super.copy(source);
        color.copy(source.color);
        specular.copy(source.specular);
        shininess = source.shininess;
        map = source.map;
        lightMap = source.lightMap;
        lightMapIntensity = source.lightMapIntensity;
        aoMap = source.aoMap;
        aoMapIntensity = source.aoMapIntensity;
        emissive.copy(source.emissive);
        emissiveMap = source.emissiveMap;
        emissiveIntensity = source.emissiveIntensity;
        bumpMap = source.bumpMap;
        bumpScale = source.bumpScale;
        normalMap = source.normalMap;
        normalMapType = source.normalMapType;
        normalScale.copy(source.normalScale);
        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;
        specularMap = source.specularMap;
        alphaMap = source.alphaMap;
        envMap = source.envMap;
        envMapRotation.copy(source.envMapRotation);
        combine = source.combine;
        reflectivity = source.reflectivity;
        refractionRatio = source.refractionRatio;
        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        wireframeLinecap = source.wireframeLinecap;
        wireframeLinejoin = source.wireframeLinejoin;
        flatShading = source.flatShading;
        fog = source.fog;
        return this;
    }
}

class Color {
    public function new(value:Dynamic) {
    }

    public function copy(source:Dynamic) : Dynamic {
        return null;
    }
}

class Vector2 {
    public function new(x:Float, y:Float) {
    }

    public function copy(source:Dynamic) : Dynamic {
        return null;
    }
}

class Euler {
    public function new() {
    }

    public function copy(source:Dynamic) : Dynamic {
        return null;
    }
}

class Material {
    public function copy(source:Dynamic) : Dynamic {
        return null;
    }
}

class MultiplyOperation {
}

class TangentSpaceNormalMap {
}

class DisplayObject extends InteractiveObject {
}

class DisplayObjectContainer extends DisplayObject {
}

class EventDispatcher extends InteractiveObject implements IEventDispatcher {
}

class IBitmapDrawable {
}

class InteractiveObject extends DisplayObject {
}

class MovieClip extends Sprite {
}

class Sprite extends DisplayObjectContainer {
}

class Event {
}

class Browser {
}

class Int {
}

class Float {
}

class Bool {
}

class String {
}