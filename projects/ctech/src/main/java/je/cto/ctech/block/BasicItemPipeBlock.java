package je.cto.ctech.block;

import net.minecraft.block.Block;
import net.minecraft.block.material.Material;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.modificationstation.stationapi.api.recipe.CraftingRegistry;
import net.modificationstation.stationapi.api.template.block.TemplateBlock;
import net.modificationstation.stationapi.api.util.Identifier;

public class BasicItemPipeBlock extends TemplateBlock {
    public BasicItemPipeBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    public boolean isFullCube() {
        return false;
    }

    /**
     * Registers the crafting recipe: wool around 3 iron in a row = 16 pipes.
     * WWW
     * III
     * WWW
     */
    public static void registerRecipe(Block result) {
        CraftingRegistry.addShapedRecipe(
            new ItemStack(result, 16),
            "WWW", "III", "WWW",
            'W', new ItemStack(Block.WOOL),
            'I', new ItemStack(Item.IRON_INGOT)
        );
    }
}
