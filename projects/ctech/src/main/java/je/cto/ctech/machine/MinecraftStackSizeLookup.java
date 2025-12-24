package je.cto.ctech.machine;

import net.minecraft.item.Item;

/**
 * Minecraft implementation of StackSizeLookup.
 * Looks up max stack size from the Item registry.
 */
public final class MinecraftStackSizeLookup implements StackSizeLookup {

    @Override
    public int getMaxStackSize(int itemId) {
        Item item = Item.ITEMS[itemId];
        if (item == null) {
            return 64; // Default for unknown items
        }
        return item.getMaxCount();
    }
}
