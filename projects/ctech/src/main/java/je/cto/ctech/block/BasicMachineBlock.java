package je.cto.ctech.block;

import net.minecraft.block.Block;
import net.minecraft.block.material.Material;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.modificationstation.stationapi.api.recipe.CraftingRegistry;
import net.modificationstation.stationapi.api.template.block.TemplateBlock;
import net.modificationstation.stationapi.api.util.Identifier;

public class BasicMachineBlock extends TemplateBlock {
    public BasicMachineBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    public boolean isFullCube() {
        return false;
    }

    /**
     * Registers the crafting recipe: 8 iron in a circle = 1 block.
     * III
     * I I
     * III
     */
    public static void registerRecipe(Block result) {
        CraftingRegistry.addShapedRecipe(
            new ItemStack(result, 1),
            "III", "I I", "III",
            'I', new ItemStack(Item.IRON_INGOT)
        );
    }
}