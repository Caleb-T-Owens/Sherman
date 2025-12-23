package je.cto.ctech.block;

import je.cto.ctech.blockentity.BasicExtractorBlockEntity;
import net.minecraft.block.Block;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.material.Material;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.modificationstation.stationapi.api.recipe.CraftingRegistry;
import net.modificationstation.stationapi.api.template.block.TemplateBlockWithEntity;
import net.modificationstation.stationapi.api.util.Identifier;

public class BasicExtractorBlock extends TemplateBlockWithEntity {
    public BasicExtractorBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    protected BlockEntity createBlockEntity() {
        return new BasicExtractorBlockEntity();
    }

    @Override
    public boolean isFullCube() {
        return false;
    }

    /**
     * Registers the crafting recipe: stone and redstone around a basic machine block.
     * SRS
     * RMR
     * SRS
     */
    public static void registerRecipe(Block result, Block machineBlock) {
        CraftingRegistry.addShapedRecipe(
            new ItemStack(result, 1),
            "SRS", "RMR", "SRS",
            'S', new ItemStack(Block.STONE),
            'R', new ItemStack(Item.REDSTONE),
            'M', new ItemStack(machineBlock)
        );
    }
}