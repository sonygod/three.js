import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.ClampToEdgeWrapping;
import three.math.Color;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.core.LinearFilter;
import three.core.LinearMipmapLinearFilter;
import three.loaders.Loader;
import three.math.Matrix4;
import three.objects.Mesh;
import three.materials.MeshPhongMaterial;
import three.materials.MeshStandardMaterial;
import three.core.MirroredRepeatWrapping;
import three.core.NearestFilter;
import three.core.RepeatWrapping;
import three.loaders.TextureLoader;
import three.core.SRGBColorSpace;
import fflate.FFlate;

class ThreeMFLoader extends Loader {

  public var availableExtensions:Array<Dynamic>;

  public function new(manager:Loader) {
    super(manager);
    availableExtensions = new Array();
  }

  public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
    final scope = this;
    final loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(buffer:haxe.io.Bytes) {
      try {
        onLoad(scope.parse(buffer.buffer));
      } catch(e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          console.error(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }

  public function parse(data:haxe.io.Bytes):Dynamic {
    final scope = this;
    final textureLoader = new TextureLoader(this.manager);
    final COLOR_SPACE_3MF = SRGBColorSpace;

    function loadDocument(data:haxe.io.Bytes):Dynamic {
      var zip:Dynamic = null;
      var file:String = null;
      var relsName:String;
      var modelRelsName:String;
      final modelPartNames:Array<String> = new Array();
      final texturesPartNames:Array<String> = new Array();
      var modelRels:Dynamic;
      final modelParts:Dynamic = new DynamicMap();
      final printTicketParts:Dynamic = new DynamicMap();
      final texturesParts:Dynamic = new DynamicMap();
      final textDecoder = new TextDecoder();
      try {
        zip = FFlate.unzipSync(new Uint8Array(data));
      } catch(e:Dynamic) {
        if (Std.isOfType(e, ReferenceError)) {
          console.error('THREE.3MFLoader: fflate missing and file is compressed.');
          return null;
        }
      }
      for (file in zip) {
        if (file.match(/\_rels\/.rels$/)) {
          relsName = file;
        } else if (file.match(/3D\/_rels\/.*\.model\.rels$/)) {
          modelRelsName = file;
        } else if (file.match(/^3D\/.*\.model$/)) {
          modelPartNames.push(file);
        } else if (file.match(/^3D\/Textures?\/.*/)) {
          texturesPartNames.push(file);
        }
      }
      if (relsName == null) throw new Error('THREE.ThreeMFLoader: Cannot find relationship file `rels` in 3MF archive.');
      final relsView:haxe.io.Bytes = zip[relsName];
      final relsFileText:String = textDecoder.decode(relsView);
      final rels:Dynamic = parseRelsXml(relsFileText);
      if (modelRelsName != null) {
        final relsView:haxe.io.Bytes = zip[modelRelsName];
        final relsFileText:String = textDecoder.decode(relsView);
        modelRels = parseRelsXml(relsFileText);
      }
      for (var i = 0; i < modelPartNames.length; i++) {
        final modelPart:String = modelPartNames[i];
        final view:haxe.io.Bytes = zip[modelPart];
        final fileText:String = textDecoder.decode(view);
        final xmlData:DOMParser = new DOMParser();
        xmlData.parseFromString(fileText, 'application/xml');
        if (xmlData.documentElement.nodeName.toLowerCase() != 'model') {
          console.error('THREE.3MFLoader: Error loading 3MF - no 3MF document found: ', modelPart);
        }
        final modelNode:xml.Element = xmlData.querySelector('model');
        final extensions:Dynamic = new DynamicMap();
        for (var i1 = 0; i1 < modelNode.attributes.length; i1++) {
          final attr:xml.Attr = modelNode.attributes[i1];
          if (attr.name.match(/^xmlns:(.+)$/)) {
            extensions[attr.value] = RegExp.$1;
          }
        }
        final modelData:Dynamic = parseModelNode(modelNode);
        modelData['xml'] = modelNode;
        if (0 < extensions.keys().length) {
          modelData['extensions'] = extensions;
        }
        modelParts[modelPart] = modelData;
      }
      for (var i = 0; i < texturesPartNames.length; i++) {
        final texturesPartName:String = texturesPartNames[i];
        texturesParts[texturesPartName] = zip[texturesPartName].buffer;
      }
      return {
        'rels': rels,
        'modelRels': modelRels,
        'model': modelParts,
        'printTicket': printTicketParts,
        'texture': texturesParts
      };
    }

    function parseRelsXml(relsFileText:String):Dynamic {
      final relationships:Array<Dynamic> = new Array();
      final relsXmlData:DOMParser = new DOMParser();
      relsXmlData.parseFromString(relsFileText, 'application/xml');
      final relsNodes:xml.NodeList = relsXmlData.querySelectorAll('Relationship');
      for (var i = 0; i < relsNodes.length; i++) {
        final relsNode:xml.Element = relsNodes[i];
        final relationship:Dynamic = {
          'target': relsNode.getAttribute('Target'),
          'id': relsNode.getAttribute('Id'),
          'type': relsNode.getAttribute('Type')
        };
        relationships.push(relationship);
      }
      return relationships;
    }

    function parseMetadataNodes(metadataNodes:xml.NodeList):Dynamic {
      final metadataData:Dynamic = new DynamicMap();
      for (var i = 0; i < metadataNodes.length; i++) {
        final metadataNode:xml.Element = metadataNodes[i];
        final name:String = metadataNode.getAttribute('name');
        final validNames:Array<String> = [
          'Title',
          'Designer',
          'Description',
          'Copyright',
          'LicenseTerms',
          'Rating',
          'CreationDate',
          'ModificationDate'
        ];
        if (0 <= validNames.indexOf(name)) {
          metadataData[name] = metadataNode.textContent;
        }
      }
      return metadataData;
    }

    function parseBasematerialsNode(basematerialsNode:xml.Element):Dynamic {
      final basematerialsData:Dynamic = {
        'id': basematerialsNode.getAttribute('id'),
        'basematerials': new Array()
      };
      final basematerialNodes:xml.NodeList = basematerialsNode.querySelectorAll('base');
      for (var i = 0; i < basematerialNodes.length; i++) {
        final basematerialNode:xml.Element = basematerialNodes[i];
        final basematerialData:Dynamic = parseBasematerialNode(basematerialNode);
        basematerialData.index = i;
        basematerialsData.basematerials.push(basematerialData);
      }
      return basematerialsData;
    }

    function parseTexture2DNode(texture2DNode:xml.Element):Dynamic {
      final texture2dData:Dynamic = {
        'id': texture2DNode.getAttribute('id'),
        'path': texture2DNode.getAttribute('path'),
        'contenttype': texture2DNode.getAttribute('contenttype'),
        'tilestyleu': texture2DNode.getAttribute('tilestyleu'),
        'tilestylev': texture2DNode.getAttribute('tilestylev'),
        'filter': texture2DNode.getAttribute('filter')
      };
      return texture2dData;
    }

    function parseTextures2DGroupNode(texture2DGroupNode:xml.Element):Dynamic {
      final texture2DGroupData:Dynamic = {
        'id': texture2DGroupNode.getAttribute('id'),
        'texid': texture2DGroupNode.getAttribute('texid'),
        'displaypropertiesid': texture2DGroupNode.getAttribute('displaypropertiesid')
      };
      final tex2coordNodes:xml.NodeList = texture2DGroupNode.querySelectorAll('tex2coord');
      final uvs:Array<Float> = new Array();
      for (var i = 0; i < tex2coordNodes.length; i++) {
        final tex2coordNode:xml.Element = tex2coordNodes[i];
        final u:String = tex2coordNode.getAttribute('u');
        final v:String = tex2coordNode.getAttribute('v');
        uvs.push(Std.parseFloat(u), Std.parseFloat(v));
      }
      texture2DGroupData['uvs'] = new Float32Array(uvs);
      return texture2DGroupData;
    }

    function parseColorGroupNode(colorGroupNode:xml.Element):Dynamic {
      final colorGroupData:Dynamic = {
        'id': colorGroupNode.getAttribute('id'),
        'displaypropertiesid': colorGroupNode.getAttribute('displaypropertiesid')
      };
      final colorNodes:xml.NodeList = colorGroupNode.querySelectorAll('color');
      final colors:Array<Float> = new Array();
      final colorObject = new Color();
      for (var i = 0; i < colorNodes.length; i++) {
        final colorNode:xml.Element = colorNodes[i];
        final color:String = colorNode.getAttribute('color');
        colorObject.setStyle(color.substring(0, 7), COLOR_SPACE_3MF);
        colors.push(colorObject.r, colorObject.g, colorObject.b);
      }
      colorGroupData['colors'] = new Float32Array(colors);
      return colorGroupData;
    }

    function parseMetallicDisplaypropertiesNode(metallicDisplaypropetiesNode:xml.Element):Dynamic {
      final metallicDisplaypropertiesData:Dynamic = {
        'id': metallicDisplaypropetiesNode.getAttribute('id')
      };
      final metallicNodes:xml.NodeList = metallicDisplaypropetiesNode.querySelectorAll('pbmetallic');
      final metallicData:Array<Dynamic> = new Array();
      for (var i = 0; i < metallicNodes.length; i++) {
        final metallicNode:xml.Element = metallicNodes[i];
        metallicData.push({
          'name': metallicNode.getAttribute('name'),
          'metallicness': Std.parseFloat(metallicNode.getAttribute('metallicness')),
          'roughness': Std.parseFloat(metallicNode.getAttribute('roughness'))
        });
      }
      metallicDisplaypropertiesData.data = metallicData;
      return metallicDisplaypropertiesData;
    }

    function parseBasematerialNode(basematerialNode:xml.Element):Dynamic {
      final basematerialData:Dynamic = new DynamicMap();
      basematerialData['name'] = basematerialNode.getAttribute('name');
      basematerialData['displaycolor'] = basematerialNode.getAttribute('displaycolor');
      basematerialData['displaypropertiesid'] = basematerialNode.getAttribute('displaypropertiesid');
      return basematerialData;
    }

    function parseMeshNode(meshNode:xml.Element):Dynamic {
      final meshData:Dynamic = new DynamicMap();
      final vertices:Array<Float> = new Array();
      final vertexNodes:xml.NodeList = meshNode.querySelectorAll('vertices vertex');
      for (var i = 0; i < vertexNodes.length; i++) {
        final vertexNode:xml.Element = vertexNodes[i];
        final x:String = vertexNode.getAttribute('x');
        final y:String = vertexNode.getAttribute('y');
        final z:String = vertexNode.getAttribute('z');
        vertices.push(Std.parseFloat(x), Std.parseFloat(y), Std.parseFloat(z));
      }
      meshData['vertices'] = new Float32Array(vertices);
      final triangleProperties:Array<Dynamic> = new Array();
      final triangles:Array<Int> = new Array();
      final triangleNodes:xml.NodeList = meshNode.querySelectorAll('triangles triangle');
      for (var i = 0; i < triangleNodes.length; i++) {
        final triangleNode:xml.Element = triangleNodes[i];
        final v1:String = triangleNode.getAttribute('v1');
        final v2:String = triangleNode.getAttribute('v2');
        final v3:String = triangleNode.getAttribute('v3');
        final p1:String = triangleNode.getAttribute('p1');
        final p2:String = triangleNode.getAttribute('p2');
        final p3:String = triangleNode.getAttribute('p3');
        final pid:String = triangleNode.getAttribute('pid');
        final triangleProperty:Dynamic = new DynamicMap();
        triangleProperty['v1'] = Std.parseInt(v1, 10);
        triangleProperty['v2'] = Std.parseInt(v2, 10);
        triangleProperty['v3'] = Std.parseInt(v3, 10);
        triangles.push(triangleProperty['v1'], triangleProperty['v2'], triangleProperty['v3']);
        if (p1 != null) {
          triangleProperty['p1'] = Std.parseInt(p1, 10);
        }
        if (p2 != null) {
          triangleProperty['p2'] = Std.parseInt(p2, 10);
        }
        if (p3 != null) {
          triangleProperty['p3'] = Std.parseInt(p3, 10);
        }
        if (pid != null) {
          triangleProperty['pid'] = pid;
        }
        if (0 < triangleProperty.keys().length) {
          triangleProperties.push(triangleProperty);
        }
      }
      meshData['triangleProperties'] = triangleProperties;
      meshData['triangles'] = new Uint32Array(triangles);
      return meshData;
    }

    function parseComponentsNode(componentsNode:xml.Element):Dynamic {
      final components:Array<Dynamic> = new Array();
      final componentNodes:xml.NodeList = componentsNode.querySelectorAll('component');
      for (var i = 0; i < componentNodes.length; i++) {
        final componentNode:xml.Element = componentNodes[i];
        final componentData:Dynamic = parseComponentNode(componentNode);
        components.push(componentData);
      }
      return components;
    }

    function parseComponentNode(componentNode:xml.Element):Dynamic {
      final componentData:Dynamic = new DynamicMap();
      componentData['objectId'] = componentNode.getAttribute('objectid');
      final transform:String = componentNode.getAttribute('transform');
      if (transform != null) {
        componentData['transform'] = parseTransform(transform);
      }
      return componentData;
    }

    function parseTransform(transform:String):Dynamic {
      final t:Array<Float> = new Array();
      transform.split(' ').forEach(function(s:String) {
        t.push(Std.parseFloat(s));
      });
      final matrix = new Matrix4();
      matrix.set(t[0], t[3], t[6], t[9], t[1], t[4], t[7], t[10], t[2], t[5], t[8], t[11], 0.0, 0.0, 0.0, 1.0);
      return matrix;
    }

    function parseObjectNode(objectNode:xml.Element):Dynamic {
      final objectData:Dynamic = {
        'type': objectNode.getAttribute('type')
      };
      final id:String = objectNode.getAttribute('id');
      if (id != null) {
        objectData['id'] = id;
      }
      final pid:String = objectNode.getAttribute('pid');
      if (pid != null) {
        objectData['pid'] = pid;
      }
      final pindex:String = objectNode.getAttribute('pindex');
      if (pindex != null) {
        objectData['pindex'] = pindex;
      }
      final thumbnail:String = objectNode.getAttribute('thumbnail');
      if (thumbnail != null) {
        objectData['thumbnail'] = thumbnail;
      }
      final partnumber:String = objectNode.getAttribute('partnumber');
      if (partnumber != null) {
        objectData['partnumber'] = partnumber;
      }
      final name:String = objectNode.getAttribute('name');
      if (name != null) {
        objectData['name'] = name;
      }
      final meshNode:xml.Element = objectNode.querySelector('mesh');
      if (meshNode != null) {
        objectData['mesh'] = parseMeshNode(meshNode);
      }
      final componentsNode:xml.Element = objectNode.querySelector('components');
      if (componentsNode != null) {
        objectData['components'] = parseComponentsNode(componentsNode);
      }
      return objectData;
    }

    function parseResourcesNode(resourcesNode:xml.Element):Dynamic {
      final resourcesData:Dynamic = new DynamicMap();
      resourcesData['basematerials'] = new DynamicMap();
      final basematerialsNodes:xml.NodeList = resourcesNode.querySelectorAll('basematerials');
      for (var i = 0; i < basematerialsNodes.length; i++) {
        final basematerialsNode:xml.Element = basematerialsNodes[i];
        final basematerialsData:Dynamic = parseBasematerialsNode(basematerialsNode);
        resourcesData['basematerials'][basematerialsData['id']] = basematerialsData;
      }
      resourcesData['texture2d'] = new DynamicMap();
      final textures2DNodes:xml.NodeList = resourcesNode.querySelectorAll('texture2d');
      for (var i = 0; i < textures2DNodes.length; i++) {
        final textures2DNode:xml.Element = textures2DNodes[i];
        final texture2DData:Dynamic = parseTexture2DNode(textures2DNode);
        resourcesData['texture2d'][texture2DData['id']] = texture2DData;
      }
      resourcesData['colorgroup'] = new DynamicMap();
      final colorGroupNodes:xml.NodeList = resourcesNode.querySelectorAll('colorgroup');
      for (var i = 0; i < colorGroupNodes.length; i++) {
        final colorGroupNode:xml.Element = colorGroupNodes[i];
        final colorGroupData:Dynamic = parseColorGroupNode(colorGroupNode);
        resourcesData['colorgroup'][colorGroupData['id']] = colorGroupData;
      }
      resourcesData['pbmetallicdisplayproperties'] = new DynamicMap();
      final pbmetallicdisplaypropertiesNodes:xml.NodeList = resourcesNode.querySelectorAll('pbmetallicdisplayproperties');
      for (var i = 0; i < pbmetallicdisplaypropertiesNodes.length; i++) {
        final pbmetallicdisplaypropertiesNode:xml.Element = pbmetallicdisplaypropertiesNodes[i];
        final pbmetallicdisplaypropertiesData:Dynamic = parseMetallicDisplaypropertiesNode(pbmetallicdisplaypropertiesNode);
        resourcesData['pbmetallicdisplayproperties'][pbmetallicdisplaypropertiesData['id']] = pbmetallicdisplaypropertiesData;
      }
      resourcesData['texture2dgroup'] = new DynamicMap();
      final textures2DGroupNodes:xml.NodeList = resourcesNode.querySelectorAll('texture2dgroup');
      for (var i = 0; i < textures2DGroupNodes.length; i++) {
        final textures2DGroupNode:xml.Element = textures2DGroupNodes[i];
        final textures2DGroupData:Dynamic = parseTextures2DGroupNode(textures2DGroupNode);
        resourcesData['texture2dgroup'][textures2DGroupData['id']] = textures2DGroupData;
      }
      resourcesData['object'] = new DynamicMap();
      final objectNodes:xml.NodeList = resourcesNode.querySelectorAll('object');
      for (var i = 0; i < objectNodes.length; i++) {
        final objectNode:xml.Element = objectNodes[i];
        final objectData:Dynamic = parseObjectNode(objectNode);
        resourcesData['object'][objectData['id']] = objectData;
      }
      return resourcesData;
    }

    function parseBuildNode(buildNode:xml.Element):Dynamic {
      final buildData:Array<Dynamic> = new Array();
      final itemNodes:xml.NodeList = buildNode.querySelectorAll('item');
      for (var i = 0; i < itemNodes.length; i++) {
        final itemNode:xml.Element = itemNodes[i];
        final buildItem:Dynamic = {
          'objectId': itemNode.getAttribute('objectid')
        };
        final transform:String = itemNode.getAttribute('transform');
        if (transform != null) {
          buildItem['transform'] = parseTransform(transform);
        }
        buildData.push(buildItem);
      }
      return buildData;
    }

    function parseModelNode(modelNode:xml.Element):Dynamic {
      final modelData:Dynamic = {
        'unit': modelNode.getAttribute('unit') || 'millimeter'
      };
      final metadataNodes:xml.NodeList = modelNode.querySelectorAll('metadata');
      if (metadataNodes != null) {
        modelData['metadata'] = parseMetadataNodes(metadataNodes);
      }
      final resourcesNode:xml.Element = modelNode.querySelector('resources');
      if (resourcesNode != null) {
        modelData['resources'] = parseResourcesNode(resourcesNode);
      }
      final buildNode:xml.Element = modelNode.querySelector('build');
      if (buildNode != null) {
        modelData['build'] = parseBuildNode(buildNode);
      }
      return modelData;
    }

    function buildTexture(texture2dgroup:Dynamic, objects:Dynamic, modelData:Dynamic, textureData:Dynamic):Dynamic {
      final texid:String = texture2dgroup.texid;
      final texture2ds:Dynamic = modelData.resources.texture2d;
      final texture2d:Dynamic = texture2ds[texid];
      if (texture2d != null) {
        final data:haxe.io.Bytes = textureData[texture2d.path];
        final type:String = texture2d.contenttype;
        final blob = new Blob([data], {
          'type': type
        });
        final sourceURI:String = URL.createObjectURL(blob);
        final texture = textureLoader.load(sourceURI, function() {
          URL.revokeObjectURL(sourceURI);
        });
        texture.colorSpace = COLOR_SPACE_3MF;
        switch (texture2d.tilestyleu) {
          case 'wrap':
            texture.wrapS = RepeatWrapping;
            break;
          case 'mirror':
            texture.wrapS = MirroredRepeatWrapping;
            break;
          case 'none':
          case 'clamp':
            texture.wrapS = ClampToEdgeWrapping;
            break;
          default:
            texture.wrapS = RepeatWrapping;
        }
        switch (texture2d.tilestylev) {
          case 'wrap':
            texture.wrapT = RepeatWrapping;
            break;
          case 'mirror':
            texture.wrapT = MirroredRepeatWrapping;
            break;
          case 'none':
          case 'clamp':
            texture.wrapT = ClampToEdgeWrapping;
            break;
          default:
            texture.wrapT = RepeatWrapping;
        }
        switch (texture2d.filter) {
          case 'auto':
            texture.magFilter = LinearFilter;
            texture.minFilter = LinearMipmapLinearFilter;
            break;
          case 'linear':
            texture.magFilter = LinearFilter;
            texture.minFilter = LinearFilter;
            break;
          case 'nearest':
            texture.magFilter = NearestFilter;
            texture.minFilter = NearestFilter;
            break;
          default:
            texture.magFilter = LinearFilter;
            texture.minFilter = LinearMipmapLinearFilter;
        }
        return texture;
      } else {
        return null;
      }
    }

    function buildBasematerialsMeshes(basematerials:Dynamic, triangleProperties:Array<Dynamic>, meshData:Dynamic, objects:Dynamic, modelData:Dynamic, textureData:Dynamic, objectData:Dynamic):Array<Dynamic> {
      final objectPindex:String = objectData.pindex;
      final materialMap:Dynamic = new DynamicMap();
      for (var i = 0; i < triangleProperties.length; i++) {
        final triangleProperty:Dynamic = triangleProperties[i];
        final pindex:String = (triangleProperty.p1 != null) ? triangleProperty.p1 : objectPindex;
        if (materialMap[pindex] == null) materialMap[pindex] = new Array();
        materialMap[pindex].push(triangleProperty);
      }
      final keys:Array<String> = materialMap.keys();
      final meshes:Array<Dynamic> = new Array();
      for (var i = 0; i < keys.length; i++) {
        final materialIndex:String = keys[i];
        final trianglePropertiesProps:Array<Dynamic> = materialMap[materialIndex];
        final basematerialData:Dynamic = basematerials.basematerials[materialIndex];
        final material:Dynamic = getBuild(basematerialData, objects, modelData, textureData, objectData, buildBasematerial);
        final geometry = new BufferGeometry();
        final positionData:Array<Float> = new Array();
        final vertices:Float32Array = meshData.vertices;
        for (var j = 0; j < trianglePropertiesProps.length; j++) {
          final triangleProperty:Dynamic = trianglePropertiesProps[j];
          positionData.push(vertices[(triangleProperty.v1 * 3) + 0]);
          positionData.push(vertices[(triangleProperty.v1 * 3) + 1]);
          positionData.push(vertices[(triangleProperty.v1 * 3) + 2]);
          positionData.push(vertices[(triangleProperty.v2 * 3) + 0]);
          positionData.push(vertices[(triangleProperty.v2 * 3) + 1]);
          positionData.push(vertices[(triangleProperty.v2 * 3) + 2]);
          positionData.push(vertices[(triangleProperty.v3 * 3) + 0]);
          positionData.push(vertices[(triangleProperty.v3 * 3) + 1]);
          positionData.push(vertices[(triangleProperty.v3 * 3) + 2]);
        }
        geometry.setAttribute('position', new Float32BufferAttribute(positionData, 3));
        final mesh = new Mesh(geometry, material);
        meshes.push(mesh);
      }
      return meshes;
    }

    function buildTexturedMesh(texture2dgroup:Dynamic, triangleProperties:Array<Dynamic>, meshData:Dynamic, objects:Dynamic, modelData:Dynamic, textureData:Dynamic, objectData:Dynamic):Dynamic {
      final geometry = new BufferGeometry();
      final positionData:Array<Float> = new Array();
      final uvData:Array<Float> = new Array();
      final vertices:Float32Array = meshData.vertices;
      final uvs:Float32Array = texture2dgroup.uvs;
      for (var i = 0; i < triangleProperties.length; i++) {
        final triangleProperty:Dynamic = triangleProperties[i];
        positionData.push(vertices[(triangleProperty.v1 * 3) + 0]);
        positionData.push(vertices[(triangleProperty.v1 * 3) + 1]);
        positionData.push(vertices[(triangleProperty.v1 * 3) + 2]);
        positionData.push(vertices[(triangleProperty.v2 * 3) + 0]);
        positionData.push(vertices[(triangleProperty.v2 * 3) + 1]);
        positionData.push(vertices[(triangleProperty.v2 * 3) + 2]);
        positionData.push(vertices[(triangleProperty.v3 * 3) + 0]);
        positionData.push(vertices[(triangleProperty.v3 * 3) + 1]);
        positionData.push(vertices[(triangleProperty.v3 * 3) + 2]);
        uvData.push(uvs[(triangleProperty.p1 * 2) + 0]);
        uvData.push(uvs[(triangleProperty.p1 * 2) + 1]);
        uvData.push(uvs[(triangleProperty.p2 * 2) + 0]);
        uvData.push(uvs[(triangleProperty.p2 * 2) + 1]);
        uvData.push(uvs[(triangleProperty.p3 * 2) + 0]);
        uvData.push(uvs[(triangleProperty.p3 * 2) + 1]);
      }
      geometry.setAttribute('position', new Float32BufferAttribute(positionData, 3));
      geometry.setAttribute('uv', new Float32BufferAttribute(uvData, 2));
      final texture:Dynamic = getBuild(texture2dgroup, objects, modelData, textureData, objectData, buildTexture);
      final material = new MeshPhongMaterial({
        'map': texture,
        'flatShading': true
      });
      final mesh = new Mesh(geometry, material);
      return mesh;
    }

    function buildVertexColorMesh(colorgroup:Dynamic, triangleProperties:Array<Dynamic>, meshData:Dynamic, objectData:Dynamic):Dynamic {
      final geometry = new BufferGeometry();
      final positionData:Array<Float> = new Array();
      final colorData:Array<Float> = new Array();
      final vertices:Float32Array = meshData.vertices;
      final colors:Float32Array = colorgroup.colors;
      for (var i = 0; i < triangleProperties.length; i++) {
        final triangleProperty:Dynamic = triangleProperties[i];
        final v1:Int = triangleProperty.v1;
        final v2:Int = triangleProperty.v2;
        final v3:Int = triangleProperty.v3;
        positionData.push(vertices[(v1 * 3) + 0]);
        positionData.push(vertices[(v1 * 3) + 1]);
        positionData.push(vertices[(v1 * 3) + 2]);
        positionData.push(vertices[(v2 * 3) + 0]);
        positionData.push(vertices[(v2 * 3) + 1]);
        positionData.push(vertices[(v2 * 3) + 2]);
        positionData.push(vertices[(v3 * 3) + 0]);
        positionData.push(vertices[(v3 * 3) + 1]);
        positionData.push(vertices[(v3 * 3) + 2]);
        final p1:String = (triangleProperty.p1 != null) ? triangleProperty.p1 : objectData.pindex;
        final p2:String = (triangleProperty.p2 != null) ? triangleProperty.p2 : p1;
        final p3:String = (triangleProperty.p3 != null) ? triangleProperty.p3 : p1;
        colorData.push(colors[(p1 * 3) + 0]);
        colorData.push(colors[(p1 * 3) + 1]);
        colorData.push(colors[(p1 * 3) + 2]);
        colorData.push(colors[(p2 * 3) + 0]);
        colorData.push(colors[(p2 * 3) + 1]);
        colorData.push(colors[(p2 * 3) + 2]);
        colorData.push(colors[(p3 * 3) + 0]);
        colorData.push(colors[(p3 * 3) + 1]);
        colorData.push(colors[(p3 * 3) + 2]);
      }
      geometry.setAttribute('position', new Float32BufferAttribute(positionData, 3));
      geometry.setAttribute('color', new Float32BufferAttribute(colorData, 3));
      final material = new MeshPhongMaterial({
        'vertexColors': true,
        'flatShading': true
      });
      final mesh = new Mesh(geometry, material);
      return mesh;
    }

    function buildDefaultMesh(meshData:Dynamic):Dynamic {
      final geometry = new BufferGeometry();
      geometry.setIndex(new BufferAttribute(meshData['triangles'], 1));
      geometry.setAttribute('position', new BufferAttribute(meshData['vertices'], 3));
      final material = new MeshPhongMaterial({
        'name': Loader.DEFAULT_MATERIAL_NAME,
        'color': 0xffffff,
        'flatShading': true
      });
      final mesh = new Mesh(geometry, material);
      return mesh;
    }

    function buildMeshes(resourceMap:Dynamic, meshData:Dynamic, objects:Dynamic, modelData:Dynamic, textureData:Dynamic, objectData:Dynamic):Array<Dynamic> {
      final keys:Array<String> = resourceMap.keys();
      final meshes:Array<Dynamic> = new Array();
      for (var i = 0; i < keys.length; i++) {
        final resourceId:String = keys[i];
        final triangleProperties:Array<Dynamic> = resourceMap[resourceId];
        final resourceType:String = getResourceType(resourceId, modelData);
        switch (resourceType) {
          case 'material':
            final basematerials:Dynamic = modelData.resources.basematerials[resourceId];
            final newMeshes:Array<Dynamic> = buildBasematerialsMeshes(basematerials, triangleProperties, meshData, objects, modelData, textureData, objectData);
            for (var j = 0; j < newMeshes.length; j++) {
              meshes.push(
      for (var i = 0; i < keys.length; i++) {
        final resourceId:String = keys[i];
        final triangleProperties:Array<Dynamic> = resourceMap[resourceId];
        final resourceType:String = getResourceType(resourceId, modelData);
        switch (resourceType) {
          case 'material':
            final basematerials:Dynamic = modelData.resources.basematerials[resourceId];
            final newMeshes:Array<Dynamic> = buildBasematerialsMeshes(basematerials, triangleProperties, meshData, objects, modelData, textureData, objectData);
            for (var j = 0; j < newMeshes.length; j++) {
              meshes.push(newMeshes[j]);
            }
            break;
          case 'texture':
            final texture2dgroup:Dynamic = modelData.resources.texture2dgroup[resourceId];
            meshes.push(buildTexturedMesh(texture2dgroup, triangleProperties, meshData, objects, modelData, textureData, objectData));
            break;
          case 'vertexColors':
            final colorgroup:Dynamic = modelData.resources.colorgroup[resourceId];
            meshes.push(buildVertexColorMesh(colorgroup, triangleProperties, meshData, objectData));
            break;
          case 'default':
            meshes.push(buildDefaultMesh(meshData));
            break;
          default:
            console.error('THREE.3MFLoader: Unsupported resource type.');
        }
      }
      if (objectData.name != null) {
        for (var i = 0; i < meshes.length; i++) {
          meshes[i].name = objectData.name;
        }
      }
      return meshes;
    }

    function getResourceType(pid:String, modelData:Dynamic):String {
      if (modelData.resources.texture2dgroup[pid] != null) {
        return 'texture';
      } else if (modelData.resources.basematerials[pid] != null) {
        return 'material';
      } else if (modelData.resources.colorgroup[pid] != null) {
        return 'vertexColors';
      } else if (pid == 'default') {
        return 'default';
      } else {
        return null;
      }
    }

    function analyzeObject(meshData:Dynamic, objectData:Dynamic):Dynamic {
      final resourceMap:Dynamic = new DynamicMap();
      final triangleProperties:Array<Dynamic> = meshData['triangleProperties'];
      final objectPid:String = objectData.pid;
      for (var i = 0; i < triangleProperties.length; i++) {
        final triangleProperty:Dynamic = triangleProperties[i];
        var pid:String = (triangleProperty.pid != null) ? triangleProperty.pid : objectPid;
        if (pid == null) pid = 'default';
        if (resourceMap[pid] == null) resourceMap[pid] = new Array();
        resourceMap[pid].push(triangleProperty);
      }
      return resourceMap;
    }

    function buildGroup(meshData:Dynamic, objects:Dynamic, modelData:Dynamic, textureData:Dynamic, objectData:Dynamic):Dynamic {
      final group = new Group();
      final resourceMap:Dynamic = analyzeObject(meshData, objectData);
      final meshes:Array<Dynamic> = buildMeshes(resourceMap, meshData, objects, modelData, textureData, objectData);
      for (var i = 0; i < meshes.length; i++) {
        group.add(meshes[i]);
      }
      return group;
    }

    function applyExtensions(extensions:Dynamic, meshData:Dynamic, modelXml:xml.Element) {
      if (extensions == null) {
        return;
      }
      final availableExtensions:Array<Dynamic> = new Array();
      final keys:Array<String> = extensions.keys();
      for (var i = 0; i < keys.length; i++) {
        final ns:String = keys[i];
        for (var j = 0; j < scope.availableExtensions.length; j++) {
          final extension:Dynamic = scope.availableExtensions[j];
          if (extension.ns == ns) {
            availableExtensions.push(extension);
          }
        }
      }
      for (var i = 0; i < availableExtensions.length; i++) {
        final extension:Dynamic = availableExtensions[i];
        extension.apply(modelXml, extensions[extension['ns']], meshData);
      }
    }

    function getBuild(data:Dynamic, objects:Dynamic, modelData:Dynamic, textureData:Dynamic, objectData:Dynamic, builder:Dynamic):Dynamic {
      if (data.build != null) return data.build;
      data.build = builder(data, objects, modelData, textureData, objectData);
      return data.build;
    }

    function buildBasematerial(materialData:Dynamic, objects:Dynamic, modelData:Dynamic):Dynamic {
      var material:Dynamic;
      final displaypropertiesid:String = materialData.displaypropertiesid;
      final pbmetallicdisplayproperties:Dynamic = modelData.resources.pbmetallicdisplayproperties;
      if (displaypropertiesid != null && pbmetallicdisplayproperties[displaypropertiesid] != null) {
        final pbmetallicdisplayproperty:Dynamic = pbmetallicdisplayproperties[displaypropertiesid];
        final metallicData:Dynamic = pbmetallicdisplayproperty.data[materialData.index];
        material = new MeshStandardMaterial({
          'flatShading': true,
          'roughness': metallicData.roughness,
          'metalness': metallicData.metallicness
        });
      } else {
        material = new MeshPhongMaterial({
          'flatShading': true
        });
      }
      material.name = materialData.name;
      final displaycolor:String = materialData.displaycolor;
      final color:String = displaycolor.substring(0, 7);
      material.color.setStyle(color, COLOR_SPACE_3MF);
      if (displaycolor.length == 9) {
        material.opacity = Std.parseInt(displaycolor.charAt(7) + displaycolor.charAt(8), 16) / 255;
      }
      return material;
    }

    function buildComposite(compositeData:Array<Dynamic>, objects:Dynamic, modelData:Dynamic, textureData:Dynamic):Dynamic {
      final composite = new Group();
      for (var j = 0; j < compositeData.length; j++) {
        final component:Dynamic = compositeData[j];
        var build:Dynamic = objects[component.objectId];
        if (build == null) {
          buildObject(component.objectId, objects, modelData, textureData);
          build = objects[component.objectId];
        }
        final object3D:Dynamic = build.clone();
        final transform:Dynamic = component.transform;
        if (transform != null) {
          object3D.applyMatrix4(transform);
        }
        composite.add(object3D);
      }
      return composite;
    }

    function buildObject(objectId:String, objects:Dynamic, modelData:Dynamic, textureData:Dynamic) {
      final objectData:Dynamic = modelData['resources']['object'][objectId];
      if (objectData['mesh'] != null) {
        final meshData:Dynamic = objectData['mesh'];
        final extensions:Dynamic = modelData['extensions'];
        final modelXml:xml.Element = modelData['xml'];
        applyExtensions(extensions, meshData, modelXml);
        objects[objectData.id] = getBuild(meshData, objects, modelData, textureData, objectData, buildGroup);
      } else {
        final compositeData:Array<Dynamic> = objectData['components'];
        objects[objectData.id] = getBuild(compositeData, objects, modelData, textureData, objectData, buildComposite);
      }
      if (objectData.name != null) {
        objects[objectData.id].name = objectData.name;
      }
    }

    function buildObjects(data3mf:Dynamic):Dynamic {
      final modelsData:Dynamic = data3mf.model;
      final modelRels:Dynamic = data3mf.modelRels;
      final objects:Dynamic = new DynamicMap();
      final modelsKeys:Array<String> = modelsData.keys();
      final textureData:Dynamic = new DynamicMap();
      if (modelRels != null) {
        for (var i = 0; i < modelRels.length; i++) {
          final modelRel:Dynamic = modelRels[i];
          final textureKey:String = modelRel.target.substring(1);
          if (data3mf.texture[textureKey] != null) {
            textureData[modelRel.target] = data3mf.texture[textureKey];
          }
        }
      }
      for (var i = 0; i < modelsKeys.length; i++) {
        final modelsKey:String = modelsKeys[i];
        final modelData:Dynamic = modelsData[modelsKey];
        final objectIds:Array<String> = modelData['resources']['object'].keys();
        for (var j = 0; j < objectIds.length; j++) {
          final objectId:String = objectIds[j];
          buildObject(objectId, objects, modelData, textureData);
        }
      }
      return objects;
    }

    function fetch3DModelPart(rels:Array<Dynamic>):Dynamic {
      for (var i = 0; i < rels.length; i++) {
        final rel:Dynamic = rels[i];
        final extension:String = rel.target.split('.').pop();
        if (extension.toLowerCase() == 'model') return rel;
      }
    }

    function build(objects:Dynamic, data3mf:Dynamic):Dynamic {
      final group = new Group();
      final relationship:Dynamic = fetch3DModelPart(data3mf['rels']);
      final buildData:Array<Dynamic> = data3mf.model[relationship['target'].substring(1)]['build'];
      for (var i = 0; i < buildData.length; i++) {
        final buildItem:Dynamic = buildData[i];
        final object3D:Dynamic = objects[buildItem['objectId']].clone();
        final transform:Dynamic = buildItem['transform'];
        if (transform != null) {
          object3D.applyMatrix4(transform);
        }
        group.add(object3D);
      }
      return group;
    }

    final data3mf:Dynamic = loadDocument(data);
    final objects:Dynamic = buildObjects(data3mf);
    return build(objects, data3mf);
  }

  public function addExtension(extension:Dynamic):Void {
    availableExtensions.push(extension);
  }

}

export { ThreeMFLoader };