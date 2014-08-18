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
import org.eclipse.core.internal.resources.File;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EModelElement;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecoretools.diagram.navigator.EcoreDomainNavigatorItem;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.ui.statushandlers.StatusManager;

import de.cau.cs.kieler.klighd.KlighdTreeSelection;
import de.cau.cs.kieler.klighd.ui.DiagramViewManager;
import de.cau.cs.kieler.klighd.util.KlighdSynthesisProperties;

/**
 * Handler for opening ecore diagrams.
 * 
 * @author ckru
 */
@SuppressWarnings("restriction")
public class OpenDiagramHandler extends AbstractHandler {

    public static final String PLUGIN_ID = "de.cau.cs.kieler.ecoreviz";

    /**
     * {@inheritDoc}
     */
    public Object execute(final ExecutionEvent event) throws ExecutionException {
        final ISelection selection = HandlerUtil.getCurrentSelection(event);

        if (selection instanceof IStructuredSelection) {
            final IStructuredSelection sSelection = (IStructuredSelection) selection;
            final List<EModelElement> listSelection = new LinkedList<EModelElement>();
            if (selection instanceof KlighdTreeSelection) {
                // do not react on selections in KLighD diagrams
                return null;
            }

            for (Object o : sSelection.toArray()) {
                if (o instanceof EcoreDomainNavigatorItem
                        && ((EcoreDomainNavigatorItem) o).getEObject() instanceof EModelElement) {
                    listSelection.add((EModelElement) ((EcoreDomainNavigatorItem) o).getEObject());
                } else if (o instanceof EModelElement) {
                    listSelection.add((EModelElement) o);
                } else if (o instanceof File) {
                    try {
                        File f = (File) o;
                        ResourceSet rs = new ResourceSetImpl();
                        Resource r =
                                rs.getResource(URI.createFileURI(f.getFullPath().toString()), true);
                        if (r.getContents().size() > 0) {
                            if (r.getContents().get(0) instanceof EPackage) {
                                listSelection.add((EModelElement) r.getContents().get(0));
                            }
                        }
                    } catch (Exception e) {
                        StatusManager.getManager().handle(
                                new Status(IStatus.ERROR, PLUGIN_ID,
                                        "Could not load selected file.", e), StatusManager.SHOW);
                    }
                } else {
                    handleUnknownSelection(selection);

                    return null;
                }
            }

            EModelElementCollection model = EModelElementCollection.of(listSelection.iterator());

            DiagramViewManager.createView(
                    "de.cau.cs.kieler.ecoreviz.EModelElementCollectionDiagram", "Ecore Diagram",
                    model, KlighdSynthesisProperties.create());
            
            return null;
        }

        handleUnknownSelection(selection);

        return null;
    }

    private void handleUnknownSelection(final ISelection selection) {
        StatusManager.getManager().handle(
                new Status(IStatus.ERROR, PLUGIN_ID,
                        "KLighD diagram synthesis is unsupported for the current selection "
                                + selection.toString() + "."), StatusManager.SHOW);
    }
}
