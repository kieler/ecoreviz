package de.cau.cs.kieler.klighd.ecoreviz;

import java.util.LinkedList;
import java.util.List;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.emf.ecore.EModelElement;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecoretools.diagram.navigator.EcoreDomainNavigatorItem;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import de.cau.cs.kieler.klighd.KlighdTreeSelection;
import de.cau.cs.kieler.klighd.ui.DiagramViewManager;
import de.cau.cs.kieler.klighd.util.KlighdSynthesisProperties;

/**
 * A simple handler for opening diagrams.
 */
public class OpenDiagramHandler extends AbstractHandler {

    /**
     * {@inheritDoc}
     */
    public Object execute(final ExecutionEvent event) throws ExecutionException {
        final ISelection selection = HandlerUtil.getCurrentSelection(event);
        
        if (selection instanceof IStructuredSelection) {
            final IStructuredSelection sSelection  = (IStructuredSelection) selection;
            final List<EModelElement> listSelection = new LinkedList<EModelElement>(); 
            if (selection instanceof KlighdTreeSelection) {
                // do not react on selections in KLighD diagrams
                return null;
            }
            
            for (Object o: sSelection.toArray()) {
                if (o instanceof EcoreDomainNavigatorItem && ((EcoreDomainNavigatorItem) o).getEObject() instanceof EModelElement) {
                    listSelection.add((EModelElement) ((EcoreDomainNavigatorItem) o).getEObject());
                } else if (o instanceof EModelElement) {
                    listSelection.add((EModelElement) o);
                }
            }
            
            EModelElementCollection model = EModelElementCollection.of(listSelection.iterator());
            
            DiagramViewManager.createView(
                    "de.cau.cs.kieler.klighd.ecoreviz.EModelElementCollectionDiagram", "EModelElementCollection Diagram", model, KlighdSynthesisProperties.newInstance());
        } else {
            MessageDialog.openInformation(HandlerUtil.getActiveShell(event), "Unsupported element",
                    "KLighD diagram synthesis is unsupported for the current selection "
                            + selection.toString() + ".");
        }
        return null;
    }
}
