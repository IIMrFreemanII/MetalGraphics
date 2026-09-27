import simd

/// A 64-bit hash of what a shape looks like, built field by field — never from raw bytes, whose
/// padding Swift leaves undefined. `GraphicsGrid2D` folds these per cell to find the cells whose
/// pixels changed since the last frame. Only compared within one run, so any good mix will do.
struct ContentHash {
  private(set) var value: UInt64 = 0xCBF2_9CE4_8422_2325

  @inline(__always)
  mutating func add(_ word: UInt64) {
    self.value = (self.value ^ word) &* 0x9E37_79B9_7F4A_7C15
    self.value ^= self.value >> 29
  }

  @inline(__always)
  mutating func add(_ value: Float) {
    self.add(UInt64(value.bitPattern))
  }

  @inline(__always)
  mutating func add(_ value: Int32) {
    self.add(UInt64(UInt32(bitPattern: value)))
  }

  @inline(__always)
  mutating func add(_ value: UInt32) {
    self.add(UInt64(value))
  }

  @inline(__always)
  mutating func add(_ value: float2) {
    self.add(UInt64(value.x.bitPattern) << 32 | UInt64(value.y.bitPattern))
  }

  @inline(__always)
  mutating func add(_ value: float4) {
    self.add(UInt64(value.x.bitPattern) << 32 | UInt64(value.y.bitPattern))
    self.add(UInt64(value.z.bitPattern) << 32 | UInt64(value.w.bitPattern))
  }
}

// What each shape hashes: everything the shader reads, but not its depth. Depths count every
// draw of the frame, so one shape added anywhere would shift them all; the order of the shapes
// within a cell, which is what depth decides, is hashed by the cell instead.

extension Circle2D {
  var contentHash: UInt64 {
    var hash = ContentHash()
    hash.add(self.position)
    hash.add(self.radius)
    hash.add(self.color)
    return hash.value
  }
}

extension Square {
  var contentHash: UInt64 {
    var hash = ContentHash()
    hash.add(self.position)
    hash.add(self.size)
    hash.add(self.rotation)
    hash.add(self.color)
    return hash.value
  }
}

extension Line {
  var contentHash: UInt64 {
    var hash = ContentHash()
    hash.add(self.start)
    hash.add(self.end)
    hash.add(self.color)
    hash.add(self.thickness)
    return hash.value
  }
}

extension Glyph {
  var contentHash: UInt64 {
    var hash = ContentHash()
    hash.add(self.position)
    hash.add(self.size)
    hash.add(self.uvMin)
    hash.add(self.uvMax)
    hash.add(self.color)
    hash.add(self.fontSize)
    hash.add(self.blur)
    return hash.value
  }
}

extension ImageQuad {
  /// `texture` stands in for `textureIndex`, which counts textures in the order this frame
  /// first drew them.
  func contentHash(texture: ObjectIdentifier) -> UInt64 {
    var hash = ContentHash()
    hash.add(self.position)
    hash.add(self.size)
    hash.add(self.uvMin)
    hash.add(self.uvMax)
    hash.add(self.tint)
    hash.add(UInt64(UInt(bitPattern: texture)))
    hash.add(self.flags)
    hash.add(self.lod)
    return hash.value
  }
}

extension VectorItem {
  var contentHash: UInt64 {
    var hash = ContentHash()
    hash.add(self.row0)
    // `row1.w` is the depth.
    hash.add(float4(self.row1.x, self.row1.y, self.row1.z, 0))
    hash.add(self.params0)
    hash.add(self.params1)
    hash.add(self.color)
    hash.add(self.clip)
    hash.add(self.stroke)
    hash.add(self.kind)
    hash.add(self.flags)
    hash.add(self.blur)
    return hash.value
  }
}

extension GlassItem {
  /// Not where its backdrop landed in the atlas, which is packed anew every frame: what it
  /// shows through is accounted for by `Graphics2D.damageGlasses`.
  var contentHash: UInt64 {
    var hash = ContentHash()
    hash.add(self.rect)
    hash.add(self.radii)
    hash.add(self.tint)
    hash.add(self.sceneOrigin)
    hash.add(self.regionMax - self.regionMin)
    hash.add(self.pointsPerTexel)
    hash.add(self.saturation)
    hash.add(self.noise)
    hash.add(self.opacity)
    return hash.value
  }
}

extension GPUClip {
  /// `rounded` is the hash of the clip it chains to, which comes earlier in the table.
  func contentHash(rounded: UInt64) -> UInt64 {
    var hash = ContentHash()
    hash.add(self.bounds)
    hash.add(self.rect)
    hash.add(self.radii)
    hash.add(self.blur)
    hash.add(rounded)
    return hash.value
  }
}
