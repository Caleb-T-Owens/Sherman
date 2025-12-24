package je.cto.ctech.machine;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * Immutable value object representing a machine recipe.
 * A recipe has a list of required inputs and a list of outputs.
 */
public final class MachineRecipe {

    private final List<MachineItem> inputs;
    private final List<MachineItem> outputs;

    public MachineRecipe(List<MachineItem> inputs, List<MachineItem> outputs) {
        if (inputs == null || inputs.isEmpty()) {
            throw new IllegalArgumentException("Recipe must have at least one input");
        }
        if (outputs == null || outputs.isEmpty()) {
            throw new IllegalArgumentException("Recipe must have at least one output");
        }
        this.inputs = Collections.unmodifiableList(new ArrayList<>(inputs));
        this.outputs = Collections.unmodifiableList(new ArrayList<>(outputs));
    }

    public List<MachineItem> getInputs() {
        return inputs;
    }

    public List<MachineItem> getOutputs() {
        return outputs;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof MachineRecipe)) return false;
        MachineRecipe other = (MachineRecipe) obj;
        return inputs.equals(other.inputs) && outputs.equals(other.outputs);
    }

    @Override
    public int hashCode() {
        return Objects.hash(inputs, outputs);
    }

    @Override
    public String toString() {
        return String.format("MachineRecipe(inputs=%s, outputs=%s)", inputs, outputs);
    }
}
