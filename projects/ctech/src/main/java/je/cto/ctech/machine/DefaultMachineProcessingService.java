package je.cto.ctech.machine;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;

import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.ItemData;

/**
 * Default implementation of machine processing logic.
 *
 * Finds the first matching recipe, checks if outputs can fit,
 * then consumes inputs and produces outputs.
 */
public final class DefaultMachineProcessingService implements MachineProcessingService {

    private final StackSizeLookup stackSizeLookup;
    private final Random random;

    public DefaultMachineProcessingService(StackSizeLookup stackSizeLookup) {
        this(stackSizeLookup, new Random());
    }

    /**
     * Constructor for dependency injection (used in tests).
     */
    public DefaultMachineProcessingService(StackSizeLookup stackSizeLookup, Random random) {
        this.stackSizeLookup = stackSizeLookup;
        this.random = random;
    }

    @Override
    public boolean tryProcess(List<MachineRecipe> recipes, Inventory input, Inventory output) {
        if (recipes == null || recipes.isEmpty() || input == null || output == null) {
            return false;
        }

        for (MachineRecipe recipe : recipes) {
            if (tryProcessRecipe(recipe, input, output)) {
                return true;
            }
        }

        return false;
    }

    private boolean tryProcessRecipe(MachineRecipe recipe, Inventory input, Inventory output) {
        // Step 1: Check if all inputs are available
        Map<Integer, InputMatch> matches = findInputMatches(recipe, input);
        if (matches == null) {
            return false;
        }

        // Step 2: Determine which outputs will be produced (roll for probabilistic outputs)
        List<MachineItem> actualOutputs = rollForOutputs(recipe.getOutputs());

        // Must produce at least one guaranteed output to proceed
        boolean hasGuaranteedOutput = recipe.getOutputs().stream().anyMatch(MachineItem::isGuaranteed);
        if (hasGuaranteedOutput && actualOutputs.isEmpty()) {
            return false;
        }

        // Step 3: Check if outputs can fit
        if (!actualOutputs.isEmpty() && !canFitOutputs(actualOutputs, output)) {
            return false;
        }

        // Step 4: Consume inputs
        consumeInputs(matches, input);

        // Step 5: Produce outputs
        if (!actualOutputs.isEmpty()) {
            produceOutputs(actualOutputs, output);
        }

        return true;
    }

    /**
     * Rolls for each output based on its chance.
     * Guaranteed outputs (chance = 1.0) are always included.
     */
    private List<MachineItem> rollForOutputs(List<MachineItem> outputs) {
        List<MachineItem> result = new ArrayList<>();
        for (MachineItem output : outputs) {
            if (output.isGuaranteed() || random.nextDouble() < output.getChance()) {
                result.add(output);
            }
        }
        return result;
    }

    /**
     * Finds slots that satisfy each input requirement.
     * Returns null if any input cannot be satisfied.
     */
    private Map<Integer, InputMatch> findInputMatches(MachineRecipe recipe, Inventory input) {
        // Track how many items we're "reserving" from each slot
        Map<Integer, Integer> reservedCounts = new HashMap<>();
        Map<Integer, InputMatch> matches = new HashMap<>();

        for (int i = 0; i < recipe.getInputs().size(); i++) {
            MachineItem requiredInput = recipe.getInputs().get(i);
            InputMatch match = findMatchForInput(requiredInput, input, reservedCounts);
            if (match == null) {
                return null;
            }
            matches.put(i, match);

            // Reserve the items we found
            for (Map.Entry<Integer, Integer> entry : match.slotCounts.entrySet()) {
                reservedCounts.merge(entry.getKey(), entry.getValue(), Integer::sum);
            }
        }

        return matches;
    }

    /**
     * Finds slots that can satisfy a single input, respecting already reserved items.
     */
    private InputMatch findMatchForInput(
            MachineItem requiredInput,
            Inventory input,
            Map<Integer, Integer> reservedCounts) {

        Map<Integer, Integer> slotCounts = new HashMap<>();
        int remaining = requiredInput.getCount();

        for (int slot = 0; slot < input.size() && remaining > 0; slot++) {
            Optional<ItemData> optStack = input.getStack(slot);
            if (optStack.isEmpty()) {
                continue;
            }

            ItemData stack = optStack.get();
            if (!requiredInput.matches(stack.getItemId(), stack.getDamage())) {
                continue;
            }

            int available = stack.getCount() - reservedCounts.getOrDefault(slot, 0);
            if (available <= 0) {
                continue;
            }

            int toTake = Math.min(available, remaining);
            slotCounts.put(slot, toTake);
            remaining -= toTake;
        }

        if (remaining > 0) {
            return null;
        }

        return new InputMatch(slotCounts);
    }

    /**
     * Checks if all outputs can fit in the output inventory.
     */
    private boolean canFitOutputs(List<MachineItem> outputs, Inventory inventory) {
        // Track simulated additions to slots
        Map<Integer, SimulatedSlot> simulated = new HashMap<>();

        // Initialize with current inventory state
        for (int slot = 0; slot < inventory.size(); slot++) {
            Optional<ItemData> optStack = inventory.getStack(slot);
            if (optStack.isPresent()) {
                ItemData stack = optStack.get();
                simulated.put(slot, new SimulatedSlot(
                    stack.getItemId(), stack.getDamage(), stack.getCount(), stack.getMaxCount()));
            }
        }

        for (MachineItem output : outputs) {
            int remaining = output.getCount();
            int maxStackSize = stackSizeLookup.getMaxStackSize(output.getItemId());

            // First try to merge with existing stacks
            for (int slot = 0; slot < inventory.size() && remaining > 0; slot++) {
                SimulatedSlot sim = simulated.get(slot);
                if (sim != null && sim.itemId == output.getItemId() && sim.damage == output.getDamage()) {
                    int space = sim.maxCount - sim.count;
                    int toAdd = Math.min(space, remaining);
                    sim.count += toAdd;
                    remaining -= toAdd;
                }
            }

            // Then try empty slots
            for (int slot = 0; slot < inventory.size() && remaining > 0; slot++) {
                if (!simulated.containsKey(slot)) {
                    int toAdd = Math.min(maxStackSize, remaining);
                    simulated.put(slot, new SimulatedSlot(
                        output.getItemId(), output.getDamage(), toAdd, maxStackSize));
                    remaining -= toAdd;
                }
            }

            if (remaining > 0) {
                return false;
            }
        }

        return true;
    }

    /**
     * Consumes inputs from the input inventory.
     */
    private void consumeInputs(Map<Integer, InputMatch> matches, Inventory input) {
        for (InputMatch match : matches.values()) {
            for (Map.Entry<Integer, Integer> entry : match.slotCounts.entrySet()) {
                int slot = entry.getKey();
                int toConsume = entry.getValue();

                Optional<ItemData> optStack = input.getStack(slot);
                if (optStack.isEmpty()) {
                    continue;
                }

                ItemData stack = optStack.get();
                ItemData newStack = stack;
                for (int i = 0; i < toConsume; i++) {
                    newStack = newStack.withDecrementedCount();
                }

                if (newStack.isEmpty()) {
                    input.clearSlot(slot);
                } else {
                    input.setStack(slot, newStack);
                }
            }
        }
        input.markDirty();
    }

    /**
     * Produces outputs into the output inventory.
     */
    private void produceOutputs(List<MachineItem> outputs, Inventory inventory) {
        for (MachineItem output : outputs) {
            int remaining = output.getCount();
            int maxStackSize = stackSizeLookup.getMaxStackSize(output.getItemId());

            // First try to merge with existing stacks
            for (int slot = 0; slot < inventory.size() && remaining > 0; slot++) {
                Optional<ItemData> optStack = inventory.getStack(slot);
                if (optStack.isEmpty()) {
                    continue;
                }

                ItemData stack = optStack.get();
                if (stack.getItemId() == output.getItemId() && stack.getDamage() == output.getDamage()) {
                    ItemData newStack = stack;
                    while (remaining > 0 && !newStack.isFull()) {
                        newStack = newStack.withIncrementedCount();
                        remaining--;
                    }
                    inventory.setStack(slot, newStack);
                }
            }

            // Then use empty slots
            for (int slot = 0; slot < inventory.size() && remaining > 0; slot++) {
                Optional<ItemData> optStack = inventory.getStack(slot);
                if (optStack.isPresent()) {
                    continue;
                }

                int toAdd = Math.min(maxStackSize, remaining);
                ItemData newStack = new ItemData(
                    output.getItemId(), output.getDamage(), toAdd, maxStackSize);
                inventory.setStack(slot, newStack);
                remaining -= toAdd;
            }
        }
        inventory.markDirty();
    }

    /**
     * Tracks which slots satisfy an input and how many items from each.
     */
    private static final class InputMatch {
        final Map<Integer, Integer> slotCounts;

        InputMatch(Map<Integer, Integer> slotCounts) {
            this.slotCounts = slotCounts;
        }
    }

    /**
     * Used for simulating output placement.
     */
    private static final class SimulatedSlot {
        final int itemId;
        final int damage;
        int count;
        final int maxCount;

        SimulatedSlot(int itemId, int damage, int count, int maxCount) {
            this.itemId = itemId;
            this.damage = damage;
            this.count = count;
            this.maxCount = maxCount;
        }
    }
}
