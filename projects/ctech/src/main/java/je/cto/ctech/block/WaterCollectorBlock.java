package je.cto.ctech.block;

import je.cto.ctech.blockentity.WaterCollectorBlockEntity;
import net.minecraft.block.Block;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.material.Material;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.modificationstation.stationapi.api.recipe.CraftingRegistry;
import net.modificationstation.stationapi.api.template.block.TemplateBlockWithEntity;
import net.modificationstation.stationapi.api.util.Identifier;

public class WaterCollectorBlock extends TemplateBlockWithEntity {
    public WaterCollectorBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    protected BlockEntity createBlockEntity() {
        return new WaterCollectorBlockEntity();
    }

    @Override
    public boolean isFullCube() {
        return false;
    }

    /**
     * Registers the crafting recipe: buckets around a basic machine block.
     * BBB
     * BMB
     * BBB
     */
    public static void registerRecipe(Block result, Block machineBlock) {
        CraftingRegistry.addShapedRecipe(
            new ItemStack(result, 1),
            "BBB", "BMB", "BBB",
            'B', new ItemStack(Item.BUCKET),
            'M', new ItemStack(machineBlock)
        );
    }
}
