import three.core.Object3D;
import three.core.Group;
import three.core.Scene;
import three.core.Vector3;
import three.core.Quaternion;
import three.materials.MeshBasicMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.PointsMaterial;
import three.materials.LineBasicMaterial;
import three.geometries.SphereGeometry;
import three.geometries.BoxGeometry;
import three.geometries.ConeGeometry;
import three.geometries.CylinderGeometry;
import three.geometries.BufferGeometry;
import three.geometries.PlaneGeometry;
import three.math.Color;
import three.textures.TextureLoader;
import three.textures.DataTexture;
import three.textures.ClampToEdgeWrapping;
import three.textures.RepeatWrapping;
import three.textures.SRGBColorSpace;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.core.Mesh;
import three.core.Points;
import three.core.LineSegments;
import three.math.Vector2;
import three.math.Matrix4;
import three.core.BufferAttribute;
import three.math.Face3;
import three.core.Raycaster;
import three.core.Intersection;
import three.core.WebGLRenderer;
import three.scenes.Fog;
import three.objects.Sprite;
import three.materials.SpriteMaterial;
import three.geometries.PlaneBufferGeometry;

import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.StringInput;
import haxe.io.BytesInput;
import haxe.ds.StringMap;

import chevrotain.Lexer;
import chevrotain.Parser;
import chevrotain.Token;
import chevrotain.createToken;
import chevrotain.Lexer.SKIPPED;

class VRMLLoader extends Loader {

  public function new( manager:Loader = null ) {
    super(manager);
  }

  override public function load( url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void ) {
    final path = (path == "") ? LoaderUtils.extractUrlBase(url) : path;
    final loader = new FileLoader(manager);
    loader.setPath(path);
    loader.setRequestHeader(requestHeader);
    loader.setWithCredentials(withCredentials);
    loader.load(url, function(text:String) {
      try {
        onLoad(parse(text, path));
      } catch(e:Dynamic) {
        if(onError != null) {
          onError(e);
        } else {
          #if three_debug
          console.error(e);
          #end
        }
        manager.itemError(url);
      }
    }, onProgress, onError);
  }

  public function parse( data:String, path:String ):Scene {
    final nodeMap = new StringMap<VRMLNode>();

    // Create lexer, parser and visitor
    final tokenData = createTokens();
    final lexer = new VRMLLexer(tokenData.tokens);
    final parser = new VRMLParser(tokenData.tokenVocabulary);
    final visitor = createVisitor(parser.getBaseCstVisitorConstructor());

    // Lexing
    final lexingResult = lexer.lex(data);
    parser.input = lexingResult.tokens;

    // Parsing
    final cstOutput = parser.vrml();

    if(parser.errors.length > 0) {
      #if three_debug
      console.error(parser.errors);
      #end
      throw "THREE.VRMLLoader: Parsing errors detected.";
    }

    // Actions
    final ast = visitor.visit(cstOutput);

    // First iteration: build nodemap based on DEF statements
    for(node in ast.nodes) {
      buildNodeMap(node);
    }

    // Second iteration: build nodes
    final scene = new Scene();
    for(node in ast.nodes) {
      final object = getNode(node);
      if(object is Object3D) {
        scene.add(object);
      }
      if(node.name == "WorldInfo") {
        scene.userData.worldInfo = object;
      }
    }

    return scene;
  }

  private function createTokens() {
    final createToken = chevrotain.createToken;

    // From http://gun.teipir.gr/VRML-amgem/spec/part1/concepts.html#SyntaxBasics
    final RouteIdentifier = createToken({ name: "RouteIdentifier", pattern: /[^x30-x39\0-x20x22x27x23x2bx2cx2dx2ex5bx5dx5cx7bx7d][^x0-x20x22x27x23x2bx2cx2dx2ex5bx5dx5cx7bx7d]*[\.][^x30-x39\0-x20x22x27x23x2bx2cx2dx2ex5bx5dx5cx7bx7d][^x0-x20x22x27x23x2bx2cx2dx2ex5bx5dx5cx7bx7d]*/ });
    final Identifier = createToken({ name: "Identifier", pattern: /[^x30-x39\0-x20x22x27x23x2bx2cx2dx2ex5bx5dx5cx7bx7d]([^x0-x20x22x27x23x2bx2cx2dx2ex5bx5dx5cx7bx7d])*/, longer_alt: RouteIdentifier });

    // From http://gun.teipir.gr/VRML-amgem/spec/part1/nodesRef.html
    final nodeTypes = [
      "Anchor", "Billboard", "Collision", "Group", "Transform", // grouping nodes
      "Inline", "LOD", "Switch", // special groups
      "AudioClip", "DirectionalLight", "PointLight", "Script", "Shape", "Sound", "SpotLight", "WorldInfo", // common nodes
      "CylinderSensor", "PlaneSensor", "ProximitySensor", "SphereSensor", "TimeSensor", "TouchSensor", "VisibilitySensor", // sensors
      "Box", "Cone", "Cylinder", "ElevationGrid", "Extrusion", "IndexedFaceSet", "IndexedLineSet", "PointSet", "Sphere", // geometries
      "Color", "Coordinate", "Normal", "TextureCoordinate", // geometric properties
      "Appearance", "FontStyle", "ImageTexture", "Material", "MovieTexture", "PixelTexture", "TextureTransform", // appearance
      "ColorInterpolator", "CoordinateInterpolator", "NormalInterpolator", "OrientationInterpolator", "PositionInterpolator", "ScalarInterpolator", // interpolators
      "Background", "Fog", "NavigationInfo", "Viewpoint", // bindable nodes
      "Text" // Text must be placed at the end of the regex so there are no matches for TextureTransform and TextureCoordinate
    ];

    final Version = createToken({
      name: "Version",
      pattern: /#VRML.*/,
      longer_alt: Identifier
    });

    final NodeName = createToken({
      name: "NodeName",
      pattern: new EReg(nodeTypes.join("|"), "i"),
      longer_alt: Identifier
    });

    final DEF = createToken({
      name: "DEF",
      pattern: /DEF/,
      longer_alt: Identifier
    });

    final USE = createToken({
      name: "USE",
      pattern: /USE/,
      longer_alt: Identifier
    });

    final ROUTE = createToken({
      name: "ROUTE",
      pattern: /ROUTE/,
      longer_alt: Identifier
    });

    final TO = createToken({
      name: "TO",
      pattern: /TO/,
      longer_alt: Identifier
    });

    final StringLiteral = createToken({ name: "StringLiteral", pattern: /"(?:[^\\"\n\r]|\\[bfnrtv"\\/]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])*"/ });
    final HexLiteral = createToken({ name: "HexLiteral", pattern: /0[xX][0-9a-fA-F]+/ });
    final NumberLiteral = createToken({ name: "NumberLiteral", pattern: /[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/ });
    final TrueLiteral = createToken({ name: "TrueLiteral", pattern: /TRUE/ });
    final FalseLiteral = createToken({ name: "FalseLiteral", pattern: /FALSE/ });
    final NullLiteral = createToken({ name: "NullLiteral", pattern: /NULL/ });
    final LSquare = createToken({ name: "LSquare", pattern: /\[/ });
    final RSquare = createToken({ name: "RSquare", pattern: /]/ });
    final LCurly = createToken({ name: "LCurly", pattern: /{/ });
    final RCurly = createToken({ name: "RCurly", pattern: /}/ });
    final Comment = createToken({
      name: "Comment",
      pattern: /#.*/,
      group: SKIPPED
    });

    // Commas, blanks, tabs, newlines and carriage returns are whitespace characters wherever they appear outside of string fields
    final WhiteSpace = createToken({
      name: "WhiteSpace",
      pattern: /[ ,\s]/,
      group: SKIPPED
    });

    final tokens = [
      WhiteSpace,
      // Keywords appear before the Identifier
      NodeName,
      DEF,
      USE,
      ROUTE,
      TO,
      TrueLiteral,
      FalseLiteral,
      NullLiteral,
      // The Identifier must appear after the keywords because all keywords are valid identifiers
      Version,
      Identifier,
      RouteIdentifier,
      StringLiteral,
      HexLiteral,
      NumberLiteral,
      LSquare,
      RSquare,
      LCurly,
      RCurly,
      Comment
    ];

    final tokenVocabulary = new StringMap<Token>();

    for(i in 0...tokens.length) {
      final token = tokens[i];
      tokenVocabulary.set(token.name, token);
    }

    return { tokens: tokens, tokenVocabulary: tokenVocabulary };
  }

  private function createVisitor(BaseVRMLVisitor:Class<Dynamic>) {
    class VRMLToASTVisitor extends BaseVRMLVisitor {

      public function new() {
        super();
        validateVisitor();
      }

      override public function vrml(ctx:VRMLParser.VrmlContext) {
        final data = {
          version: visit(ctx.version),
          nodes: [],
          routes: []
        };

        for(i in 0...ctx.node.length) {
          final node = ctx.node[i];
          data.nodes.push(visit(node));
        }

        if(ctx.route != null) {
          for(i in 0...ctx.route.length) {
            final route = ctx.route[i];
            data.routes.push(visit(route));
          }
        }

        return data;
      }

      override public function version(ctx:VRMLParser.VersionContext) {
        return ctx.Version[0].image;
      }

      override public function node(ctx:VRMLParser.NodeContext) {
        final data = {
          name: ctx.NodeName[0].image,
          fields: []
        };

        if(ctx.field != null) {
          for(i in 0...ctx.field.length) {
            final field = ctx.field[i];
            data.fields.push(visit(field));
          }
        }

        // DEF
        if(ctx.def != null) {
          data.DEF = visit(ctx.def[0]);
        }

        return data;
      }

      override public function field(ctx:VRMLParser.FieldContext) {
        final data = {
          name: ctx.Identifier[0].image,
          type: null,
          values: null
        };

        var result:Dynamic;

        // SFValue
        if(ctx.singleFieldValue != null) {
          result = visit(ctx.singleFieldValue[0]);
        }

        // MFValue
        if(ctx.multiFieldValue != null) {
          result = visit(ctx.multiFieldValue[0]);
        }

        data.type = result.type;
        data.values = result.values;

        return data;
      }

      override public function def(ctx:VRMLParser.DefContext) {
        return (ctx.Identifier != null) ? ctx.Identifier[0].image : ctx.NodeName[0].image;
      }

      override public function use(ctx:VRMLParser.UseContext) {
        return { USE: (ctx.Identifier != null) ? ctx.Identifier[0].image : ctx.NodeName[0].image };
      }

      override public function singleFieldValue(ctx:VRMLParser.SingleFieldValueContext) {
        return processField(this, ctx);
      }

      override public function multiFieldValue(ctx:VRMLParser.MultiFieldValueContext) {
        return processField(this, ctx);
      }

      override public function route(ctx:VRMLParser.RouteContext) {
        final data = {
          FROM: ctx.RouteIdentifier[0].image,
          TO: ctx.RouteIdentifier[1].image
        };
        return data;
      }
    }

    function processField(scope:VRMLToASTVisitor, ctx:VRMLParser.SingleFieldValueContext | VRMLParser.MultiFieldValueContext) {
      final field = {
        type: null,
        values: []
      };

      if(ctx.node != null) {
        field.type = "node";
        for(i in 0...ctx.node.length) {
          final node = ctx.node[i];
          field.values.push(scope.visit(node));
        }
      }

      if(ctx.use != null) {
        field.type = "use";
        for(i in 0...ctx.use.length) {
          final use = ctx.use[i];
          field.values.push(scope.visit(use));
        }
      }

      if(ctx.StringLiteral != null) {
        field.type = "string";
        for(i in 0...ctx.StringLiteral.length) {
          final stringLiteral = ctx.StringLiteral[i];
          field.values.push(stringLiteral.image.replace(/'|"/g, ""));
        }
      }

      if(ctx.NumberLiteral != null) {
        field.type = "number";
        for(i in 0...ctx.NumberLiteral.length) {
          final numberLiteral = ctx.NumberLiteral[i];
          field.values.push(Std.parseFloat(numberLiteral.image));
        }
      }

      if(ctx.HexLiteral != null) {
        field.type = "hex";
        for(i in 0...ctx.HexLiteral.length) {
          final hexLiteral = ctx.HexLiteral[i];
          field.values.push(hexLiteral.image);
        }
      }

      if(ctx.TrueLiteral != null) {
        field.type = "boolean";
        for(i in 0...ctx.TrueLiteral.length) {
          final trueLiteral = ctx.TrueLiteral[i];
          if(trueLiteral.image == "TRUE") {
            field.values.push(true);
          }
        }
      }

      if(ctx.FalseLiteral != null) {
        field.type = "boolean";
        for(i in 0...ctx.FalseLiteral.length) {
          final falseLiteral = ctx.FalseLiteral[i];
          if(falseLiteral.image == "FALSE") {
            field.values.push(false);
          }
        }
      }

      if(ctx.NullLiteral != null) {
        field.type = "null";
        ctx.NullLiteral.forEach(function() {
          field.values.push(null);
        });
      }

      return field;
    }

    return new VRMLToASTVisitor();
  }

  private function buildNodeMap(node:VRMLNode) {
    if(node.DEF != null) {
      nodeMap.set(node.DEF, node);
    }

    for(field in node.fields) {
      if(field.type == "node") {
        for(fieldValue in field.values) {
          buildNodeMap(fieldValue);
        }
      }
    }
  }

  private function getNode(node:VRMLNode) {
    if(node.USE != null) {
      return resolveUSE(node.USE);
    }

    if(node.build != null) {
      return node.build;
    }

    node.build = buildNode(node);
    return node.build;
  }

  private function buildNode(node:VRMLNode) {
    final nodeName = node.name;
    var build:Dynamic;

    switch(nodeName) {
      case "Anchor":
      case "Group":
      case "Transform":
      case "Collision":
        build = buildGroupingNode(node);
        break;
      case "Background":
        build = buildBackgroundNode(node);
        break;
      case "Shape":
        build = buildShapeNode(node);
        break;
      case "Appearance":
        build = buildAppearanceNode(node);
        break;
      case "Material":
        build = buildMaterialNode(node);
        break;
      case "ImageTexture":
        build = buildImageTextureNode(node);
        break;
      case "PixelTexture":
        build = buildPixelTextureNode(node);
        break;
      case "TextureTransform":
        build = buildTextureTransformNode(node);
        break;
      case "IndexedFaceSet":
        build = buildIndexedFaceSetNode(node);
        break;
      case "IndexedLineSet":
        build = buildIndexedLineSetNode(node);
        break;
      case "PointSet":
        build = buildPointSetNode(node);
        break;
      case "Box":
        build = buildBoxNode(node);
        break;
      case "Cone":
        build = buildConeNode(node);
        break;
      case "Cylinder":
        build = buildCylinderNode(node);
        break;
      case "Sphere":
        build = buildSphereNode(node);
        break;
      case "ElevationGrid":
        build = buildElevationGridNode(node);
        break;
      case "Extrusion":
        build = buildExtrusionNode(node);
        break;
      case "Color":
      case "Coordinate":
      case "Normal":
      case "TextureCoordinate":
        build = buildGeometricNode(node);
        break;
      case "WorldInfo":
        build = buildWorldInfoNode(node);
        break;
      case "Billboard":
      case "Inline":
      case "LOD":
      case "Switch":
      case "AudioClip":
      case "DirectionalLight":
      case "PointLight":
      case "Script":
      case "Sound":
      case "SpotLight":
      case "CylinderSensor":
      case "PlaneSensor":
      case "ProximitySensor":
      case "SphereSensor":
      case "TimeSensor":
      case "TouchSensor":
      case "VisibilitySensor":
      case "Text":
      case "FontStyle":
      case "MovieTexture":
      case "ColorInterpolator":
      case "CoordinateInterpolator":
      case "NormalInterpolator":
      case "OrientationInterpolator":
      case "PositionInterpolator":
      case "ScalarInterpolator":
      case "Fog":
      case "NavigationInfo":
      case "Viewpoint":
        // Node not supported yet
        break;
      default:
        #if three_debug
        console.warn("THREE.VRMLLoader: Unknown node:", nodeName);
        #end
        break;
    }

    if(build != null && node.DEF != null && Reflect.hasField(build, "name")) {
      Reflect.setField(build, "name", node.DEF);
    }

    return build;
  }

  private function buildGroupingNode(node:VRMLNode) {
    final object = new Group();

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "bboxCenter":
          // Field not supported
          break;
        case "bboxSize":
          // Field not supported
          break;
        case "center":
          // Field not supported
          break;
        case "children":
          parseFieldChildren(fieldValues, object);
          break;
        case "description":
          // Field not supported
          break;
        case "collide":
          // Field not supported
          break;
        case "parameter":
          // Field not supported
          break;
        case "rotation":
          final axis = new Vector3(fieldValues[0], fieldValues[1], fieldValues[2]).normalize();
          final angle = fieldValues[3];
          object.quaternion.setFromAxisAngle(axis, angle);
          break;
        case "scale":
          object.scale.set(fieldValues[0], fieldValues[1], fieldValues[2]);
          break;
        case "scaleOrientation":
          // Field not supported
          break;
        case "translation":
          object.position.set(fieldValues[0], fieldValues[1], fieldValues[2]);
          break;
        case "proxy":
          // Field not supported
          break;
        case "url":
          // Field not supported
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    return object;
  }

  private function buildBackgroundNode(node:VRMLNode) {
    final group = new Group();

    var groundAngle:Array<Float>;
    var groundColor:Array<Float>;
    var skyAngle:Array<Float>;
    var skyColor:Array<Float>;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "groundAngle":
          groundAngle = fieldValues;
          break;
        case "groundColor":
          groundColor = fieldValues;
          break;
        case "backUrl":
          // Field not supported
          break;
        case "bottomUrl":
          // Field not supported
          break;
        case "frontUrl":
          // Field not supported
          break;
        case "leftUrl":
          // Field not supported
          break;
        case "rightUrl":
          // Field not supported
          break;
        case "topUrl":
          // Field not supported
          break;
        case "skyAngle":
          skyAngle = fieldValues;
          break;
        case "skyColor":
          skyColor = fieldValues;
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    final radius = 10000;

    // Sky
    if(skyColor != null) {
      final skyGeometry = new SphereGeometry(radius, 32, 16);
      final skyMaterial = new MeshBasicMaterial({ fog: false, side: BackSide, depthWrite: false, depthTest: false });

      if(skyColor.length > 3) {
        paintFaces(skyGeometry, radius, skyAngle, toColorArray(skyColor), true);
        skyMaterial.vertexColors = true;
      } else {
        skyMaterial.color.setRGB(skyColor[0], skyColor[1], skyColor[2]);
        skyMaterial.color.convertSRGBToLinear();
      }

      final sky = new Mesh(skyGeometry, skyMaterial);
      group.add(sky);
    }

    // Ground
    if(groundColor != null) {
      if(groundColor.length > 0) {
        final groundGeometry = new SphereGeometry(radius, 32, 16, 0, 2 * Math.PI, 0.5 * Math.PI, 1.5 * Math.PI);
        final groundMaterial = new MeshBasicMaterial({ fog: false, side: BackSide, vertexColors: true, depthWrite: false, depthTest: false });
        paintFaces(groundGeometry, radius, groundAngle, toColorArray(groundColor), false);
        final ground = new Mesh(groundGeometry, groundMaterial);
        group.add(ground);
      }
    }

    // Render background group first
    group.renderOrder = -Infinity;

    return group;
  }

  private function buildShapeNode(node:VRMLNode) {
    final fields = node.fields;

    // If the appearance field is NULL or unspecified, lighting is off and the unlit object color is (0, 0, 0)
    var material = new MeshBasicMaterial({
      name: Loader.DEFAULT_MATERIAL_NAME,
      color: 0x000000
    });
    var geometry:Dynamic;

    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "appearance":
          if(fieldValues[0] != null) {
            material = getNode(fieldValues[0]);
          }
          break;
        case "geometry":
          if(fieldValues[0] != null) {
            geometry = getNode(fieldValues[0]);
          }
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    // Build 3D object
    var object:Dynamic;
    if(geometry != null && Reflect.hasField(geometry, "attributes") && Reflect.field(geometry, "attributes").position != null) {
      final type = geometry._type;

      if(type == "points") { // Points
        final pointsMaterial = new PointsMaterial({
          name: Loader.DEFAULT_MATERIAL_NAME,
          color: 0xffffff,
          opacity: material.opacity,
          transparent: material.transparent
        });

        if(Reflect.hasField(geometry, "attributes") && Reflect.field(geometry, "attributes").color != null) {
          pointsMaterial.vertexColors = true;
        } else {
          // If the color field is NULL and there is a material defined for the appearance affecting this PointSet, then use the emissiveColor of the material to draw the points
          if(material is MeshPhongMaterial) {
            pointsMaterial.color.copy(material.emissive);
          }
        }

        object = new Points(geometry, pointsMaterial);
      } else if(type == "line") { // Lines
        final lineMaterial = new LineBasicMaterial({
          name: Loader.DEFAULT_MATERIAL_NAME,
          color: 0xffffff,
          opacity: material.opacity,
          transparent: material.transparent
        });

        if(Reflect.hasField(geometry, "attributes") && Reflect.field(geometry, "attributes").color != null) {
          lineMaterial.vertexColors = true;
        } else {
          // If the color field is NULL and there is a material defined for the appearance affecting this IndexedLineSet, then use the emissiveColor of the material to draw the lines
          if(material is MeshPhongMaterial) {
            lineMaterial.color.copy(material.emissive);
          }
        }

        object = new LineSegments(geometry, lineMaterial);
      } else { // Consider meshes
        // Check "solid" hint (it's placed in the geometry but affects the material)
        if(Reflect.hasField(geometry, "_solid")) {
          material.side = (Reflect.field(geometry, "_solid")) ? FrontSide : DoubleSide;
        }

        // Check for vertex colors
        if(Reflect.hasField(geometry, "attributes") && Reflect.field(geometry, "attributes").color != null) {
          material.vertexColors = true;
        }

        object = new Mesh(geometry, material);
      }
    } else {
      object = new Object3D();
      // If the geometry field is NULL or no vertices are defined the object is not drawn
      object.visible = false;
    }

    return object;
  }

  private function buildAppearanceNode(node:VRMLNode) {
    var material = new MeshPhongMaterial();
    var transformData:Dynamic;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "material":
          if(fieldValues[0] != null) {
            final materialData = getNode(fieldValues[0]);
            if(materialData.diffuseColor != null) material.color.copy(materialData.diffuseColor);
            if(materialData.emissiveColor != null) material.emissive.copy(materialData.emissiveColor);
            if(materialData.shininess != null) material.shininess = materialData.shininess;
            if(materialData.specularColor != null) material.specular.copy(materialData.specularColor);
            if(materialData.transparency != null) material.opacity = 1 - materialData.transparency;
            if(materialData.transparency != null && materialData.transparency > 0) material.transparent = true;
          } else {
            // If the material field is NULL or unspecified, lighting is off and the unlit object color is (0, 0, 0)
            material = new MeshBasicMaterial({
              name: Loader.DEFAULT_MATERIAL_NAME,
              color: 0x000000
            });
          }
          break;
        case "texture":
          final textureNode = fieldValues[0];
          if(textureNode != null) {
            if(textureNode.name == "ImageTexture" || textureNode.name == "PixelTexture") {
              material.map = getNode(textureNode);
            } else {
              // MovieTexture not supported yet
            }
          }
          break;
        case "textureTransform":
          if(fieldValues[0] != null) {
            transformData = getNode(fieldValues[0]);
          }
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    // Only apply texture transform data if a texture was defined
    if(material.map != null) {
      // Respect VRML lighting model
      if(Reflect.hasField(material.map, "__type")) {
        switch(Reflect.field(material.map, "__type")) {
          case TEXTURE_TYPE.INTENSITY_ALPHA:
            material.opacity = 1; // Ignore transparency
            break;
          case TEXTURE_TYPE.RGB:
            material.color.set(0xffffff); // Ignore material color
            break;
          case TEXTURE_TYPE.RGBA:
            material.color.set(0xffffff); // Ignore material color
            material.opacity = 1; // Ignore transparency
            break;
          default:
        }
        Reflect.deleteField(material.map, "__type");
      }

      // Apply texture transform
      if(transformData != null) {
        material.map.center.copy(transformData.center);
        material.map.rotation = transformData.rotation;
        material.map.repeat.copy(transformData.scale);
        material.map.offset.copy(transformData.translation);
      }
    }

    return material;
  }

  private function buildMaterialNode(node:VRMLNode) {
    final materialData = {
      diffuseColor: null,
      emissiveColor: null,
      shininess: null,
      specularColor: null,
      transparency: null
    };

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "ambientIntensity":
          // Field not supported
          break;
        case "diffuseColor":
          materialData.diffuseColor = new Color(fieldValues[0], fieldValues[1], fieldValues[2]);
          materialData.diffuseColor.convertSRGBToLinear();
          break;
        case "emissiveColor":
          materialData.emissiveColor = new Color(fieldValues[0], fieldValues[1], fieldValues[2]);
          materialData.emissiveColor.convertSRGBToLinear();
          break;
        case "shininess":
          materialData.shininess = fieldValues[0];
          break;
        case "specularColor":
          materialData.specularColor = new Color(fieldValues[0], fieldValues[1], fieldValues[2]);
          materialData.specularColor.convertSRGBToLinear();
          break;
        case "transparency":
          materialData.transparency = fieldValues[0];
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    return materialData;
  }

  private function parseHexColor(hex:String, textureType:Int, color:Dynamic) {
    var value:Int;

    switch(textureType) {
      case TEXTURE_TYPE.INTENSITY:
        // Intensity texture: A one-component image specifies one-byte hexadecimal or integer values representing the intensity of the image
        value = Std.parseInt(hex);
        color.r = value;
        color.g = value;
        color.b = value;
        color.a = 1;
        break;
      case TEXTURE_TYPE.INTENSITY_ALPHA:
        // Intensity+Alpha texture: A two-component image specifies the intensity in the first (high) byte and the alpha opacity in the second (low) byte.
        value = Std.parseInt("0x" + hex.substring(2, 4));
        color.r = value;
        color.g = value;
        color.b = value;
        color.a = Std.parseInt("0x" + hex.substring(4, 6));

        break;
      case TEXTURE_TYPE.RGB:
        // RGB texture: Pixels in a three-component image specify the red component in the first (high) byte, followed by the green and blue components
        color.r = Std.parseInt("0x" + hex.substring(2, 4));
        color.g = Std.parseInt("0x" + hex.substring(4, 6));
        color.b = Std.parseInt("0x" + hex.substring(6, 8));
        color.a = 1;
        break;
      case TEXTURE_TYPE.RGBA:
        // RGBA texture: Four-component images specify the alpha opacity byte after red/green/blue
        color.r = Std.parseInt("0x" + hex.substring(2, 4));
        color.g = Std.parseInt("0x" + hex.substring(4, 6));
        color.b = Std.parseInt("0x" + hex.substring(6, 8));
        color.a = Std.parseInt("0x" + hex.substring(8, 10));
        break;
      default:
    }
  }

  private function getTextureType( num_components:Int ):Int {
    var type:Int;

    switch(num_components) {
      case 1:
        type = TEXTURE_TYPE.INTENSITY;
        break;
      case 2:
        type = TEXTURE_TYPE.INTENSITY_ALPHA;
        break;
      case 3:
        type = TEXTURE_TYPE.RGB;
        break;
      case 4:
        type = TEXTURE_TYPE.RGBA;
        break;
      default:
    }

    return type;
  }

  private function buildPixelTextureNode( node:VRMLNode ):DataTexture {
    var texture:DataTexture;
    var wrapS = RepeatWrapping;
    var wrapT = RepeatWrapping;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "image":
          final width = fieldValues[0];
          final height = fieldValues[1];
          final num_components = fieldValues[2];

          final textureType = getTextureType(num_components);

          final data = new Uint8Array(4 * width * height);

          final color = { r: 0, g: 0, b: 0, a: 0 };

          for(j in 3...fieldValues.length) {
            parseHexColor(fieldValues[j], textureType, color);

            final stride = (j - 3) * 4;

            data[stride + 0] = color.r;
            data[stride + 1] = color.g;
            data[stride + 2] = color.b;
            data[stride + 3] = color.a;
          }

          texture = new DataTexture(data, width, height);
          texture.colorSpace = SRGBColorSpace;
          texture.needsUpdate = true;
          texture.__type = textureType; // needed for material modifications
          break;
        case "repeatS":
          if(fieldValues[0] == false) wrapS = ClampToEdgeWrapping;
          break;
        case "repeatT":
          if(fieldValues[0] == false) wrapT = ClampToEdgeWrapping;
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    if(texture != null) {
      texture.wrapS = wrapS;
      texture.wrapT = wrapT;
    }

    return texture;
  }

  private function buildImageTextureNode( node:VRMLNode ):DataTexture {
    var texture:DataTexture;
    var wrapS = RepeatWrapping;
    var wrapT = RepeatWrapping;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "url":
          final url = fieldValues[0];
          if(url != null) texture = textureLoader.load(url);
          break;
        case "repeatS":
          if(fieldValues[0] == false) wrapS = ClampToEdgeWrapping;
          break;
        case "repeatT":
          if(fieldValues[0] == false) wrapT = ClampToEdgeWrapping;
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    if(texture != null) {
      texture.wrapS = wrapS;
      texture.wrapT = wrapT;
      texture.colorSpace = SRGBColorSpace;
    }

    return texture;
  }

  private function buildTextureTransformNode( node:VRMLNode ) {
    final transformData = {
      center: new Vector2(),
      rotation: new Vector2(),
      scale: new Vector2(),
      translation: new Vector2()
    };

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "center":
          transformData.center.set(fieldValues[0], fieldValues[1]);
          break;
        case "rotation":
          transformData.rotation = fieldValues[0];
          break;
        case "scale":
          transformData.scale.set(fieldValues[0], fieldValues[1]);
          break;
        case "translation":
          transformData.translation.set(fieldValues[0], fieldValues[1]);
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    return transformData;
  }

  private function buildGeometricNode( node:VRMLNode ) {
    return node.fields[0].values;
  }

  private function buildWorldInfoNode( node:VRMLNode ) {
    final worldInfo = {};

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "title":
          worldInfo.title = fieldValues[0];
          break;
        case "info":
          worldInfo.info = fieldValues;
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    return worldInfo;
  }

  private function buildIndexedFaceSetNode( node:VRMLNode ):BufferGeometry {
    var color:Array<Float>;
    var coord:Array<Float>;
    var normal:Array<Float>;
    var texCoord:Array<Float>;
    var ccw = true;
    var solid = true;
    var creaseAngle = 0;
    var colorIndex:Array<Int>;
    var coordIndex:Array<Int>;
    var normalIndex:Array<Int>;
    var texCoordIndex:Array<Int>;
    var colorPerVertex = true;
    var normalPerVertex = true;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "color":
          final colorNode = fieldValues[0];
          if(colorNode != null) {
            color = getNode(colorNode);
          }
          break;
        case "coord":
          final coordNode = fieldValues[0];
          if(coordNode != null) {
            coord = getNode(coordNode);
          }
          break;
        case "normal":
          final normalNode = fieldValues[0];
          if(normalNode != null) {
            normal = getNode(normalNode);
          }
          break;
        case "texCoord":
          final texCoordNode = fieldValues[0];
          if(texCoordNode != null) {
            texCoord = getNode(texCoordNode);
          }
          break;
        case "ccw":
          ccw = fieldValues[0];
          break;
        case "colorIndex":
          colorIndex = fieldValues;
          break;
        case "colorPerVertex":
          colorPerVertex = fieldValues[0];
          break;
        case "convex":
          // Field not supported
          break;
        case "coordIndex":
          coordIndex = fieldValues;
          break;
        case "creaseAngle":
          creaseAngle = fieldValues[0];
          break;
        case "normalIndex":
          normalIndex = fieldValues;
          break;
        case "normalPerVertex":
          normalPerVertex = fieldValues[0];
          break;
        case "solid":
          solid = fieldValues[0];
          break;
        case "texCoordIndex":
          texCoordIndex = fieldValues;
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    if(coordIndex == null) {
      #if three_debug
      console.warn("THREE.VRMLLoader: Missing coordIndex.");
      #end
      return new BufferGeometry(); // handle VRML files with incomplete geometry definition
    }

    final triangulatedCoordIndex = triangulateFaceIndex(coordIndex, ccw);

    var colorAttribute:BufferAttribute;
    var normalAttribute:BufferAttribute;
    var uvAttribute:BufferAttribute;

    if(color != null) {
      if(colorPerVertex == true) {
        if(colorIndex != null && colorIndex.length > 0) {
          // If the colorIndex field is not empty, then it is used to choose colors for each vertex of the IndexedFaceSet.
          final triangulatedColorIndex = triangulateFaceIndex(colorIndex, ccw);
          colorAttribute = computeAttributeFromIndexedData(triangulatedCoordIndex, triangulatedColorIndex, color, 3);
        } else {
          // If the colorIndex field is empty, then the coordIndex field is used to choose colors from the Color node
          colorAttribute = toNonIndexedAttribute(triangulatedCoordIndex, new Float32BufferAttribute(color, 3));
        }
      } else {
        if(colorIndex != null && colorIndex.length > 0) {
          // If the colorIndex field is not empty, then they are used to choose one color for each face of the IndexedFaceSet
          final flattenFaceColors = flattenData(color, colorIndex);
          final triangulatedFaceColors = triangulateFaceData(flattenFaceColors, coordIndex);
          colorAttribute = computeAttributeFromFaceData(triangulatedCoordIndex, triangulatedFaceColors);
        } else {
          // If the colorIndex field is empty, then the color are applied to each face of the IndexedFaceSet in order
          final triangulatedFaceColors = triangulateFaceData(color, coordIndex);
          colorAttribute = computeAttributeFromFaceData(triangulatedCoordIndex, triangulatedFaceColors);
        }
      }
      convertColorsToLinearSRGB(colorAttribute);
    }

    if(normal != null) {
      if(normalPerVertex == true) {
        // Consider vertex normals
        if(normalIndex != null && normalIndex.length > 0) {
          // If the normalIndex field is not empty, then it is used to choose normals for each vertex of the IndexedFaceSet.
          final triangulatedNormalIndex = triangulateFaceIndex(normalIndex, ccw);
          normalAttribute = computeAttributeFromIndexedData(triangulatedCoordIndex, triangulatedNormalIndex, normal, 3);
        } else {
          // If the normalIndex field is empty, then the coordIndex field is used to choose normals from the Normal node
          normalAttribute = toNonIndexedAttribute(triangulatedCoordIndex, new Float32BufferAttribute(normal, 3));
        }
      } else {
        // Consider face normals
        if(normalIndex != null && normalIndex.length > 0) {
          // If the normalIndex field is not empty, then they are used to choose one normal for each face of the IndexedFaceSet
          final flattenFaceNormals = flattenData(normal, normalIndex);
          final triangulatedFaceNormals = triangulateFaceData(flattenFaceNormals, coordIndex);
          normalAttribute = computeAttributeFromFaceData(triangulatedCoordIndex, triangulatedFaceNormals);
        } else {
          // If the normalIndex field is empty, then the normals are applied to each face of the IndexedFaceSet in order
          final triangulatedFaceNormals = triangulateFaceData(normal, coordIndex);
          normalAttribute = computeAttributeFromFaceData(triangulatedCoordIndex, triangulatedFaceNormals);
        }
      }
    } else {
      // If the normal field is NULL, then the loader should automatically generate normals, using creaseAngle to determine if and how normals are smoothed across shared vertices
      normalAttribute = computeNormalAttribute(triangulatedCoordIndex, coord, creaseAngle);
    }

    if(texCoord != null) {
      // Texture coordinates are always defined on vertex level
      if(texCoordIndex != null && texCoordIndex.length > 0) {
        // If the texCoordIndex field is not empty, then it is used to choose texture coordinates for each vertex of the IndexedFaceSet.
        final triangulatedTexCoordIndex = triangulateFaceIndex(texCoordIndex, ccw);
        uvAttribute = computeAttributeFromIndexedData(triangulatedCoordIndex, triangulatedTexCoordIndex, texCoord, 2);
      } else {
        // If the texCoordIndex field is empty, then the coordIndex array is used to choose texture coordinates from the TextureCoordinate node
        uvAttribute = toNonIndexedAttribute(triangulatedCoordIndex, new Float32BufferAttribute(texCoord, 2));
      }
    }

    final geometry = new BufferGeometry();
    final positionAttribute = toNonIndexedAttribute(triangulatedCoordIndex, new Float32BufferAttribute(coord, 3));

    geometry.setAttribute("position", positionAttribute);
    geometry.setAttribute("normal", normalAttribute);

    // Optional attributes
    if(colorAttribute != null) geometry.setAttribute("color", colorAttribute);
    if(uvAttribute != null) geometry.setAttribute("uv", uvAttribute);

    // "solid" influences the material so let's store it for later use
    geometry._solid = solid;
    geometry._type = "mesh";

    return geometry;
  }

  private function buildIndexedLineSetNode( node:VRMLNode ):BufferGeometry {
    var color:Array<Float>;
    var coord:Array<Float>;
    var colorIndex:Array<Int>;
    var coordIndex:Array<Int>;
    var colorPerVertex = true;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "color":
          final colorNode = fieldValues[0];
          if(colorNode != null) {
            color = getNode(colorNode);
          }
          break;
        case "coord":
          final coordNode = fieldValues[0];
          if(coordNode != null) {
            coord = getNode(coordNode);
          }
          break;
        case "colorIndex":
          colorIndex = fieldValues;
          break;
        case "colorPerVertex":
          colorPerVertex = fieldValues[0];
          break;
        case "coordIndex":
          coordIndex = fieldValues;
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    // Build lines
    var colorAttribute:BufferAttribute;

    final expandedLineIndex = expandLineIndex(coordIndex); // create an index for three.js's linesegment primitive

    if(color != null) {
      if(colorPerVertex == true) {
        if(colorIndex.length > 0) {
          // If the colorIndex field is not empty, then one color is used for each polyline of the IndexedLineSet.
          final expandedColorIndex = expandLineIndex(colorIndex); // compute colors for each line segment (rendering primitve)
          colorAttribute = computeAttributeFromIndexedData(expandedLineIndex, expandedColorIndex, color, 3); // compute data on vertex level
        } else {
          // If the colorIndex field is empty, then the colors are applied to each polyline of the IndexedLineSet in order.
          colorAttribute = toNonIndexedAttribute(expandedLineIndex, new Float32BufferAttribute(color, 3));
        }
      } else {
        if(colorIndex.length > 0) {
          // If the colorIndex field is not empty, then colors are applied to each vertex of the IndexedLineSet
          final flattenLineColors = flattenData(color, colorIndex); // compute colors for each VRML primitve
          final expandedLineColors = expandLineData(flattenLineColors, coordIndex); // compute colors for each line segment (rendering primitve)
          colorAttribute = computeAttributeFromLineData(expandedLineIndex, expandedLineColors); // compute data on vertex level
        } else {
          // If the colorIndex field is empty, then the coordIndex field is used to choose colors from the Color node
          final expandedLineColors = expandLineData(color, coordIndex); // compute colors for each line segment (rendering primitve)
          colorAttribute = computeAttributeFromLineData(expandedLineIndex, expandedLineColors); // compute data on vertex level
        }
      }
      convertColorsToLinearSRGB(colorAttribute);
    }

    final geometry = new BufferGeometry();

    final positionAttribute = toNonIndexedAttribute(expandedLineIndex, new Float32BufferAttribute(coord, 3));
    geometry.setAttribute("position", positionAttribute);

    if(colorAttribute != null) geometry.setAttribute("color", colorAttribute);

    geometry._type = "line";

    return geometry;
  }

  private function buildPointSetNode( node:VRMLNode ):BufferGeometry {
    var color:Array<Float>;
    var coord:Array<Float>;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "color":
          final colorNode = fieldValues[0];
          if(colorNode != null) {
            color = getNode(colorNode);
          }
          break;
        case "coord":
          final coordNode = fieldValues[0];
          if(coordNode != null) {
            coord = getNode(coordNode);
          }
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    final geometry = new BufferGeometry();

    geometry.setAttribute("position", new Float32BufferAttribute(coord, 3));

    if(color != null) {
      final colorAttribute = new Float32BufferAttribute(color, 3);
      convertColorsToLinearSRGB(colorAttribute);
      geometry.setAttribute("color", colorAttribute);
    }

    geometry._type = "points";

    return geometry;
  }

  private function buildBoxNode( node:VRMLNode ):BoxGeometry {
    final size = new Vector3(2, 2, 2);

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "size":
          size.x = fieldValues[0];
          size.y = fieldValues[1];
          size.z = fieldValues[2];
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    final geometry = new BoxGeometry(size.x, size.y, size.z);

    return geometry;
  }

  private function buildConeNode( node:VRMLNode ):ConeGeometry {
    var radius = 1;
    var height = 2;
    var openEnded = false;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "bottom":
          openEnded = !fieldValues[0];
          break;
        case "bottomRadius":
          radius = fieldValues[0];
          break;
        case "height":
          height = fieldValues[0];
          break;
        case "side":
          // Field not supported
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    final geometry = new ConeGeometry(radius, height, 16, 1, openEnded);

    return geometry;
  }

  private function buildCylinderNode( node:VRMLNode ):CylinderGeometry {
    var radius = 1;
    var height = 2;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "bottom":
          // Field not supported
          break;
        case "radius":
          radius = fieldValues[0];
          break;
        case "height":
          height = fieldValues[0];
          break;
        case "side":
          // Field not supported
          break;
        case "top":
          // Field not supported
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    final geometry = new CylinderGeometry(radius, radius, height, 16, 1);

    return geometry;
  }

  private function buildSphereNode( node:VRMLNode ):SphereGeometry {
    var radius = 1;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "radius":
          radius = fieldValues[0];
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    final geometry = new SphereGeometry(radius, 16, 16);

    return geometry;
  }

  private function buildElevationGridNode( node:VRMLNode ):BufferGeometry {
    var color:Array<Float>;
    var normal:Array<Float>;
    var texCoord:Array<Float>;
    var height:Array<Float>;

    var colorPerVertex = true;
    var normalPerVertex = true;
    var solid = true;
    var ccw = true;
    var creaseAngle = 0;
    var xDimension = 2;
    var zDimension = 2;
    var xSpacing = 1;
    var zSpacing = 1;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "color":
          final colorNode = fieldValues[0];
          if(colorNode != null) {
            color = getNode(colorNode);
          }
          break;
        case "normal":
          final normalNode = fieldValues[0];
          if(normalNode != null) {
            normal = getNode(normalNode);
          }
          break;
        case "texCoord":
          final texCoordNode = fieldValues[0];
          if(texCoordNode != null) {
            texCoord = getNode(texCoordNode);
          }
          break;
        case "height":
          height = fieldValues;
          break;
        case "ccw":
          ccw = fieldValues[0];
          break;
        case "colorPerVertex":
          colorPerVertex = fieldValues[0];
          break;
        case "creaseAngle":
          creaseAngle = fieldValues[0];
          break;
        case "normalPerVertex":
          normalPerVertex = fieldValues[0];
          break;
        case "solid":
          solid = fieldValues[0];
          break;
        case "xDimension":
          xDimension = fieldValues[0];
          break;
        case "xSpacing":
          xSpacing = fieldValues[0];
          break;
        case "zDimension":
          zDimension = fieldValues[0];
          break;
        case "zSpacing":
          zSpacing = fieldValues[0];
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    // Vertex data
    final vertices = [];
    final normals = [];
    final colors = [];
    final uvs = [];

    for(i in 0...zDimension) {
      for(j in 0...xDimension) {
        // Compute a row major index
        final index = (i * xDimension) + j;

        // Vertices
        final x = xSpacing * i;
        final y = height[index];
        final z = zSpacing * j;

        vertices.push(x, y, z);

        // Colors
        if(color != null && colorPerVertex == true) {
          final r = color[index * 3 + 0];
          final g = color[index * 3 + 1];
          final b = color[index * 3 + 2];
          colors.push(r, g, b);
        }

        // Normals
        if(normal != null && normalPerVertex == true) {
          final xn = normal[index * 3 + 0];
          final yn = normal[index * 3 + 1];
          final zn = normal[index * 3 + 2];
          normals.push(xn, yn, zn);
        }

        // Uvs
        if(texCoord != null) {
          final s = texCoord[index * 2 + 0];
          final t = texCoord[index * 2 + 1];
          uvs.push(s, t);
        } else {
          uvs.push(i / (xDimension - 1), j / (zDimension - 1));
        }
      }
    }

    // Indices
    final indices = [];

    for(i in 0...xDimension - 1) {
      for(j in 0...zDimension - 1) {
        // From https://tecfa.unige.ch/guides/vrml/vrml97/spec/part1/nodesRef.html#ElevationGrid
        final a = i + j * xDimension;
        final b = i + (j + 1) * xDimension;
        final c = (i + 1) + (j + 1) * xDimension;
        final d = (i + 1) + j * xDimension;

        // Faces
        if(ccw == true) {
          indices.push(a, c, b);
          indices.push(c, a, d);
        } else {
          indices.push(a, b, c);
          indices.push(c, d, a);
        }
      }
    }

    final positionAttribute = toNonIndexedAttribute(indices, new Float32BufferAttribute(vertices, 3));
    final uvAttribute = toNonIndexedAttribute(indices, new Float32BufferAttribute(uvs, 2));
    var colorAttribute:BufferAttribute;
    var normalAttribute:BufferAttribute;

    // Color attribute
    if(color != null) {
      if(colorPerVertex == false) {
        for(i in 0...xDimension - 1) {
          for(j in 0...zDimension - 1) {
            final index = i + j * (xDimension - 1);
            final r = color[index * 3 + 0];
            final g = color[index * 3 + 1];
            final b = color[index * 3 + 2];

            // One color per quad
            colors.push(r, g, b); colors.push(r, g, b); colors.push(r, g, b);
            colors.push(r, g, b); colors.push(r, g, b); colors.push(r, g, b);
          }
        }

        colorAttribute = new Float32BufferAttribute(colors, 3);
      } else {
        colorAttribute = toNonIndexedAttribute(indices, new Float32BufferAttribute(colors, 3));
      }
      convertColorsToLinearSRGB(colorAttribute);
    }

    // Normal attribute
    if(normal != null) {
      if(normalPerVertex == false) {
        for(i in 0...xDimension - 1) {
          for(j in 0...zDimension - 1) {
            final index = i + j * (xDimension - 1);
            final xn = normal[index * 3 + 0];
            final yn = normal[index * 3 + 1];
            final zn = normal[index * 3 + 2];

            // One normal per quad
            normals.push(xn, yn, zn); normals.push(xn, yn, zn); normals.push(xn, yn, zn);
            normals.push(xn, yn, zn); normals.push(xn, yn, zn); normals.push(xn, yn, zn);
          }
        }

        normalAttribute = new Float32BufferAttribute(normals, 3);
      } else {
        normalAttribute = toNonIndexedAttribute(indices, new Float32BufferAttribute(normals, 3));
      }
    } else {
      normalAttribute = computeNormalAttribute(indices, vertices, creaseAngle);
    }

    // Build geometry
    final geometry = new BufferGeometry();
    geometry.setAttribute("position", positionAttribute);
    geometry.setAttribute("normal", normalAttribute);
    geometry.setAttribute("uv", uvAttribute);

    if(colorAttribute != null) geometry.setAttribute("color", colorAttribute);

    // "solid" influences the material so let's store it for later use
    geometry._solid = solid;
    geometry._type = "mesh";

    return geometry;
  }

  private function buildExtrusionNode( node:VRMLNode ):BufferGeometry {
    var crossSection = [1, 1, 1, -1, -1, -1, -1, 1, 1, 1];
    var spine = [0, 0, 0, 0, 1, 0];
    var scale:Array<Float>;
    var orientation:Array<Float>;

    var beginCap = true;
    var ccw = true;
    var creaseAngle = 0;
    var endCap = true;
    var solid = true;

    final fields = node.fields;
    for(i in 0...fields.length) {
      final field = fields[i];
      final fieldName = field.name;
      final fieldValues = field.values;

      switch(fieldName) {
        case "beginCap":
          beginCap = fieldValues[0];
          break;
        case "ccw":
          ccw = fieldValues[0];
          break;
        case "convex":
          // Field not supported
          break;
        case "creaseAngle":
          creaseAngle = fieldValues[0];
          break;
        case "crossSection":
          crossSection = fieldValues;
          break;
        case "endCap":
          endCap = fieldValues[0];
          break;
        case "orientation":
          orientation = fieldValues;
          break;
        case "scale":
          scale = fieldValues;
          break;
        case "solid":
          solid = fieldValues[0];
          break;
        case "spine":
          spine = fieldValues; // only extrusion along the Y-axis are supported so far
          break;
        default:
          #if three_debug
          console.warn("THREE.VRMLLoader: Unknown field:", fieldName);
          #end
          break;
      }
    }

    final crossSectionClosed = (crossSection[0] == crossSection[crossSection.length - 2] && crossSection[1] == crossSection[crossSection.length - 1]);

    // Vertices
    final vertices = [];
    final spineVector = new Vector3();
    final scaling = new Vector3();

    final axis = new Vector3();
    final vertex = new Vector3();
    final quaternion = new Quaternion();

    for(i in 0...spine.length) {
      if(i % 3 == 0) {
        spineVector.fromArray(spine, i);
        final j = (i / 3) * 2;
        final o = (i / 3) * 4;

        scaling.x = (scale != null) ? scale[j + 0] : 1;
        scaling.y = 1;
        scaling.z = (scale != null) ? scale[j + 1] : 1;

        axis.x = (orientation != null) ? orientation[o + 0] : 0;
        axis.y = (orientation != null) ? orientation[o + 1] : 0;
        axis.z = (orientation != null) ? orientation[o + 2] : 1;
        final angle = (orientation != null) ? orientation[o + 3] : 0;
        for(k in 0...crossSection.length) {
          if(k % 2 == 0) {
            vertex.x = crossSection[k + 0];
            vertex.y = 0;
            vertex.z = crossSection[k + 1];

            // Scale
            vertex.multiply(scaling);

            // Rotate
            quaternion.setFromAxisAngle(axis, angle);
            vertex.applyQuaternion(quaternion);

            // Translate
            vertex.add(spineVector);

            vertices.push(vertex.x, vertex.y, vertex.z);
          }
        }
      }
    }

    // Indices
    final indices = [];

    final spineCount = spine.length / 3;
    final crossSectionCount = crossSection.length / 2;

    for(i in 0...spineCount - 1) {
      for(j in 0...crossSectionCount - 1) {
        final a = j + i * crossSectionCount;
        var b = (j + 1) + i * crossSectionCount;
        final c = j + (i + 1) * crossSectionCount;
        var d = (j + 1) + (i + 1) * crossSectionCount;

        if((j == crossSectionCount - 2) && (crossSectionClosed == true)) {
          b = i * crossSectionCount;
          d = (i + 1) * crossSectionCount;
        }

        if(ccw == true) {
          indices.push(a, b, c);
          indices.push(c, b, d);
        } else {
          indices.push(a, c, b);
          indices.push(c, d, b);
        }
      }
    }

    // Triangulate cap
    if(beginCap == true || endCap == true) {
      final contour = [];

      for(i in 0...crossSection.length) {
        if(i % 2 == 0) {
          contour.push(new Vector2(crossSection[i], crossSection[i + 1]));
        }
      }

      final faces = ShapeUtils.triangulateShape(contour, []);
      final capIndices = [];

      for(i in 0...faces.length) {
        final face = faces[i];
        capIndices.push(face[0], face[1], face[2]);
      }

      // Begin cap
      if(beginCap == true) {
        for(i in 0...capIndices.length) {
          if(i % 3 == 0) {
            if(ccw == true) {
              indices.push(capIndices[i + 0], capIndices[i + 1], capIndices[i + 2]);
            } else {
              indices.push(capIndices[i + 0], capIndices[i + 2], capIndices[i + 1]);
            }
          }
        }
      }

      // End cap
      if(endCap == true) {
        final indexOffset = crossSectionCount * (spineCount - 1); // references to the first vertex of the last cross section

        for(i in 0...capIndices.length) {
          if(i % 3 == 0) {
            if(ccw == true) {
              indices.push(indexOffset + capIndices[i + 0], indexOffset + capIndices[i + 2], indexOffset + capIndices[i + 1]);
            } else {
              indices.push(indexOffset + capIndices[i + 0], indexOffset + capIndices[i + 1], indexOffset + capIndices[i + 2]);
            }
          }
        }
      }
    }

    final positionAttribute = toNonIndexedAttribute(indices, new Float32BufferAttribute(vertices, 3));
    final normalAttribute = computeNormalAttribute(indices, vertices, creaseAngle);

    final geometry = new BufferGeometry();
    geometry.setAttribute("position", positionAttribute);
    geometry.setAttribute("normal", normalAttribute);
    // no uvs yet

    // "solid" influences the material so let's store it for later use
    geometry._solid = solid;
    geometry._type = "mesh";

    return geometry;
  }

  // helper functions

  private function resolveUSE( identifier:String ) {
    final node = nodeMap.get(identifier);
    final build = getNode(node);

    // because the same 3D objects can have different transformations, it's necessary to clone them.
    // materials can be influenced by the geometry (e.g. vertex normals). cloning is necessary to avoid
    // any side effects
    return (build is Object3D || build is MeshPhongMaterial || build is MeshBasicMaterial || build is PointsMaterial || build is LineBasicMaterial) ? build.clone() : build;
  }

  private function parseFieldChildren( children:Array<VRMLNode>, owner:Group ) {
    for(i in 0...children.length) {
      final object = getNode(children[i]);
      if(object is Object3D) owner.add(object);
    }
  }

  private function triangulateFaceIndex( index:Array<Int>, ccw:Bool ) {
    final indices = [];

    // since face defintions can have more than three vertices, it's necessary to
    // perform a simple triangulation

    var start = 0;

    for(i in 0...index.length) {
      final i1 = index[start];
      final i2 = index[i + (ccw ? 1 : 2)];
      final i3 = index[i + (ccw ? 2 : 1)];

      indices.push(i1, i2, i3);

      // an index of -1 indicates that the current face has ended and the next one begins
      if(index[i + 3] == - 1 || i + 3 >= index.length) {
        i += 3;
        start = i + 1;
      }
    }

    return indices;
  }

  private function triangulateFaceData( data:Array<Float>, index:Array<Int> ) {
    final triangulatedData = [];

    var start = 0;

    for(i in 0...index.length) {
      final stride = start * 3;

      final x = data[stride];
      final y = data[stride + 1];
      final z = data[stride + 2];

      triangulatedData.push(x, y, z);

      // an index of -1 indicates that the current face has ended and the next one begins
      if(index[i + 3] == - 1 || i + 3 >= index.length) {
        i += 3;
        start++;
      }
    }

    return triangulatedData;
  }

  private function flattenData( data:Array<Float>, index:Array<Int> ) {
    final flattenData = [];

    for(i in 0...index.length) {
      final i1 = index[i];

      final stride = i1 * 3;

      final x = data[stride];
      final y = data[stride + 1];
      final z = data[stride + 2];

      flattenData.push(x, y, z);
    }

    return flattenData;
  }

  private function expandLineIndex( index:Array<Int> ) {
    final indices = [];

    for(i in 0...index.length) {
      final i1 = index[i];
      final i2 = index[i + 1];

      indices.push(i1, i2);

      // an index of -1 indicates that the current line has ended and the next one begins
      if(index[i + 2] == - 1 || i + 2 >= index.length) {
        i += 2;
      }
    }

    return indices;
  }

  private function expandLineData( data:Array<Float>, index:Array<Int> ) {
    final triangulatedData = [];

    var start = 0;

    for(i in 0...index.length) {
      final stride = start * 3;

      final x = data[stride];
      final y = data[stride + 1];
      final z = data[stride + 2];

      triangulatedData.push(x, y, z);

      // an index of -1 indicates that the current line has ended and the next one begins
      if(index[i + 2] == - 1 || i + 2 >= index.length) {
        i += 2;
        start++;
      }
    }

    return triangulatedData;
  }

  private final vA = new Vector3();
  private final vB = new Vector3();
  private final vC = new Vector3();

  private final uvA = new Vector2();
  private final uvB = new Vector2();
  private final uvC = new Vector2();

  private function computeAttributeFromIndexedData( coordIndex:Array<Int>, index:Array<Int>, data:Array<Float>, itemSize:Int ):BufferAttribute {
    final array = [];

    // we use the coordIndex.length as delimiter since normalIndex must contain at least as many indices
    for(i in 0...coordIndex.length) {
      if(i % 3 == 0) {
        final a = index[i];
        final b = index[i + 1];
        final c = index[i + 2];

        if(itemSize == 2) {
          uvA.fromArray(data, a * itemSize);
          uvB.fromArray(data, b * itemSize);
          uvC.fromArray(data, c * itemSize);

          array.push(uvA.x, uvA.y);
          array.push(uvB.x, uvB.y);
          array.push(uvC.x, uvC.y);
        } else {
          vA.fromArray(data, a * itemSize);
          vB.fromArray(data, b * itemSize);
          vC.fromArray(data, c * itemSize);

          array.push(vA.x, vA.y, vA.z);
          array.push(vB.x, vB.y, vB.z);
          array.push(vC.x, vC.y, vC.z);
        }
      }
    }

    return new Float32BufferAttribute(array, itemSize);
  }

  private function computeAttributeFromFaceData( index:Array<Int>, faceData:Array<Float> ):BufferAttribute {
    final array = [];

    for(i in 0...index.length) {
      if(i % 3 == 0) {
        final j = i / 3;
        vA.fromArray(faceData, j * 3);

        array.push(vA.x, vA.y, vA.z);
        array.push(vA.x, vA.y, vA.z);
        array.push(vA.x, vA.y, vA.z);
      }
    }

    return new Float32BufferAttribute(array, 3);
  }

  private function computeAttributeFromLineData( index:Array<Int>, lineData:Array<Float> ):BufferAttribute {
    final array = [];

    for(i in 0...index.length) {
      if(i % 2 == 0) {
        final j = i / 2;
        vA.fromArray(lineData, j * 3);

        array.push(vA.x, vA.y, vA.z);
        array.push(vA.x, vA.y, vA.z);
      }
    }

    return new Float32BufferAttribute(array, 3);
  }

  private function toNonIndexedAttribute( indices:Array<Int>, attribute:BufferAttribute ):BufferAttribute {
    final array = attribute.array;
    final itemSize = attribute.itemSize;

    final array2 = new attribute.array.constructor(indices.length * itemSize);

    var index = 0;
    var index2 = 0;

    for(i in 0...indices.length) {
      index = indices[i] * itemSize;

      for(j in 0...itemSize) {
        array2[index2++] = array[index++];
      }
    }

    return new Float32BufferAttribute(array2, itemSize);
  }

  private final ab = new Vector3();
  private final cb = new Vector3();

  private function computeNormalAttribute( index:Array<Int>, coord:Array<Float>, creaseAngle:Float ):BufferAttribute {
    final faces = [];
    final vertexNormals = new StringMap<Array<Vector3>>();

    // prepare face and raw vertex normals
    for(i in 0...index.length) {
      if(i % 3 == 0) {
        final a = index[i];
        final b = index[i + 1];
        final c = index[i + 2];

        final face = new Face(a, b, c);

        vA.fromArray(coord, a * 3);
        vB.fromArray(coord, b * 3);
        vC.fromArray(coord, c * 3);

        cb.subVectors(vC, vB);
        ab.subVectors(vA, vB);
        cb.cross(ab);

        cb.normalize();

        face.normal.copy(cb);

        if(!vertexNormals.exists(a.toString())) vertexNormals.set(a.toString(), []);
        if(!vertexNormals.exists(b.toString())) vertexNormals.set(b.toString(), []);
        if(!vertexNormals.exists(c.toString())) vertexNormals.set(c.toString(), []);

        vertexNormals.get(a.toString()).push(face.normal);
        vertexNormals.get(b.toString()).push(face.normal);
        vertexNormals.get(c.toString()).push(face.normal);

        faces.push(face);
      }
    }

    // compute vertex normals and build final geometry
    final normals = [];

    for(i in 0...faces.length) {
      final face = faces[i];

      final nA = weightedNormal(vertexNormals.get(face.a.toString()), face.normal, creaseAngle);
      final nB = weightedNormal(vertexNormals.get(face.b.toString()), face.normal, creaseAngle);
      final nC = weightedNormal(vertexNormals.get(face.c.toString()), face.normal, creaseAngle);

      vA.fromArray(coord, face.a * 3);
      vB.fromArray(coord, face.b * 3);
      vC.fromArray(coord, face.c * 3);

      normals.push(nA.x, nA.y, nA.z);
      normals.push(nB.x, nB.y, nB.z);
      normals.push(nC.x, nC.y, nC.z);
    }

    return new Float32BufferAttribute(normals, 3);
  }

  private function weightedNormal( normals:Array<Vector3>, vector:Vector3, creaseAngle:Float ):Vector3 {
    final normal = new Vector3();

    if(creaseAngle == 0) {
      normal.copy(vector);
    } else {
      for(i in 0...normals.length) {
        if(normals[i].angleTo(vector) < creaseAngle) {
          normal.add(normals[i]);
        }
      }
    }

    return normal.normalize();
  }

  private function toColorArray( colors:Array<Float> ) {
    final array = [];

    for(i in 0...colors.length) {
      if(i % 3 == 0) {
        array.push(new Color(colors[i], colors[i + 1], colors[i + 2]));
      }
    }

    return array;
  }

  private function convertColorsToLinearSRGB( attribute:BufferAttribute ) {
    final color = new Color();

    for(i in 0...attribute.count) {
      color.fromBufferAttribute(attribute, i);
      color.convertSRGBToLinear();
      attribute.setXYZ(i, color.r, color.g, color.b);
    }
  }

  /**
   * Vertically paints the faces interpolating between the
   * specified colors at the specified angels. This is used for the Background
   * node, but could be applied to other nodes with multiple faces as well.
   *
   * When used with the Background node, default is directionIsDown is true if
   * interpolating the skyColor down from the Zenith. When interpolationg up from
   * the Nadir i.e. interpolating the groundColor, the directionIsDown is false.
   *
   * The first angle is never specified, it is the Zenith (0 rad). Angles are specified
   * in radians. The geometry is thought a sphere, but could be anything. The color interpolation
   * is linear along the Y axis in any case.
   *
   * You must specify one more color than you have angles at the beginning of the colors array.
   * This is the color of the Zenith (the top of the shape).
   *
   * @param {BufferGeometry} geometry
   * @param {number} radius
   * @param {array} angles
   * @param {array} colors
   * @param {boolean} topDown - Whether to work top down or bottom up.
   */
  private function paintFaces( geometry:BufferGeometry, radius:Float, angles:Array<Float>, colors:Array<Color>, topDown:Bool ) {
    // compute threshold values
    final thresholds = [];
    final startAngle = (topDown) ? 0 : Math.PI;

    for(i in 0...colors.length) {
      var angle = (i == 0) ? 0 : angles[i - 1];
      angle = (topDown) ? angle : (startAngle - angle);

      final point = new Vector3();
      point.setFromSphericalCoords(radius, angle, 0);

      thresholds.push(point);
    }

    // generate vertex colors
    final indices = geometry.index;
    final positionAttribute = geometry.attributes.position;
    final colorAttribute = new BufferAttribute(new Float32Array(geometry.attributes.position.count * 3), 3);

    final position = new Vector3();
    final color = new Color();

    for(i in 0...indices.count) {
      final index = indices.getX(i);
      position.fromBufferAttribute(positionAttribute, index);

      var thresholdIndexA:Int;
      var thresholdIndexB:Int;
      var t = 1;

      for(j in 1...thresholds.length) {
        thresholdIndexA = j - 1;
        thresholdIndexB = j;

        final thresholdA = thresholds[thresholdIndexA];
        final thresholdB = thresholds[thresholdIndexB];

        if(topDown) {
          // interpolation for sky color
          if(position.y <= thresholdA.y && position.y > thresholdB.y) {
            t = Math.abs(thresholdA.y - position.y) / Math.abs(thresholdA.y - thresholdB.y);
            break;
          }
        } else {
          // interpolation for ground color
          if(position.y >= thresholdA.y && position.y < thresholdB.y) {
            t = Math.abs(thresholdA.y - position.y) / Math.abs(thresholdA.y - thresholdB.y);
            break;
          }
        }
      }

      final colorA = colors[thresholdIndexA];
      final colorB = colors[thresholdIndexB];

      color.copy(colorA).lerp(colorB, t).convertSRGBToLinear();

      colorAttribute.setXYZ(index, color.r, color.g, color.b);
    }

    geometry.setAttribute("color", colorAttribute);
  }

  private final textureLoader = new TextureLoader(manager);

  // check version (only 2.0 is supported)
  private function checkVersion(data:String) {
    if(data.indexOf("#VRML V2.0") == - 1) {
      throw "THREE.VRMLLexer: Version of VRML asset not supported.";
    }
  }

  // create JSON representing the tree structure of the VRML asset
  private function generateVRMLTree( data:String ):Dynamic {
    final tokenData = createTokens();
    final lexer = new VRMLLexer(tokenData.tokens);
    final parser = new VRMLParser(tokenData.tokenVocabulary);
    final visitor = createVisitor(parser.getBaseCstVisitorConstructor());

    // Lexing
    final lexingResult = lexer.lex(data);
    parser.input = lexingResult.tokens;

    // Parsing
    final cstOutput = parser.vrml();

    if(parser.errors.length > 0) {
      #if three_debug
      console.error(parser.errors);
      #end
      throw "THREE.VRMLLoader: Parsing errors detected.";
    }

    // Actions
    return visitor.visit(cstOutput);
  }

  // parse the tree structure to a three.js scene
  private function parseTree( tree:Dynamic ):Scene {
    final nodes = tree.nodes;
    final scene = new Scene();

    // first iteration: build nodemap based on DEF statements
    for(i in 0...nodes.length) {
      final node = nodes[i];
      buildNodeMap(node);
    }

    // second iteration: build nodes
    for(i in 0...nodes.length) {
      final node = nodes[i];
      final object = getNode(node);
      if(object is Object3D) scene.add(object);
      if(node.name == "WorldInfo") scene.userData.worldInfo = object;
    }

    return scene;
  }

  private function resolveUSE( identifier:String ) {
    final node = nodeMap.get(identifier);
    final build = getNode(node);

    // because the same 3D objects can have different transformations, it's necessary to clone them.
    // materials can be influenced by the geometry (e.g. vertex normals). cloning is necessary to avoid
    // any side effects
    return (build is Object3D || build is MeshPhongMaterial || build is MeshBasicMaterial || build is PointsMaterial || build is LineBasicMaterial) ? build.clone() : build;
  }

  private function parseFieldChildren( children:Array<VRMLNode>, owner:Group ) {
    for(i in 0...children.length) {
      final object = getNode(children[i]);
      if(object is Object3D) owner.add(object);
    }
  }

  public function dispose() {
    textureLoader.dispose();
  }

}

class VRMLLexer extends Lexer {

  public function new( tokens:Array<Token> ) {
    super(tokens);
  }

  public function lex( inputText:String ) {
    final lexingResult = tokenize(inputText);
    if(lexingResult.errors.length > 0) {
      #if three_debug
      console.error(lexingResult.errors);
      #end
      throw "THREE.VRMLLexer: Lexing errors detected.";
    }
    return lexingResult;
  }

}

class VRMLParser extends Parser {

  public function new( tokenVocabulary:StringMap<Token> ) {
    super(tokenVocabulary);

    final $ = this;

    final Version = tokenVocabulary.get("Version");
    final LCurly = tokenVocabulary.get("LCurly");
    final RCurly = tokenVocabulary.get("RCurly");
    final LSquare = tokenVocabulary.get("LSquare");
    final RSquare = tokenVocabulary.get("RSquare");
    final Identifier = tokenVocabulary.get("Identifier");
    final RouteIdentifier = tokenVocabulary.get("RouteIdentifier");
    final StringLiteral = tokenVocabulary.get("StringLiteral");
    final HexLiteral = tokenVocabulary.get("HexLiteral");
    final NumberLiteral = tokenVocabulary.get("NumberLiteral");
    final TrueLiteral = tokenVocabulary.get("TrueLiteral");
    final FalseLiteral = tokenVocabulary.get("FalseLiteral");
    final NullLiteral = tokenVocabulary.get("NullLiteral");
    final DEF = tokenVocabulary.get("DEF");
    final USE = tokenVocabulary.get("USE");
    final ROUTE = tokenVocabulary.get("ROUTE");
    final TO = tokenVocabulary.get("TO");
    final NodeName = tokenVocabulary.get("NodeName");

    $.RULE("vrml", function() {
      $.SUBRULE($.version);
      $.AT_LEAST_ONE(function() {
        $.SUBRULE($.node);
      });
      $.MANY(function() {
        $.SUBRULE($.route);
      });
    });

    $.RULE("version", function() {
      $.CONSUME(Version);
    });

    $.RULE("node", function() {
      $.OPTION(function() {
        $.SUBRULE($.def);
      });
      $.CONSUME(NodeName);
      $.CONSUME(LCurly);
      $.MANY(function() {
        $.SUBRULE($.field);
      });
      $.CONSUME(RCurly);
    });

    $.RULE("field", function() {
      $.CONSUME(Identifier);
      $.OR2([
        { ALT: function() {
          $.SUBRULE($.singleFieldValue);
        } },
        { ALT: function() {
          $.SUBRULE($.multiFieldValue);
        } }
      ]);
    });

    $.RULE("def", function() {
      $.CONSUME(DEF);
      $.OR([
        { ALT: function() {
          $.CONSUME(Identifier);
        } },
        { ALT: function() {
          $.CONSUME(NodeName);
        } }
      ]);
    });

    $.RULE("use", function() {
      $.CONSUME(USE);
      $.OR([
        { ALT: function() {
          $.CONSUME(Identifier);
        } },
        { ALT: function() {
          $.CONSUME(NodeName);
        } }
      ]);
    });

    $.RULE("singleFieldValue", function() {
      $.AT_LEAST_ONE(function() {
        $.OR([
          { ALT: function() {
            $.SUBRULE($.node);
          } },
          { ALT: function() {
            $.SUBRULE($.use);
          } },
          { ALT: function() {
            $.CONSUME(StringLiteral);
          } },
          { ALT: function() {
            $.CONSUME(HexLiteral);
          } },
          { ALT: function() {
            $.CONSUME(NumberLiteral);
          } },
          { ALT: function() {
            $.CONSUME(TrueLiteral);
          } },
          { ALT: function() {
            $.CONSUME(FalseLiteral);
          } },
          { ALT: function() {
            $.CONSUME(NullLiteral);
          } }
        ]);
      });
    });

    $.RULE("multiFieldValue", function() {
      $.CONSUME(LSquare);
      $.MANY(function() {
        $.OR([
          { ALT: function() {
            $.SUBRULE($.node);
          } },
          { ALT: function() {
            $.SUBRULE($.use);
          } },
          { ALT: function() {
            $.CONSUME(StringLiteral);
          } },
          { ALT: function() {
            $.CONSUME(HexLiteral);
          } },
          { ALT: function() {
            $.CONSUME(NumberLiteral);
          } },
          { ALT: function() {
            $.CONSUME(NullLiteral);
          } }
        ]);
      });
      $.CONSUME(RSquare);
    });

    $.RULE("route", function() {
      $.CONSUME(ROUTE);
      $.CONSUME(RouteIdentifier);
      $.CONSUME(TO);
      $.CONSUME2(RouteIdentifier);
    });

    this.performSelfAnalysis();
  }

}

class Face {

  public var a:Int;
  public var b:Int;
  public var c:Int;
  public var normal:Vector3;

  public function new( a:Int, b:Int, c:Int ) {
    this.a = a;
    this.b = b;
    this.c = c;
    this.normal = new Vector3();
  }

}

enum TEXTURE_TYPE {
  INTENSITY;
  INTENSITY_ALPHA;
  RGB;
  RGBA;
}

typedef VRMLNode = {
  name:String;
  DEF:String;
  USE:String;
  fields:Array<{
    name:String;
    type:String;
    values:Dynamic;
  }>;
  build:Dynamic;
};

export { VRMLLoader };