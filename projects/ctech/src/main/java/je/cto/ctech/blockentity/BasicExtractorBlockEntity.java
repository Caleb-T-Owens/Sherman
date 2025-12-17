package je.cto.ctech.blockentity;

import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.entity.ChestBlockEntity;
import net.minecraft.item.ItemStack;

public class BasicExtractorBlockEntity extends BlockEntity {
    private int counter = 0;

    @Override
    public void tick() {
        ++counter;
        if (counter < 10) {
            return;
        }
        counter = 0;

        BlockEntity _from = world.getBlockEntity(x, y + 1, z);
        BlockEntity _to = world.getBlockEntity(x, y - 1, z);
        if (_from == null || _to == null) {
            return;
        }
        if (!(_from instanceof ChestBlockEntity) || !(_to instanceof ChestBlockEntity)) {
            return;
        }

        ChestBlockEntity from = (ChestBlockEntity) _from;
        ChestBlockEntity to = (ChestBlockEntity) _to;

        int toRemove = findPresentStack(from);
        if (toRemove == -1) {
            return;
        }

        int toInsert = findEmptyStack(to);
        if (toInsert == -1) {
            return;
        }

        ItemStack stack = from.getStack(toRemove);
        from.setStack(toRemove, null);
        to.setStack(toInsert, stack);
    }

    public int findEmptyStack(ChestBlockEntity chest) {
        for (int i = 0; i < chest.size(); i++) {
            if (chest.getStack(i) == null) {
                return i;
            }
        }

        return -1;
    }

    public int findPresentStack(ChestBlockEntity chest) {
        for (int i = 0; i < chest.size(); i++) {
            if (chest.getStack(i) != null) {
                return i;
            }
        }

        return -1;
    }
}
