package je.cto.ctech.blockentity;

import java.util.List;

import je.cto.ctech.CTech;
import je.cto.ctech.machine.MachineItem;
import je.cto.ctech.machine.MachineRecipe;
import net.minecraft.item.Item;

/**
 * Block entity for the Water Collector.
 *
 * Recipe: 1 jolt + 1 bucket -> 1 water bucket
 */
public class WaterCollectorBlockEntity extends AbstractMachineBlockEntity {

    private List<MachineRecipe> recipes;

    @Override
    protected List<MachineRecipe> getRecipes() {
        if (recipes == null) {
            recipes = List.of(
                new MachineRecipe(
                    List.of(
                        new MachineItem(CTech.jolt1A.id, 1),
                        new MachineItem(Item.BUCKET.id, 1)
                    ),
                    List.of(
                        new MachineItem(Item.WATER_BUCKET.id, 0, 1)
                    )
                )
            );
        }
        return recipes;
    }
}
