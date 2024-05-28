package three.js.src.materials;

import three.js.Material;
import three.js.math.Color;

class LineBasicMaterial extends Material {
    
    public var isLineBasicMaterial:Bool = true;
    
    public var type:String = 'LineBasicMaterial';
    
    public var color:Color;
    
    public var map:Dynamic;
    
    public var linewidth:Float = 1;
    
    public var linecap:String = 'round';
    
    public var linejoin:String = 'round';
    
    public var fog:Bool = true;
    
    public function new(?parameters:Dynamic) {
        super();
        
        color = new Color(0xffffff);
        
        setValues(parameters);
    }
    
    public function copy(source:LineBasicMaterial):LineBasicMaterial {
        super.copy(source);
        
        color.copy(source.color);
        
        map = source.map;
        
        linewidth = source.linewidth;
        linecap = source.linecap;
        linejoin = source.linejoin;
        
        fog = source.fog;
        
        return this;
    }
}