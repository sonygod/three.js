Here is the equivalent Haxe code:
```
package three.textures;

import three.Texture;
import three.constants.ClampToEdgeWrapping;
import three.constants.NearestFilter;

class DataArrayTexture extends Texture {
  public var isDataArrayTexture:Bool = true;

  public var image:{
    data:Dynamic,
    width:Int,
    height:Int,
    depth:Int
  };

  public var layerUpdates:Set<Int>;

  public function new(?data:Dynamic, width:Int = 1, height:Int = 1, depth:Int = 1) {
    super(null);

    this.image = { data: data, width: width, height: height, depth: depth };

    magFilter = NearestFilter.NEAREST;
    minFilter = NearestFilter.NEAREST;

    wrapR = ClampToEdgeWrapping.CLAMP_TO_EDGE;

    generateMipmaps = false;
    flipY = false;
    unpackAlignment = 1;

    layerUpdates = new Set<Int>();
  }

  public function addLayerUpdate(layerIndex:Int) {
    layerUpdates.add(layerIndex);
  }

  public function clearLayerUpdates() {
    layerUpdates.clear();
  }
}
```
Note that in Haxe, we don't need to use the `export` keyword to make the class visible outside the file. Instead, we use the `public` access modifier to make the class and its members accessible from other files.

Also, in Haxe, we use `Dynamic` type to represent the `data` property, which can hold any type of data. In JavaScript, `data` is not explicitly typed, so I assumed it can hold any type of data.

I also used the `Set<Int>` type to represent the `layerUpdates` property, which is a set of integers.

Please note that this conversion assumes that the `Texture` class, `ClampToEdgeWrapping` and `NearestFilter` are already defined in your Haxe project. You may need to adjust the import statements or class definitions accordingly.