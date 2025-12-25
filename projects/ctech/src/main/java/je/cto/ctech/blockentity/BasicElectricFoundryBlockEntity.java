package je.cto.ctech.blockentity;

import java.util.List;

import je.cto.ctech.CTech;
import je.cto.ctech.machine.MachineItem;
import je.cto.ctech.machine.MachineRecipe;
import net.minecraft.item.Item;

/**
 * Block entity for the Basic Electric Foundry.
 *
 * Recipes:
 * - 1 jolt + 1 crushed iron + 1 water bucket -> 1 iron ingot + 1 bucket
 * - 1 jolt + 1 crushed gold + 1 water bucket -> 1 gold ingot + 1 bucket
 */
public class BasicElectricFoundryBlockEntity extends AbstractMachineBlockEntity {

    private List<MachineRecipe> recipes;

    @Override
    protected List<MachineRecipe> getRecipes() {
        if (recipes == null) {
            recipes = List.of(
                new MachineRecipe(
                    List.of(
                        new MachineItem(CTech.jolt1A.id, 1),
                        new MachineItem(CTech.crushedIron.id, 1),
                        new MachineItem(Item.WATER_BUCKET.id, 1)
                    ),
                    List.of(
                        new MachineItem(Item.IRON_INGOT.id, 0, 1),
                        new MachineItem(Item.BUCKET.id, 0, 1)
                    )
                ),
                new MachineRecipe(
                    List.of(
                        new MachineItem(CTech.jolt1A.id, 1),
                        new MachineItem(CTech.crushedGold.id, 1),
                        new MachineItem(Item.WATER_BUCKET.id, 1)
                    ),
                    List.of(
                        new MachineItem(Item.GOLD_INGOT.id, 0, 1),
                        new MachineItem(Item.BUCKET.id, 0, 1)
                    )
                )
            );
        }
        return recipes;
    }
}
