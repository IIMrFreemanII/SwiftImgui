import MetalKit

enum TextureController {
  static var textures: [String: MTLTexture] = [:]
  
  static func makeTexture(_ data: inout [uchar4], _ size: int2) -> MTLTexture {
    // Create a texture descriptor
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.pixelFormat = .rgba8Unorm
    textureDescriptor.width = size.x
    textureDescriptor.height = size.y
    textureDescriptor.usage = [.shaderRead, .shaderWrite]
    
    // Create the texture
    let texture = Renderer.device.makeTexture(descriptor: textureDescriptor)!
    let region = MTLRegionMake2D(0, 0, size.x, size.y)
    texture.replace(region: region, mipmapLevel: 0, withBytes: &data, bytesPerRow: size.x * 4)
    
    return texture
  }
  
  static func texture(filename: String) -> MTLTexture? {
    if let texture = textures[filename] {
      return texture
    }
    let texture = try? loadTexture(filename: filename)
    if texture != nil {
      textures[filename] = texture
    }
    return texture
  }
  
  static func loadTexture(filename: String) throws -> MTLTexture? {
    // 1
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    if let texture = try? textureLoader.newTexture(
      name: filename,
      scaleFactor: 1.0,
      bundle: Bundle.main,
      options: nil
    ) {
      print("loaded texture: \(filename)")
      return texture
    }
    
    // 2
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
      .origin: MTKTextureLoader.Origin.bottomLeft,
      .SRGB: false,
      .generateMipmaps: NSNumber(value: true)
    ]
    // 3
    let fileExtension = URL(fileURLWithPath: filename).pathExtension.isEmpty ? "png" : nil
    // 4
    guard let url = Bundle.main.url(
      forResource: filename,
      withExtension: fileExtension)
    else {
      print("Failed to load \(filename)")
      return nil
    }
    let texture = try textureLoader.newTexture(
      URL: url,
      options: textureLoaderOptions)
    print("loaded texture: \(url.lastPathComponent)")
    return texture
  }
  
  // load from USDZ file
  static func loadTexture(texture: MDLTexture) throws -> MTLTexture? {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
      .origin: MTKTextureLoader.Origin.bottomLeft,
      .SRGB: false,
      .generateMipmaps: NSNumber(booleanLiteral: false)
    ]
    let texture = try? textureLoader.newTexture(
      texture: texture,
      options: textureLoaderOptions)
    print("loaded texture from MDLTexture")
    if texture != nil {
      let filename = UUID().uuidString
      textures[filename] = texture
    }
    return texture
  }
  
  // load a cube texture
  static func loadCubeTexture(imageName: String) throws -> MTLTexture {
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    if let texture = MDLTexture(cubeWithImagesNamed: [imageName]) {
      let options: [MTKTextureLoader.Option: Any] = [
        .origin: MTKTextureLoader.Origin.topLeft,
        .SRGB: false,
        .generateMipmaps: NSNumber(booleanLiteral: false)
      ]
      return try textureLoader.newTexture(
        texture: texture,
        options: options)
    }
    let texture = try textureLoader.newTexture(
      name: imageName,
      scaleFactor: 1.0,
      bundle: .main)
    return texture
  }
}
