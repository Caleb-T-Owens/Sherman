package je.cto.ctech.block;

import je.cto.ctech.blockentity.BasicElectricFoundryBlockEntity;
import net.minecraft.block.Block;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.material.Material;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.modificationstation.stationapi.api.recipe.CraftingRegistry;
import net.modificationstation.stationapi.api.template.block.TemplateBlockWithEntity;
import net.modificationstation.stationapi.api.util.Identifier;

public class BasicElectricFoundryBlock extends TemplateBlockWithEntity {
    public BasicElectricFoundryBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    protected BlockEntity createBlockEntity() {
        return new BasicElectricFoundryBlockEntity();
    }

    @Override
    public boolean isFullCube() {
        return false;
    }

    /**
     * Registers the crafting recipe: iron ingots around a basic machine block.
     * III
     * IMI
     * III
     */
    public static void registerRecipe(Block result, Block machineBlock) {
        CraftingRegistry.addShapedRecipe(
            new ItemStack(result, 1),
            "III", "IMI", "III",
            'I', new ItemStack(Item.IRON_INGOT),
            'M', new ItemStack(machineBlock)
        );
    }
}
