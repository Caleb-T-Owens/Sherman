# CTech

A Minecraft b1.7.3 mod built with StationAPI and Fabric. Adds technology blocks that scale responsibly.

## Setup

Requires Java 21. Uses SDKMAN (see `.sdkmanrc`).

```bash
./gradlew runClient
```

## Adding a New Block

### 1. Create the block class

For a simple block:

```java
// src/main/java/je/cto/ctech/block/MyBlock.java
package je.cto.ctech.block;

import net.minecraft.block.material.Material;
import net.modificationstation.stationapi.api.template.block.TemplateBlock;
import net.modificationstation.stationapi.api.util.Identifier;

public class MyBlock extends TemplateBlock {
    public MyBlock(Identifier id) {
        super(id, Material.METAL);
    }
}
```

For a block with a tile entity:

```java
// src/main/java/je/cto/ctech/block/MyBlock.java
package je.cto.ctech.block;

import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.material.Material;
import net.modificationstation.stationapi.api.template.block.TemplateBlockWithEntity;
import net.modificationstation.stationapi.api.util.Identifier;

public class MyBlock extends TemplateBlockWithEntity {
    public MyBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    protected BlockEntity createBlockEntity() {
        return new MyBlockEntity();
    }
}
```

### 2. Create the tile entity (if needed)

```java
// src/main/java/je/cto/ctech/blockentity/MyBlockEntity.java
package je.cto.ctech.blockentity;

import net.minecraft.block.entity.BlockEntity;

public class MyBlockEntity extends BlockEntity {
    @Override
    public void tick() {
        // Called every game tick
    }
}
```

### 3. Register in CTech.java

Add static fields:

```java
public static Identifier myBlockId;
public static Identifier myBlockTextureId;
public static Block myBlock;
public static int myBlockTexture;
```

Register in `registerBlocks`:

```java
myBlockId = NAMESPACE.id("my_block");
myBlockTextureId = NAMESPACE.id("block/my_block");
myBlock = new MyBlock(myBlockId).setTranslationKey(myBlockId);
```

Register texture in `registerTextures`:

```java
myBlockTexture = terrainAtlas.addTexture(CTech.myBlockTextureId).index;
CTech.myBlock.textureId = myBlockTexture;
```

If you have a tile entity, register it in `registerBlockEntities`:

```java
event.register(MyBlockEntity.class, myBlockId.toString());
```

### 4. Add assets

Create these files:

**Blockstate** (`src/main/resources/assets/ctech/stationapi/blockstates/my_block.json`):

```json
{
    "variants": {
        "": { "model": "ctech:block/my_block" }
    }
}
```

**Block model** (`src/main/resources/assets/ctech/stationapi/models/block/my_block.json`):

```json
{
    "parent": "block/cube_all",
    "textures": {
        "all": "ctech:block/my_block"
    }
}
```

**Item model** (`src/main/resources/assets/ctech/stationapi/models/item/my_block.json`):

```json
{
    "parent": "ctech:block/my_block"
}
```

**Texture**: Place your 16x16 PNG at `src/main/resources/assets/ctech/stationapi/textures/block/my_block.png`

### 5. Add translation

In `src/main/resources/assets/ctech/stationapi/lang/en_US.lang`:

```
tile.@.my_block.name=My Block
```

## License

FSL-1.1-MIT
