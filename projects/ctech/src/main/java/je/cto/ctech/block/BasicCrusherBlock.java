package je.cto.ctech.block;

import je.cto.ctech.blockentity.BasicCrusherBlockEntity;
import net.minecraft.block.Block;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.material.Material;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.modificationstation.stationapi.api.recipe.CraftingRegistry;
import net.modificationstation.stationapi.api.template.block.TemplateBlockWithEntity;
import net.modificationstation.stationapi.api.util.Identifier;

public class BasicCrusherBlock extends TemplateBlockWithEntity {
    public BasicCrusherBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    protected BlockEntity createBlockEntity() {
        return new BasicCrusherBlockEntity();
    }

    @Override
    public boolean isFullCube() {
        return false;
    }

    /**
     * Registers the crafting recipe: flint around a basic machine block.
     * FFF
     * FMF
     * FFF
     */
    public static void registerRecipe(Block result, Block machineBlock) {
        CraftingRegistry.addShapedRecipe(
            new ItemStack(result, 1),
            "FFF", "FMF", "FFF",
            'F', new ItemStack(Item.FLINT),
            'M', new ItemStack(machineBlock)
        );
    }
}
