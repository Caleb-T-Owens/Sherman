package je.cto.ctech.machine;

import java.util.List;

import je.cto.ctech.transport.Inventory;

/**
 * Interface for machine processing logic.
 */
public interface MachineProcessingService {

    /**
     * Attempts to process one recipe from the given list.
     * Finds the first recipe that can be crafted with the input inventory,
     * consumes the ingredients, and produces outputs.
     *
     * @param recipes the list of recipes to try
     * @param input the input inventory (e.g., chest above machine)
     * @param output the output inventory (e.g., chest below machine)
     * @return true if a recipe was successfully processed
     */
    boolean tryProcess(List<MachineRecipe> recipes, Inventory input, Inventory output);
}
