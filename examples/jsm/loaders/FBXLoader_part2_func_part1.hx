package three.js.examples.jsm.loaders;

import haxe.ds.Map;
import haxe.io.Bytes;
import js.html.Url;
import js.html.Blob;
import js.html.Uint8Array;

class FBXTreeParser {
    public var textureLoader:Dynamic;
    public var manager:Dynamic;

    public function new(textureLoader:Dynamic, manager:Dynamic) {
        this.textureLoader = textureLoader;
        this.manager = manager;
    }

    public function parse():Void {
        var connections:Map<Int, Dynamic> = parseConnections();
        var images:Map<Int, String> = parseImages();
        var textures:Map<Int, Dynamic> = parseTextures(images);
        var deformers:Array<Dynamic> = parseDeformers();
        var geometryMap:Map<Int, Dynamic> = new GeometryParser().parse(deformers);
        parseScene(deformers, geometryMap, textures);
    }

    private function parseConnections():Map<Int, Dynamic> {
        var connectionMap:Map<Int, Dynamic> = new Map();
        if (Reflect.hasField(fbxTree, "Connections")) {
            var rawConnections:Array<Dynamic> = fbxTree.Connections.connections;
            for (connection in rawConnections) {
                var fromID:Int = connection[0];
                var toID:Int = connection[1];
                var relationship:Int = connection[2];
                if (!connectionMap.exists(fromID)) {
                    connectionMap.set(fromID, { parents: [], children: [] });
                }
                var parentRelationship:Dynamic = { ID: toID, relationship: relationship };
                connectionMap.get(fromID).parents.push(parentRelationship);
                if (!connectionMap.exists(toID)) {
                    connectionMap.set(toID, { parents: [], children: [] });
                }
                var childRelationship:Dynamic = { ID: fromID, relationship: relationship };
                connectionMap.get(toID).children.push(childRelationship);
            }
        }
        return connectionMap;
    }

    private function parseImages():Map<Int, String> {
        var images:Map<Int, String> = new Map();
        var blobs:Map<String, Dynamic> = new Map();
        if (Reflect.hasField(fbxTree.Objects, "Video")) {
            var videoNodes:Dynamic = fbxTree.Objects.Video;
            for (nodeID in videoNodes.keys()) {
                var videoNode:Dynamic = videoNodes.get(nodeID);
                var id:Int = Std.parseInt(nodeID);
                images.set(id, videoNode.RelativeFilename || videoNode.Filename);
                if (Reflect.hasField(videoNode, "Content")) {
                    var arrayBufferContent:Bool = (videoNode.Content instanceof Bytes) && (videoNode.Content.length > 0);
                    var base64Content:Bool = (Js.typeof(videoNode.Content) == "string") && (videoNode.Content != "");
                    if (arrayBufferContent || base64Content) {
                        var image:Dynamic = parseImage(videoNode);
                        blobs.set(videoNode.RelativeFilename || videoNode.Filename, image);
                    }
                }
            }
        }
        for (id in images.keys()) {
            var filename:String = images.get(id);
            if (blobs.exists(filename)) {
                images.set(id, blobs.get(filename));
            } else {
                images.set(id, filename.split("\\").pop());
            }
        }
        return images;
    }

    private function parseImage(videoNode:Dynamic):Dynamic {
        var content:Dynamic = videoNode.Content;
        var fileName:String = videoNode.RelativeFilename || videoNode.Filename;
        var extension:String = fileName.slice(fileName.lastIndexOf(".") + 1).toLowerCase();
        var type:String;
        switch (extension) {
            case "bmp":
                type = "image/bmp";
                break;
            case "jpg", "jpeg":
                type = "image/jpeg";
                break;
            case "png":
                type = "image/png";
                break;
            case "tif":
                type = "image/tiff";
                break;
            case "tga":
                if (manager.getHandler(".tga") == null) {
                    console.warn("FBXLoader: TGA loader not found, skipping " + fileName);
                }
                type = "image/tga";
                break;
            default:
                console.warn("FBXLoader: Image type \"" + extension + "\" is not supported.");
                return;
        }
        if (Js.typeof(content) == "string") { // ASCII format
            return "data:" + type + ";base64," + content;
        } else { // Binary Format
            var array:Uint8Array = new Uint8Array(content);
            return Url.createObjectURL(new Blob([array], { type: type }));
        }
    }

    private function parseTextures(images:Map<Int, String>):Map<Int, Dynamic> {
        var textureMap:Map<Int, Dynamic> = new Map();
        if (Reflect.hasField(fbxTree.Objects, "Texture")) {
            var textureNodes:Dynamic = fbxTree.Objects.Texture;
            for (nodeID in textureNodes.keys()) {
                var texture:Dynamic = parseTexture(textureNodes.get(nodeID), images);
                textureMap.set(Std.parseInt(nodeID), texture);
            }
        }
        return textureMap;
    }

    private function parseTexture(textureNode:Dynamic, images:Map<Int, String>):Dynamic {
        var texture:Dynamic = loadTexture(textureNode, images);
        texture.ID = textureNode.id;
        texture.name = textureNode.attrName;
        var wrapModeU:Dynamic = textureNode.WrapModeU;
        var wrapModeV:Dynamic = textureNode.WrapModeV;
        var valueU:Int = wrapModeU != null ? wrapModeU.value : 0;
        var valueV:Int = wrapModeV != null ? wrapModeV.value : 0;
        texture.wrapS = valueU == 0 ? RepeatWrapping : ClampToEdgeWrapping;
        texture.wrapT = valueV == 0 ? RepeatWrapping : ClampToEdgeWrapping;
        if (Reflect.hasField(textureNode, "Scaling")) {
            var values:Array<Dynamic> = textureNode.Scaling.value;
            texture.repeat.x = values[0];
            texture.repeat.y = values[1];
        }
        if (Reflect.hasField(textureNode, "Translation")) {
            var values:Array<Dynamic> = textureNode.Translation.value;
            texture.offset.x = values[0];
            texture.offset.y = values[1];
        }
        return texture;
    }

    private function loadTexture(textureNode:Dynamic, images:Map<Int, String>):Dynamic {
        var fileName:String;
        var currentPath:String = textureLoader.path;
        var children:Array<Dynamic> = connections.get(textureNode.id).children;
        if (children != null && children.length > 0 && images.exists(children[0].ID)) {
            fileName = images.get(children[0].ID);
            if (fileName.indexOf("blob:") == 0 || fileName.indexOf("data:") == 0) {
                textureLoader.setPath(null);
            }
        }
        var texture:Dynamic;
        var extension:String = textureNode.FileName.slice(-3).toLowerCase();
        if (extension == "tga") {
            var loader:Dynamic = manager.getHandler(".tga");
            if (loader == null) {
                console.warn("FBXLoader: TGA loader not found, creating placeholder texture for " + textureNode.RelativeFilename);
                texture = new Texture();
            } else {
                loader.setPath(textureLoader.path);
                texture = loader.load(fileName);
            }
        } else if (extension == "dds") {
            var loader:Dynamic = manager.getHandler(".dds");
            if (loader == null) {
                console.warn("FBXLoader: DDS loader not found, creating placeholder texture for " + textureNode.RelativeFilename);
                texture = new Texture();
            } else {
                loader.setPath(textureLoader.path);
                texture = loader.load(fileName);
            }
        } else if (extension == "psd") {
            console.warn("FBXLoader: PSD textures are not supported, creating placeholder texture for " + textureNode.RelativeFilename);
            texture = new Texture();
        } else {
            texture = textureLoader.load(fileName);
        }
        textureLoader.setPath(currentPath);
        return texture;
    }

    // ... (rest of the code)
}