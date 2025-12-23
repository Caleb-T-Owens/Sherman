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

### 6. Add to creative menu

In `src/main/java/je/cto/ctech/events/bhcreative/Entrypoint.java`, add to `onTabInit()`:

```java
tab.addItem(new ItemStack(CTech.myBlock));
```

## Building Testable Block Logic

For blocks with complex logic (algorithms, multiple edge cases), use dependency injection to separate pure business logic from Minecraft-specific code. This enables unit testing without the game runtime.

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│              Minecraft Layer                         │
│  BlockEntity, Block, World interactions             │
│  - No-arg constructor (Minecraft requirement)       │
│  - Creates adapters, delegates to services          │
└─────────────────┬───────────────────────────────────┘
                  │ depends on (interfaces)
                  ▼
┌─────────────────────────────────────────────────────┐
│              Abstraction Layer                       │
│  Interfaces (pure Java, no Minecraft imports)       │
│  - Use Optional instead of null                     │
│  - Small, focused interfaces                        │
└─────────────────┬───────────────────────────────────┘
                  │ implemented by
                  ▼
┌─────────────────────────────────────────────────────┐
│  Pure Logic (testable)    │  Adapters (Minecraft)   │
│  - No MC dependencies     │  - Wrap MC types        │
│  - Unit testable          │  - Bridge to interfaces │
└─────────────────────────────────────────────────────┘
```

### Example: Transport Package

The `transport` package demonstrates this pattern:

```
je.cto.ctech/transport/
├── BlockPos.java              # Immutable 3D position
├── ItemData.java              # Item value object
├── Inventory.java             # Abstract inventory interface
├── BlockChecker.java          # World query interface
├── PipeNetworkTraverser.java  # Graph traversal interface
├── ItemTransferService.java   # Transfer logic interface
└── impl/
    ├── BfsPipeNetworkTraverser.java    # Pure BFS algorithm
    ├── DefaultItemTransferService.java  # Pure transfer logic
    ├── ChestInventoryAdapter.java       # Wraps ChestBlockEntity
    └── MinecraftBlockChecker.java       # Wraps World queries
```

### Constructor Injection Pattern

```java
public class MyBlockEntity extends BlockEntity {
    private final MyService service;

    // Minecraft uses this
    public MyBlockEntity() {
        this(new DefaultMyService());
    }

    // Tests use this
    MyBlockEntity(MyService service) {
        this.service = service;
    }
}
```

### When to Use This Pattern

**Use it when:**
- Logic involves algorithms (graph traversal, pathfinding)
- Multiple edge cases need testing
- Logic could be reused across blocks
- You want fast iteration without launching the game

**Skip it when:**
- Simple blocks with no special behavior
- Thin wrappers around Minecraft functionality

## Writing Tests

Tests live in `src/test/java` mirroring the main source structure. Run with:

```bash
./gradlew test
```

### Test Structure

Use JUnit 5 with nested classes to organize related tests:

```java
@DisplayName("MyService")
class MyServiceTest {

    private MyService service;

    @BeforeEach
    void setUp() {
        service = new MyService();
    }

    @Nested
    @DisplayName("basic operations")
    class BasicOperationTests {

        @Test
        @DisplayName("does the expected thing")
        void doesExpectedThing() {
            // Arrange
            var input = ...;

            // Act
            var result = service.doSomething(input);

            // Assert
            assertEquals(expected, result);
        }
    }

    @Nested
    @DisplayName("edge cases")
    class EdgeCaseTests {
        // ...
    }
}
```

### Naming Conventions

- **Test class**: `{ClassUnderTest}Test` in same package as source
- **Nested class**: Group by behavior (`BasicOperationTests`, `EdgeCaseTests`, `ErrorConditions`)
- **Test method**: Describe what it verifies (`transfersToEmptySlot`, `rejectsNullInput`)
- **@DisplayName**: Human-readable description shown in test reports

### Mock Objects

Create mock implementations of interfaces in `testutil` package:

```java
// src/test/java/je/cto/ctech/transport/testutil/MockInventory.java
public class MockInventory implements Inventory {
    private final Map<Integer, ItemData> slots = new HashMap<>();
    private int markDirtyCount = 0;

    // Track method calls for verification
    public int getMarkDirtyCount() {
        return markDirtyCount;
    }

    // Implement interface methods...
}
```

For simple interfaces, use anonymous classes inline:

```java
BlockChecker checker = new BlockChecker() {
    public boolean isPipe(BlockPos pos) { return pipes.contains(pos); }
    public Optional<Inventory> getInventory(BlockPos pos) { return Optional.empty(); }
};
```

### Test Patterns

**Verify state changes:**
```java
@Test
void transfersOneItem() {
    MockInventory input = new MockInventory(1);
    input.setStack(0, new ItemData(42, 0, 10, 64));
    MockInventory output = new MockInventory(1);

    service.transferOne(List.of(input), List.of(output));

    assertEquals(9, input.getStack(0).get().getCount());
    assertEquals(1, output.getStack(0).get().getCount());
}
```

**Verify method calls:**
```java
@Test
void marksInventoriesDirty() {
    MockInventory inventory = new MockInventory(1);
    inventory.setStack(0, someItem);

    service.doSomething(inventory);

    assertTrue(inventory.getMarkDirtyCount() > 0);
}
```

**Test return values:**
```java
@Test
void returnsFalseWhenNothingToTransfer() {
    MockInventory emptyInput = new MockInventory(1);

    boolean result = service.transferOne(List.of(emptyInput), List.of(output));

    assertFalse(result);
}
```

**Test exceptions:**
```java
@Test
void throwsOnNullInput() {
    assertThrows(IllegalArgumentException.class, () -> {
        service.doSomething(null);
    });
}
```

### What to Test

Focus tests on:
- **Happy path**: Normal expected behavior
- **Edge cases**: Empty inputs, single items, boundary values
- **Error conditions**: Null inputs, invalid state
- **Algorithm correctness**: For graph traversal, sorting, etc.

Skip testing:
- Simple getters/setters
- Minecraft adapter classes (those wrap MC code, not business logic)
- Trivial pass-through methods

### Example Test Organization

```
src/test/java/je/cto/ctech/
└── transport/
    ├── BlockPosTest.java           # Value object tests
    ├── ItemDataTest.java           # Value object tests
    ├── impl/
    │   ├── BfsPipeNetworkTraverserTest.java
    │   └── DefaultItemTransferServiceTest.java
    └── testutil/
        └── MockInventory.java      # Shared mock
```

## License

FSL-1.1-MIT
