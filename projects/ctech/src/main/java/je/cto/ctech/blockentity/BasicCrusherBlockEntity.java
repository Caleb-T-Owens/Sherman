package je.cto.ctech.blockentity;

import java.util.List;

import je.cto.ctech.CTech;
import je.cto.ctech.machine.MachineItem;
import je.cto.ctech.machine.MachineRecipe;
import net.minecraft.block.Block;
import net.minecraft.item.Item;

/**
 * Block entity for the Basic Crusher.
 *
 * Recipes:
 * - 1 jolt + 1 iron ore -> 2 crushed iron, 10% gravel, 10% cobblestone
 * - 1 jolt + 1 gold ore -> 2 crushed gold, 10% gravel, 10% cobblestone
 */
public class BasicCrusherBlockEntity extends AbstractMachineBlockEntity {

    private List<MachineRecipe> recipes;

    @Override
    protected List<MachineRecipe> getRecipes() {
        if (recipes == null) {
            recipes = List.of(
                new MachineRecipe(
                    List.of(
                        new MachineItem(CTech.jolt1A.id, 1),
                        new MachineItem(Block.IRON_ORE.id, 1)
                    ),
                    List.of(
                        new MachineItem(CTech.crushedIron.id, 0, 2),
                        new MachineItem(Block.GRAVEL.id, 0, 1, 0.1),
                        new MachineItem(Block.COBBLESTONE.id, 0, 1, 0.1)
                    )
                ),
                new MachineRecipe(
                    List.of(
                        new MachineItem(CTech.jolt1A.id, 1),
                        new MachineItem(Block.GOLD_ORE.id, 1)
                    ),
                    List.of(
                        new MachineItem(CTech.crushedGold.id, 0, 2),
                        new MachineItem(Block.GRAVEL.id, 0, 1, 0.1),
                        new MachineItem(Block.COBBLESTONE.id, 0, 1, 0.1)
                    )
                )
            );
        }
        return recipes;
    }
}
