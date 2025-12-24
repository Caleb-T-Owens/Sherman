package je.cto.ctech.machine;

import java.util.Objects;

/**
 * Immutable value object representing an item in a machine recipe.
 * Used for both inputs (ingredients) and outputs.
 *
 * For inputs, can optionally match any damage value.
 * For outputs, damage specifies the exact damage value to produce.
 */
public final class MachineItem {

    private final int itemId;
    private final int damage;
    private final boolean matchAnyDamage;
    private final int count;

    /**
     * Creates an item that matches any damage value (for inputs)
     * or produces with damage 0 (for outputs).
     */
    public MachineItem(int itemId, int count) {
        this(itemId, 0, true, count);
    }

    /**
     * Creates an item with a specific damage value.
     * For inputs, only matches items with this exact damage.
     * For outputs, produces items with this damage value.
     */
    public MachineItem(int itemId, int damage, int count) {
        this(itemId, damage, false, count);
    }

    private MachineItem(int itemId, int damage, boolean matchAnyDamage, int count) {
        if (count <= 0) {
            throw new IllegalArgumentException("Count must be positive: " + count);
        }
        this.itemId = itemId;
        this.damage = damage;
        this.matchAnyDamage = matchAnyDamage;
        this.count = count;
    }

    public int getItemId() {
        return itemId;
    }

    public int getDamage() {
        return damage;
    }

    public int getCount() {
        return count;
    }

    /**
     * Returns true if this item matches any damage value.
     */
    public boolean matchesAnyDamage() {
        return matchAnyDamage;
    }

    /**
     * Checks if the given item matches this item (for ingredient matching).
     * Ignores count - only checks item ID and optionally damage.
     */
    public boolean matches(int itemId, int damage) {
        if (this.itemId != itemId) {
            return false;
        }
        if (!matchAnyDamage && this.damage != damage) {
            return false;
        }
        return true;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof MachineItem)) return false;
        MachineItem other = (MachineItem) obj;
        return itemId == other.itemId
            && damage == other.damage
            && matchAnyDamage == other.matchAnyDamage
            && count == other.count;
    }

    @Override
    public int hashCode() {
        return Objects.hash(itemId, damage, matchAnyDamage, count);
    }

    @Override
    public String toString() {
        if (matchAnyDamage) {
            return String.format("MachineItem(id=%d, count=%d)", itemId, count);
        }
        return String.format("MachineItem(id=%d, damage=%d, count=%d)", itemId, damage, count);
    }
}
