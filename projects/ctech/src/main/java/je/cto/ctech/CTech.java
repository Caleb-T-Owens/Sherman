package je.cto.ctech;

import java.lang.invoke.MethodHandles;

import org.apache.logging.log4j.Logger;

import je.cto.ctech.block.BasicExtractorBlock;
import je.cto.ctech.block.BasicItemPipeBlock;
import je.cto.ctech.block.BasicMachineBlock;
import je.cto.ctech.block.DebugBlock;
import je.cto.ctech.blockentity.BasicExtractorBlockEntity;
import net.mine_diver.unsafeevents.listener.EventListener;
import net.minecraft.block.Block;
import net.modificationstation.stationapi.api.client.event.texture.TextureRegisterEvent;
import net.modificationstation.stationapi.api.event.recipe.RecipeRegisterEvent;
import net.modificationstation.stationapi.api.client.texture.atlas.Atlases;
import net.modificationstation.stationapi.api.client.texture.atlas.ExpandableAtlas;
import net.modificationstation.stationapi.api.event.block.entity.BlockEntityRegisterEvent;
import net.modificationstation.stationapi.api.event.registry.BlockRegistryEvent;
import net.modificationstation.stationapi.api.mod.entrypoint.Entrypoint;
import net.modificationstation.stationapi.api.mod.entrypoint.EntrypointManager;
import net.modificationstation.stationapi.api.util.Identifier;
import net.modificationstation.stationapi.api.util.Namespace;

public class CTech {
    static {
        EntrypointManager.registerLookup(MethodHandles.lookup());
    }

    @Entrypoint.Namespace
    public static Namespace NAMESPACE;

    @Entrypoint.Logger
    public static Logger LOGGER;

    public static Identifier debugBlockId;
    public static Identifier debugBlockTextureId;
    public static Block debugBlock;
    public static int debugBlockTexture;

    public static Identifier basicMachineBlockId;
    public static Identifier basicMachineBlockTextureId;
    public static Block basicMachineBlock;
    public static int basicMachineBlockTexture;

    public static Identifier basicExtractorBlockId;
    public static Identifier basicExtractorBlockTextureId;
    public static Block basicExtractorBlock;
    public static int basicExtractorBlockTexture;

    public static Identifier basicItemPipeBlockId;
    public static Identifier basicItemPipeBlockTextureId;
    public static Block basicItemPipeBlock;
    public static int basicItemPipeBlockTexture;

    @EventListener
    public void registerBlocks(BlockRegistryEvent _event) {
        debugBlockId = NAMESPACE.id("debug_block");
        debugBlockTextureId = NAMESPACE.id("block/debug_block");
        debugBlock = new DebugBlock(debugBlockId).setTranslationKey(debugBlockId);

        basicMachineBlockId = NAMESPACE.id("basic_machine_block");
        basicMachineBlockTextureId = NAMESPACE.id("block/basic_machine_block");
        basicMachineBlock = new BasicMachineBlock(basicMachineBlockId).setTranslationKey(basicMachineBlockId);

        basicExtractorBlockId = NAMESPACE.id("basic_extractor_block");
        basicExtractorBlockTextureId = NAMESPACE.id("block/basic_extractor_block");
        basicExtractorBlock = new BasicExtractorBlock(basicExtractorBlockId).setTranslationKey(basicExtractorBlockId);

        basicItemPipeBlockId = NAMESPACE.id("basic_item_pipe");
        basicItemPipeBlockTextureId = NAMESPACE.id("block/basic_item_pipe");
        basicItemPipeBlock = new BasicItemPipeBlock(basicItemPipeBlockId).setTranslationKey(basicItemPipeBlockId);
    }

    @EventListener
    public void registerBlockEntities(BlockEntityRegisterEvent event) {
        event.register(BasicExtractorBlockEntity.class, basicExtractorBlockId.toString());
    }

    @EventListener
    public void registerTextures(TextureRegisterEvent event) {
        ExpandableAtlas terrainAtlas = Atlases.getTerrain();

        debugBlockTexture = terrainAtlas.addTexture(CTech.debugBlockTextureId).index;
        CTech.debugBlock.textureId = debugBlockTexture;

        basicMachineBlockTexture = terrainAtlas.addTexture(CTech.basicExtractorBlockTextureId).index;
        CTech.basicMachineBlock.textureId = basicMachineBlockTexture;

        basicExtractorBlockTexture = terrainAtlas.addTexture(CTech.basicExtractorBlockTextureId).index;
        CTech.basicExtractorBlock.textureId = basicExtractorBlockTexture;

        basicItemPipeBlockTexture = terrainAtlas.addTexture(CTech.basicItemPipeBlockTextureId).index;
        CTech.basicItemPipeBlock.textureId = basicItemPipeBlockTexture;
    }

    @EventListener
    public void registerRecipes(RecipeRegisterEvent event) {
        RecipeRegisterEvent.Vanilla type = RecipeRegisterEvent.Vanilla.fromType(event.recipeId);
        if (type == RecipeRegisterEvent.Vanilla.CRAFTING_SHAPED) {
            BasicItemPipeBlock.registerRecipe(basicItemPipeBlock);
            BasicMachineBlock.registerRecipe(basicMachineBlock);
            BasicExtractorBlock.registerRecipe(basicExtractorBlock, basicMachineBlock);
        }
    }
}
