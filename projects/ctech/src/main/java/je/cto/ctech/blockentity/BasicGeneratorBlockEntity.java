package je.cto.ctech.blockentity;

import java.util.List;

import je.cto.ctech.machine.MachineItem;
import je.cto.ctech.machine.MachineRecipe;
import net.minecraft.item.Item;

/**
 * Block entity for the Basic Generator.
 *
 * Recipe: 1 coal -> 1 iron ingot
 */
public class BasicGeneratorBlockEntity extends AbstractMachineBlockEntity {

    private static final List<MachineRecipe> RECIPES = List.of(
        new MachineRecipe(
            List.of(new MachineItem(Item.COAL.id, 1)),
            List.of(new MachineItem(Item.IRON_INGOT.id, 1))
        )
    );

    @Override
    protected List<MachineRecipe> getRecipes() {
        return RECIPES;
    }
}
