/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2014 by
 * + Christian-Albrechts-University of Kiel
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.ecoreviz;

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
 * Handler for opening ecore diagrams.
 * 
 * @author ckru
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
                    "de.cau.cs.kieler.ecoreviz.EModelElementCollectionDiagram", "Ecore Diagram", model, KlighdSynthesisProperties.newInstance());
        } else {
            MessageDialog.openInformation(HandlerUtil.getActiveShell(event), "Unsupported element",
                    "KLighD diagram synthesis is unsupported for the current selection "
                            + selection.toString() + ".");
        }
        return null;
    }
}
