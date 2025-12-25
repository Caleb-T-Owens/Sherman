package je.cto.ctech.machine;

import java.util.Objects;

/**
 * Immutable value object representing an item in a machine recipe.
 * Used for both inputs (ingredients) and outputs.
 *
 * For inputs, can optionally match any damage value.
 * For outputs, damage specifies the exact damage value to produce.
 * Outputs can have a chance (0.0-1.0) to be produced.
 */
public final class MachineItem {

    private final int itemId;
    private final int damage;
    private final boolean matchAnyDamage;
    private final int count;
    private final double chance;

    /**
     * Creates an item that matches any damage value (for inputs)
     * or produces with damage 0 (for outputs).
     */
    public MachineItem(int itemId, int count) {
        this(itemId, 0, true, count, 1.0);
    }

    /**
     * Creates an item with a specific damage value.
     * For inputs, only matches items with this exact damage.
     * For outputs, produces items with this damage value.
     */
    public MachineItem(int itemId, int damage, int count) {
        this(itemId, damage, false, count, 1.0);
    }

    /**
     * Creates an output item with a specific chance to be produced.
     * @param chance probability from 0.0 to 1.0 (e.g., 0.1 = 10% chance)
     */
    public MachineItem(int itemId, int damage, int count, double chance) {
        this(itemId, damage, false, count, chance);
    }

    private MachineItem(int itemId, int damage, boolean matchAnyDamage, int count, double chance) {
        if (count <= 0) {
            throw new IllegalArgumentException("Count must be positive: " + count);
        }
        if (chance <= 0.0 || chance > 1.0) {
            throw new IllegalArgumentException("Chance must be between 0.0 (exclusive) and 1.0 (inclusive): " + chance);
        }
        this.itemId = itemId;
        this.damage = damage;
        this.matchAnyDamage = matchAnyDamage;
        this.count = count;
        this.chance = chance;
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
     * Returns the chance this item will be produced (for outputs).
     * Always 1.0 for inputs.
     */
    public double getChance() {
        return chance;
    }

    /**
     * Returns true if this output should always be produced.
     */
    public boolean isGuaranteed() {
        return chance >= 1.0;
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
            && count == other.count
            && Double.compare(chance, other.chance) == 0;
    }

    @Override
    public int hashCode() {
        return Objects.hash(itemId, damage, matchAnyDamage, count, chance);
    }

    @Override
    public String toString() {
        if (matchAnyDamage) {
            if (chance < 1.0) {
                return String.format("MachineItem(id=%d, count=%d, chance=%.0f%%)", itemId, count, chance * 100);
            }
            return String.format("MachineItem(id=%d, count=%d)", itemId, count);
        }
        if (chance < 1.0) {
            return String.format("MachineItem(id=%d, damage=%d, count=%d, chance=%.0f%%)", itemId, damage, count, chance * 100);
        }
        return String.format("MachineItem(id=%d, damage=%d, count=%d)", itemId, damage, count);
    }
}
