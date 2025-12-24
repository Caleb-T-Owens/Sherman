package je.cto.ctech.block;

import je.cto.ctech.blockentity.BasicGeneratorBlockEntity;
import net.minecraft.block.Block;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.material.Material;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.modificationstation.stationapi.api.recipe.CraftingRegistry;
import net.modificationstation.stationapi.api.template.block.TemplateBlockWithEntity;
import net.modificationstation.stationapi.api.util.Identifier;

public class BasicGeneratorBlock extends TemplateBlockWithEntity {
    public BasicGeneratorBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    protected BlockEntity createBlockEntity() {
        return new BasicGeneratorBlockEntity();
    }

    @Override
    public boolean isFullCube() {
        return false;
    }

    /**
     * Registers the crafting recipe: coal around a basic machine block.
     * CCC
     * CMC
     * CCC
     */
    public static void registerRecipe(Block result, Block machineBlock) {
        CraftingRegistry.addShapedRecipe(
            new ItemStack(result, 1),
            "CCC", "CMC", "CCC",
            'C', new ItemStack(Item.COAL),
            'M', new ItemStack(machineBlock)
        );
    }
}
