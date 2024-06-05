import qunit.QUnit;
import three.textures.Texture;
import three.core.EventDispatcher;

class TextureTest extends QUnit.Test {
  public function new() {
    super();
  }

  override function test(assert:QUnit.Assert) {
    // INHERITANCE
    assert.ok(new Texture() instanceof EventDispatcher, 'Texture extends from EventDispatcher');

    // INSTANCING
    assert.ok(new Texture() != null, 'Can instantiate a Texture.');

    // PROPERTIES
    // TODO: image
    // TODO: id
    // TODO: uuid
    // TODO: name
    // TODO: source
    // TODO: mipmaps
    // TODO: mapping
    // TODO: wrapS
    // TODO: wrapT
    // TODO: magFilter
    // TODO: minFilter
    // TODO: anisotropy
    // TODO: format
    // TODO: internalFormat
    // TODO: type
    // TODO: offset
    // TODO: repeat
    // TODO: center
    // TODO: rotation
    // TODO: matrixAutoUpdate
    // TODO: matrix
    // TODO: generateMipmaps
    // TODO: premultiplyAlpha
    // TODO: flipY
    // TODO: unpackAlignment
    // TODO: colorSpace
    // TODO: userData
    // TODO: version
    // TODO: onUpdate
    // TODO: needsPMREMUpdate

    // PUBLIC
    assert.ok(new Texture().isTexture, 'Texture.isTexture should be true');

    // TODO: updateMatrix
    // TODO: clone
    // TODO: copy
    // TODO: toJSON

    assert.expect(0);
    new Texture().dispose();

    // TODO: transformUv
  }
}

class TextureModule extends QUnit.Module {
  public function new() {
    super('Textures');
  }

  override function init(assert:QUnit.Assert) {
    new QUnit.Module('Texture', this).test(new TextureTest());
  }
}

QUnit.module(new TextureModule());