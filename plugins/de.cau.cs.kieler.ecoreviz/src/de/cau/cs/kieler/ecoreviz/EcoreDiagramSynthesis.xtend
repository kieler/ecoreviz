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
package de.cau.cs.kieler.ecoreviz

import com.google.common.collect.ImmutableList
import de.cau.cs.kieler.klighd.SynthesisOption
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.krendering.KContainerRendering
import de.cau.cs.kieler.klighd.krendering.extensions.KColorExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KContainerRenderingExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KPolylineExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis
import javax.inject.Inject
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.elk.core.options.Direction
import org.eclipse.elk.core.options.EdgeType
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcorePackage

import static extension com.google.common.base.Strings.*
import de.cau.cs.kieler.klighd.krendering.extensions.KLabelExtensions
import de.cau.cs.kieler.klighd.microlayout.PlacementUtil
import de.cau.cs.kieler.klighd.krendering.KTextUtil
import de.cau.cs.kieler.klighd.krendering.KRenderingFactory

/**
 * This Synthesis visualizes the class diagramm contained in a given EPackage.
 * It is meant to be used alongside an ECore model editor.
 * 
 * @author chsch/wechselberg
 */
class EcoreDiagramSynthesis extends AbstractDiagramSynthesis<EPackage> {
    
    @Inject
    extension KNodeExtensions
    
    @Inject
    extension KEdgeExtensions
    
    @Inject
    extension KRenderingExtensions
    
    @Inject
    extension KContainerRenderingExtensions
    
    @Inject
    extension KPolylineExtensions
    
    @Inject
    extension KColorExtensions
    
    @Inject
    extension KLabelExtensions
        
    static val SynthesisOption ATTRIBUTES = SynthesisOption::createCheckOption("Attributes/Literals", false);
    
    /**
     * {@inheritDoc}<br>
     * <br>
     * Registers the diagram filter option declared above, which allow users to tailor the constructed diagrams.
     */
    override getDisplayedSynthesisOptions() {
        return ImmutableList::of(ATTRIBUTES);
    }
    
    /**
     * {@inheritDoc}<br>
     * <br>
     * This main method creates the root node that represents the canvas of the diagram.
     * It configures some layout options adds the diagram elements by distinguishing the three option cases.
     * 
     * Note that this translation added also the Classes contained in selected EPackages,
     * see the end of this method.
     */
    override KNode transform(EPackage selectedPackage) {
        return createNode() => [
            it.addLayoutParam(CoreOptions::ALGORITHM, "de.cau.cs.kieler.kiml.ogdf.planarization");
            it.addLayoutParam(CoreOptions::SPACING_NODE_NODE, 75.0);
            it.addLayoutParam(CoreOptions::DIRECTION, Direction::UP);
               
            selectedPackage.EClassifiers => [ clazz |
                clazz.createElementFigures(it);
            ];
        ];
    }
    
    def createElementFigures(Iterable<EClassifier> classes, KNode rootNode) {
        classes.createClassifierFigures(rootNode);
        classes.createAssociationConnections();
        classes.createInheritanceConnections();
    }
    
    def createClassifierFigures(Iterable<EClassifier> classes, KNode rootNode) {
        classes.filterNull.forEach[ EClassifier clazz |
            rootNode.children += clazz.createNode().associateWith(clazz) => [
                it.addRectangle => [
                    it.lineWidth = 2;
                    it.setBackgroundGradient("white".color, "LemonChiffon".color, 0)
                    it.shadow = "black".color;
                    it.setGridPlacement(1).from(LEFT, 2, 0, TOP, 2, 0).to(RIGHT, 2, 0, BOTTOM, 2, 0);
                    it.addRectangle => [
                        // this rectangle represents the grid cell ... 
                        it.invisible = true;
                        it.addRectangle => [
                            // ... and this one a "free floating" centrally aligned rendering container
                            //  hosting the actual title image and/or text(s)  
                            it.invisible = true;
                            it.setPointPlacementData(LEFT, 0, 0.5f, TOP, 0, 0.5f, H_CENTRAL, V_CENTRAL, 0, 0, 0, 0);
                            
                            if (EcorePackage::eINSTANCE.getEEnum.isInstance(clazz)) {
                                it.addText("<<Enum>>") => [
                                    it.fontSize = 13;
                                    it.fontItalic = true;
                                    it.verticalAlignment = V_CENTRAL;
                                    it.setAreaPlacementData.from(LEFT, 20, 0, TOP, 10, 0).to(RIGHT, 20, 0, BOTTOM, 1, 0.5f);
                                ];
                                it.addText(clazz.name.nullToEmpty).associateWith(clazz) => [
                                    it.fontSize = 15;
                                    it.fontBold = true;
                                    it.cursorSelectable = false;
                                    it.setAreaPlacementData.from(LEFT, 20, 0, TOP, 1, 0.5f).to(RIGHT, 20, 0, BOTTOM, 10, 0);
                                ];
                            } else {
                                it.addImage("de.cau.cs.kieler.ecoreviz", "icons/Class.png")
                                    .setPointPlacementData(LEFT, 20, 0, TOP, 0, 0.5f, H_CENTRAL, V_CENTRAL, 10, 10, 20, 20)
                                    .addEllipticalClip; //.setAreaPlacementData.from(LEFT, 3, 0, TOP, 3, 0).to(RIGHT, 3, 0, BOTTOM, 3, 0);
                                it.addText(clazz.name.nullToEmpty).associateWith(clazz) => [
                                    it.fontSize = 15;
                                    it.fontBold = true;
                                    it.cursorSelectable = false;
                                    it.setPointPlacementData(LEFT, 40, 0, TOP, 0, 0.5f, H_LEFT, V_CENTRAL, 10, 10, 0, 0);
                                ];
                            };
                        ];
                    ];
                    if (!ATTRIBUTES.booleanValue) {
                        return;
                    }
                    if (EcorePackage::eINSTANCE.getEClass.isInstance(clazz) && !(clazz as EClass).EAttributes.empty) {
                        it.addHorizontalLine(1, 1.5f);
                        it.addRectangle => [
                            it.invisible = true;
                            it.foreground = "red".color;
                            it.setSurroundingSpaceGrid(7, 0)
                            it.setGridPlacement(1).from(LEFT, 0, 0, TOP, -2, 0);
                            
                            (clazz as EClass).EAttributes.forEach[ attr |
                                it.addRectangle => [
                                    it.invisible = true;
                                    // it.addImage("org.eclipse.emf.ecoretools.diagram", "icons/EAttribute.gif")
                                    // .setGridPlacementData(16, 16);
                                    it.addAttributeIcon()
                                        .setPointPlacementData(LEFT, 10, 0, TOP, 1.5f, 0.5f, H_CENTRAL, V_CENTRAL, 0, 0, 15f, 7.5f);
                                    it.addText(attr.name + " : " + attr.EAttributeType.name) => [
                                        it.fontSize = 13;
                                        it.horizontalAlignment = H_LEFT
                                        it.verticalAlignment = V_CENTRAL
                                        it.cursorSelectable = false;
                                        it.setPointPlacementData(LEFT, 25, 0, TOP, 0, 0.5f, H_LEFT, V_CENTRAL, 20, 5, 0, 0);
                                    ];
                                ];
                            ];
                        ];
                    }
                    if (EcorePackage::eINSTANCE.getEEnum.isInstance(clazz)) {
                        it.addHorizontalLine(1, 1.5f);
                        it.addRectangle => [ rect |
                            rect.invisible = true;
                            rect.foreground = "red".color;
                            rect.setSurroundingSpaceGrid(5, 0)
                            rect.setGridPlacement(1).to(RIGHT, 0, 0, BOTTOM, 0, 0);
                            (clazz as EEnum).ELiterals.forEach[
                                rect.addText(it.name + " (" + it.literal + ")") => [
                                    it.horizontalAlignment = H_CENTRAL
                                    it.verticalAlignment = V_CENTRAL
                                    it.cursorSelectable = false;
                                    it.setSurroundingSpaceGrid(3, 0);
                                ];
                            ];
                        ];
                    }
                ];
            ];
        ];
    }
    
    def createAssociationConnections(Iterable<EClassifier> classes) {
        val list = classes.toList;
        list.filter(typeof(EClass)).forEach[
            it.EStructuralFeatures.filter(typeof(EReference))
                .filter[list.contains(it.EType)]
                .forEach[it.createAssociationConnection];
        ];
    }
    
    def createAssociationConnection(EReference ref) {
        ref.createEdge() => [
            it.source = ref.eContainer.node;
            it.target = ref.EType.node;
            if (!ATTRIBUTES.booleanValue) {
                it.addTailEdgeLabel(ref.name + "\n" + ref.lowerBound + if (ref.lowerBound != ref.upperBound) {".." + if (ref.upperBound == -1) "*" else ref.upperBound} else "");
            }
            it.addPolyline() => [
                it.lineWidth = 2;
                it.foreground = "gray25".color
                it.addHeadArrowDecorator();
                if (ref.containment) {
                    it.addPolygon() => [
                        it.points += createKPosition(LEFT, 0, 0, TOP, 0, 0.5f);
                        it.points += createKPosition(LEFT, 0, 0.5f, TOP, 0, 0);
                        it.points += createKPosition(RIGHT, 0, 0, TOP, 0, 0.5f);
                        it.points += createKPosition(LEFT, 0, 0.5f, BOTTOM, 0, 0);
                        it.setDecoratorPlacementData(24, 12, 12, 0, true);
                        it.foreground = "gray25".color
                        it.background = "gray25".color;
                    ];
                }
            ];
        ];
    }
    
    def createInheritanceConnections(Iterable<EClassifier> classes) {
        val list = classes.toList;
        list.filter(typeof(EClass)).forEach[
            child | child.ESuperTypes.filter[ list.contains(it) ]
                .forEach[ parent | child.createInheritanceConnection(parent) ];
        ];
    }
    
    def createInheritanceConnection(EClass child, EClass parent) {
        new Pair(child, parent).createEdge() => [
            it.addLayoutParam(CoreOptions::EDGE_TYPE, EdgeType::GENERALIZATION);
            it.source = child.node;
            it.target = parent.node;
            it.data addPolyline() => [
                it.lineWidth = 2;
                it.foreground = "gray25".color
                it.addInheritanceTriangleArrowDecorator();
            ];          
        ];
    }
    
    def addAttributeIcon(KContainerRendering parent) {
        return parent.addRectangle() => [
            it.lineWidth = 1.75f;
            it.setForegroundGradient("goldenrod4".color, 255, "darkGray".color, 255, 90);
            it.background = "LemonChiffon".color;
        ];
    }
}
