package je.cto.ctech.events.bhcreative;

import je.cto.ctech.CTech;
import net.mine_diver.unsafeevents.listener.EventListener;
import net.minecraft.item.ItemStack;
import paulevs.bhcreative.api.CreativeTab;
import paulevs.bhcreative.api.SimpleTab;
import paulevs.bhcreative.registry.TabRegistryEvent;

public class Entrypoint {
    public static CreativeTab tab;

    @EventListener
    public void onTabInit(TabRegistryEvent event) {
        tab = new SimpleTab(CTech.NAMESPACE.id("creative_tab"), new ItemStack(CTech.debugBlock)); // Making tab
        event.register(tab); // Registering tab
        tab.addItem(new ItemStack(CTech.debugBlock));
        tab.addItem(new ItemStack(CTech.basicMachineBlock));
        tab.addItem(new ItemStack(CTech.basicExtractorBlock));
        tab.addItem(new ItemStack(CTech.basicItemPipeBlock));
        tab.addItem(new ItemStack(CTech.basicGeneratorBlock));
        tab.addItem(new ItemStack(CTech.jolt1A));
        tab.addItem(new ItemStack(CTech.jolt2A));
        tab.addItem(new ItemStack(CTech.jolt4A));
        tab.addItem(new ItemStack(CTech.jolt8A));
    }
}
