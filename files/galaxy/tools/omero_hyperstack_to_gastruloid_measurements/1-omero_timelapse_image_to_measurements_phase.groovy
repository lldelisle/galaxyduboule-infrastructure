// This macro was written by the BIOP (https://github.com/BIOP)
// Romain Guiet and Rémy Dornier
// Lucille Delisle modified to support headless
// merge the analysis script with templates available at
// https://github.com/BIOP/OMERO-scripts/tree/main/Fiji

// Last modification: 2023-03-24

/*
 * = COPYRIGHT =
 * © All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, BioImaging And Optics Platform (BIOP), 2023
 *
 * Licensed under the BSD-3-Clause License:
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided
 * that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// This macro will use ilastik to detect ROIs
// measure and compute elongation index

// The input image(s) may have multiple time stacks
// It may have multiple channels
// If multiple channels are present, the LUT will be
// used to determine which channel should be used.

// This macro works both in headless
// or GUI

// In both modes,
// The result table and the result ROI are sent to omero
// The measures are: Area,Perim.,Circ.,Feret,FeretX,FeretY,FeretAngle,MinFeret,AR,Round,Solidity,Unit,Date,Version,IlastikProject,ProbabilityThreshold,MinSizeParticle,MinDiameter,ClosenessTolerance,MinSimilarity,RadiusMedian,BaseImage,ROI,Time,ROI_type,LargestRadius,SpineLength,ElongationIndex

// LargestRadius and SpineLength are set to 0 if no circle was found.
// ElongationIndex is set to 0 if a gastruloid was found and to -1 if no gastruloid was found.

// SpineLength is set to 0 and ElongationIndex is set to 1 if a single circle was found.

import ch.epfl.biop.MaxInscribedCircles

import fr.igred.omero.annotations.TableWrapper
import fr.igred.omero.Client
import fr.igred.omero.repository.DatasetWrapper
import fr.igred.omero.repository.ImageWrapper
import fr.igred.omero.repository.PlateWrapper
import fr.igred.omero.repository.PixelsWrapper
import fr.igred.omero.repository.WellWrapper
import fr.igred.omero.roi.ROIWrapper

import ij.ImagePlus
import ij.gui.Overlay
import ij.gui.PolygonRoi
import ij.gui.Roi
import ij.IJ
import ij.io.FileSaver
import ij.plugin.Concatenator
import ij.plugin.Duplicator
import ij.plugin.frame.RoiManager
import ij.plugin.HyperStackConverter
import ij.plugin.ImageCalculator
import ij.Prefs
import ij.process.FloatPolygon
import ij.process.ImageProcessor

import java.awt.Color
import java.awt.GraphicsEnvironment
import java.io.File

import loci.plugins.in.ImporterOptions

import net.imglib2.img.display.imagej.ImageJFunctions

import omero.model.LengthI

import org.apache.commons.io.FilenameUtils
import org.apache.commons.io.FileUtils
import org.ilastik.ilastik4ij.ui.*

def processDataset(Client user_client, DatasetWrapper dataset_wpr,
                   File ilastik_project, String ilastik_project_type,
                   Integer ilastik_label_OI,
                   Double probability_threshold, Double radius_median,
                   Integer min_size_particle, Boolean get_spine,
                   Integer minimum_diameter, Integer closeness_tolerance, Double min_similarity,
                   String ilastik_project_short_name,
                   File output_directory,
                   Boolean headless_mode, Boolean debug, String tool_version) {
    dataset_wpr.getImages(user_client).each{ ImageWrapper img_wpr ->
        processImage(user_client, img_wpr,
                     ilastik_project, ilastik_project_type,
                     ilastik_label_OI, probability_threshold,
                     radius_median, min_size_particle, get_spine,
                     minimum_diameter, closeness_tolerance, min_similarity,
                     ilastik_project_short_name,
                     output_directory,
                     headless_mode, debug, tool_version)
    }
}

def processSinglePlate(Client user_client, PlateWrapper plate_wpr,
                       File ilastik_project, String ilastik_project_type,
                       Integer ilastik_label_OI,
                       Double probability_threshold, Double radius_median,
                       Integer min_size_particle, Boolean get_spine,
                       Integer minimum_diameter, Integer closeness_tolerance, Double min_similarity,
                       String ilastik_project_short_name,
                       File output_directory,
                       Boolean headless_mode, Boolean debug, String tool_version) {
    plate_wpr.getWells(user_client).each{ well_wpr ->
        processSingleWell(user_client, well_wpr,
                     ilastik_project, ilastik_project_type,
                     ilastik_label_OI, probability_threshold,
                     radius_median, min_size_particle, get_spine,
                     minimum_diameter, closeness_tolerance, min_similarity,
                     ilastik_project_short_name,
                     output_directory,
                     headless_mode, debug, tool_version)
    }
}

def processSingleWell(Client user_client, WellWrapper well_wpr,
                      File ilastik_project, String ilastik_project_type,
                      Integer ilastik_label_OI,
                      Double probability_threshold, Double radius_median,
                      Integer min_size_particle, Boolean get_spine,
                      Integer minimum_diameter, Integer closeness_tolerance, Double min_similarity,
                      String ilastik_project_short_name,
                      File output_directory,
                      Boolean headless_mode, Boolean debug, String tool_version) {
    well_wpr.getWellSamples().each{
        processImage(user_client, it.getImage(),
                     ilastik_project, ilastik_project_type,
                     ilastik_label_OI, probability_threshold,
                     radius_median, min_size_particle, get_spine,
                     minimum_diameter, closeness_tolerance, min_similarity,
                     ilastik_project_short_name,
                     output_directory,
                     headless_mode, debug, tool_version)
    }
}

def processImage(Client user_client, ImageWrapper image_wpr,
                 File ilastik_project, String ilastik_project_type, // String ilastik_strategy,
                 Integer ilastik_label_OI,
                 Double probability_threshold, Double radius_median, Integer min_size_particle,
                 Boolean get_spine,
                 Integer minimum_diameter, Integer closeness_tolerance, Double min_similarity,
                 String ilastik_project_short_name,
                 File output_directory,
                 Boolean headless_mode, Boolean debug, String tool_version) {

    IJ.run("Close All", "")
    IJ.run("Clear Results")
    // Clean ROI manager
    if (!headless_mode) {
        rm = new RoiManager()
        rm = rm.getRoiManager()
        rm.reset()
    }

    // Print image information
    println "\n Image infos"
    String image_basename = image_wpr.getName()
    println ("Image_name : " + image_basename + " / id : " + image_wpr.getId())
    List<DatasetWrapper> dataset_wpr_list = image_wpr.getDatasets(user_client)

    // if the image is part of a dataset
    if(!dataset_wpr_list.isEmpty()){
        dataset_wpr_list.each{println("dataset_name : "+it.getName()+" / id : "+it.getId())};
        image_wpr.getProjects(user_client).each{println("Project_name : "+it.getName()+" / id : "+it.getId())};
    }

    // if the image is part of a plate
    else {
        WellWrapper well_wpr = image_wpr.getWells(user_client).get(0)
        println ("Well_name : "+well_wpr.getName() +" / id : "+ well_wpr.getId())

        def plate_wpr = image_wpr.getPlates(user_client).get(0)
        println ("plate_name : "+plate_wpr.getName() + " / id : "+ plate_wpr.getId())

        def screen_wpr = image_wpr.getScreens(user_client).get(0)
        println ("screen_name : "+screen_wpr.getName() + " / id : "+ screen_wpr.getId())
    }

    ImagePlus imp = image_wpr.toImagePlus(user_client);

    if (!headless_mode) {
        imp.show()
    }

    // get imp info
    int[] dim_array = imp.getDimensions()
    int nC = dim_array[2]
    int nT = dim_array[4]

    int ilastik_input_ch = 1
    // Find the Greys channel:
    ImageProcessor ip
    if (nC > 1) {
        for (int i = 1; i <= nC; i ++) {
            imp.setC(i)
            println "Set channel to "+ i
            ip = imp.getChannelProcessor()
            println ip.getLut().toString()
            // ip.getLut().toString() gives
            // rgb[0]=black, rgb[255]=white, min=3.0000, max=255.0000
            // rgb[0]=black, rgb[255]=green, min=1950.0000, max=2835.0000
            if (ip.getLut().toString().contains("white")) {
                ilastik_input_ch = i
                break
            }
        }
    }
    File output_path = new File (output_directory, image_basename+"_ilastik_" + ilastik_project_short_name + "_output.tif" )
    ImagePlus predictions_imp
    FileSaver fs
    if(output_path.exists()) {
        println "USING EXISTING ILASTIK OUTPUT"
        predictions_imp = IJ.openImage( output_path.toString() )
    } else {
        /**
        *  ilastik
        */
        println "Starting ilastik"

        // get ilastik predictions for each time point of the Time-lapse but all at the same time
        ImagePlus ilastik_input_original = new Duplicator().run(imp, ilastik_input_ch, ilastik_input_ch, 1, 1, 1, nT);

        ImagePlus gb_imp = ilastik_input_original.duplicate()
        IJ.run(gb_imp, "Gaussian Blur...", "sigma=100 stack")
        ImagePlus ilastik_input = ImageCalculator.run(ilastik_input_original, gb_imp, "Divide create 32-bit stack")
        if (!headless_mode) {ilastik_input.show()}
        // can't work without displaying image
        // IJ.run("Run Pixel Classification Prediction", "projectfilename="+ilastik_project+" inputimage="+ilastik_input.getTitle()+" pixelclassificationtype=Probabilities");
        //
        // to use in headless_mode more we need to use a commandservice
        def predictions_imgPlus
        if (ilastik_project_type == "Regular") {
            predictions_imgPlus = cmds.run( IlastikPixelClassificationCommand.class, false,
                                        'inputImage', ilastik_input,
                                        'projectFileName', ilastik_project,
                                        'pixelClassificationType', "Probabilities").get().getOutput("predictions")
        } else {
            predictions_imgPlus = cmds.run( IlastikAutoContextCommand.class, false,
                                        'inputImage', ilastik_input,
                                        'projectFileName', ilastik_project,
                                        'AutocontextPredictionType', "Probabilities").get().getOutput("predictions")
        }
        // to convert the result to ImagePlus : https://gist.github.com/GenevieveBuckley/460d0abc7c1b13eee983187b955330ba
        predictions_imp = ImageJFunctions.wrap(predictions_imgPlus, "predictions")

        predictions_imp.setTitle("ilastik_output")

        // save file
        fs = new FileSaver(predictions_imp)
        fs.saveAsTiff(output_path.toString() )
    }
    if (!headless_mode) {  predictions_imp.show()   }

    /**
     * From the "ilastik predictions of the Time-lapse" do segmentation and cleaning
     */
    // Get only the channel for the gastruloid/background prediction
    ImagePlus mask_imp = new Duplicator().run(predictions_imp, ilastik_label_OI, ilastik_label_OI, 1, 1, 1, nT);
    // This title will appear in the result table
    mask_imp.setTitle(image_basename)
    // Apply threshold:
    IJ.setThreshold(mask_imp, probability_threshold, 100.0000);
    Prefs.blackBackground = true;
    IJ.run(mask_imp, "Convert to Mask", "method=Default background=Dark black");
    if (!headless_mode) {  mask_imp.show() }

    // clean the mask a bit
    // Before we were doing:
    // IJ.run(mask_ilastik_imp, "Options...", "iterations=10 count=3 black do=Open")
    // Now:
    // (Romain proposed 5 as radius_median)
    println "Smoothing mask"

    // Here I need to check if we first fill holes or first do the median
    IJ.run(mask_imp, "Median...", "radius=" + radius_median + " stack");

    IJ.run(mask_imp, "Fill Holes", "stack");

    // Get scale from omero
    PixelsWrapper pixels = image_wpr.getPixels()
    LengthI pixel_size = pixels.getPixelSizeX()
    Double scale = pixel_size.getValue()
    String scale_unit = pixel_size.getUnit().toString()

    // find gastruloids and measure them

    IJ.run("Set Measurements...", "area feret's perimeter shape display redirect=None decimal=3")
    IJ.run("Set Scale...", "distance=1 known=" + scale + " unit=micron")
    // Exclude the edge
    IJ.run(mask_imp, "Analyze Particles...", "size=" + min_size_particle + "-Infinity stack exclude show=Overlay");

    println "Found " + rt.size() + " ROIs"

    // make a "clean" mask
    newMask_imp = IJ.createImage("CleanMask", "8-bit black", imp.getWidth(), imp.getHeight(), nT);
    if (nT > 1) {
        HyperStackConverter.toHyperStack(newMask_imp, 1, 1, nT, "xyctz", "Color");
    }
    if (!headless_mode) {newMask_imp.show()}

    Overlay ov = mask_imp.getOverlay()
    // Let's keep only the largest area for each time:
    Overlay clean_overlay = new Overlay()
    Roi largest_roi_inT
    for (int t=1;t<=nT;t++) {
        // Don't ask me why we need to refer to Z pos and not T/Frame
        ArrayList<Roi> all_rois_inT = ov.findAll{ roi -> roi.getZPosition() == t}
        println "There are " + all_rois_inT.size() + " in time " + t
        if (all_rois_inT.size() == 0) {
            // We arbitrary design a ROI of size 1x1
            largest_roi_inT = new Roi(0,0,1,1)
            largest_roi_inT.setName("GastruloidNotFound_t" + t)
        } else {
            largest_roi_inT = Collections.max(all_rois_inT, Comparator.comparing((roi) -> roi.getStatistics().area ))
            largest_roi_inT.setName("Gastruloid_t" + t)
        }
        // Fill the frame t with the largest_roi_inT
        newMask_imp.setT(t)
        Overlay t_ov = new Overlay(largest_roi_inT)
        t_ov.fill(newMask_imp,  Color.white, Color.black)
        // Update the position before adding to the clean_overlay
        largest_roi_inT.setPosition( ilastik_input_ch, 1, t)
        clean_overlay.add(largest_roi_inT)
    }

    // Measure this new overlay:
    rt = clean_overlay.measure(imp)

    assert rt.size() == nT: "Was expecting as many entry as time points"

    // Get Date
    Date date = new Date()
    String now = date.format("yyyy-MM-dd_HH-mm")

    // Add Date, version and params
    for ( int row = 0;row<rt.size();row++) {
        rt.setValue("Unit", row, scale_unit)
        rt.setValue("Date", row, now)
        rt.setValue("Version", row, tool_version)
        rt.setValue("IlastikProject", row, ilastik_project_short_name)
        rt.setValue("ProbabilityThreshold", row, probability_threshold)
        rt.setValue("MinSizeParticle", row, min_size_particle)
        rt.setValue("MinDiameter", row, minimum_diameter)
        rt.setValue("ClosenessTolerance", row, closeness_tolerance)
        rt.setValue("MinSimilarity", row, min_similarity)
        rt.setValue("RadiusMedian", row, radius_median)
        String label = rt.getLabel(row)
        rt.setValue("BaseImage", row, label.split(":")[0])
        rt.setValue("ROI", row, label.split(":")[1])
        // In simple-omero-client
        // Strings that can be converted to double are stored in double
        // in omero so to create the super_table we need to store all
        // them as Double:
        rt.setValue("Time", row, label.split(":")[1].split("_t")[-1] as Double)
        rt.setValue("ROI_type", row, label.split(":")[1].split("_t")[0])
    }
    println "Remove existing ROIs on OMERO"
    // Remove existing ROIs
    image_wpr.getROIs(user_client).each{ user_client.delete(it) }
    println "Store " + clean_overlay.size() + " ROIs on OMERO"
    // Save ROIs to omero
    image_wpr.saveROIs(user_client, ROIWrapper.fromImageJ(clean_overlay as List))

    // Get them back with IDs:
    List<Roi> updatedRois = ROIWrapper.toImageJ(image_wpr.getROIs(user_client), "ROI")
    if (get_spine) {
        /**
        * The MaxInscribedCircles magic is here
        */
        isSelectionOnly = false
        isGetSpine = true
        appendPositionToName = true
        MaxInscribedCircles mic = MaxInscribedCircles.builder(newMask_imp)
            .minimumDiameter(minimum_diameter)
            .useSelectionOnly(isSelectionOnly)
            .getSpine(isGetSpine)
            .spineClosenessTolerance(closeness_tolerance)
            .spineMinimumSimilarity(min_similarity)
            .appendPositionToName(appendPositionToName)
            .build()
        println "Get spines"
        mic.process()
        List<Roi> all_circles = mic.getCircles();
        List<Roi> all_spines = mic.getSpines();

        /**
        *  For each Time-point, find the :
        *  - the largest cicle
        *  - the spine, and the coordinates of end-points
        *  Measure distances and inverses spine roi if necessary
        *  Add value to table with Elongation Index
        */
        double pixelWidth = mask_imp.getCalibration().pixelWidth

        for (int row = 0 ; row < rt.size();row++) {

            int t = rt.getValue("Time", row) as int
            println "#############"+t
            String roi_type = rt.getStringValue("ROI_type", row)

            if (roi_type == "Gastruloid") {
                List<Roi> circles_t =  all_circles.findAll{ roi -> roi.getName().endsWith("P_"+t)}

                if (circles_t.size() > 0) {
                    Roi largestCircle_roi = circles_t[0]
                    largestCircle_roi.setPosition( ilastik_input_ch, 1, t)
                    println largestCircle_roi
                    def xC = largestCircle_roi.x + largestCircle_roi.width/2
                    def yC = largestCircle_roi.y + largestCircle_roi.height/2
                    println "Largest Circle center : "  + xC + "," + yC
                    double circle_roi_radius = largestCircle_roi.width/2
                    ArrayList<Roi> rois_to_add_to_omero
                    rt.setValue("LargestRadius", row, circle_roi_radius * pixelWidth)
                    if (debug) {
                        circles_t.each{it.setPosition(ilastik_input_ch, 1, t)}
                        // First put all circles to omero:
                        image_wpr.saveROIs(user_client, ROIWrapper.fromImageJ(circles_t as List))
                        if (!headless_mode) {
                            (circles_t as List).each{ rm.addRoi(it)}
                        }
                    } else {
                        // First put the largest circle to omero:
                        image_wpr.saveROIs(user_client, ROIWrapper.fromImageJ([largestCircle_roi] as List))
                        if (!headless_mode) {
                            rm.addRoi(largestCircle_roi)
                        }
                    }

                    // get the Spine, and its points
                    Roi spine_roi = all_spines.findAll{ roi -> roi.getName().endsWith("P_"+t)}[0]
                    println "Spine is " + spine_roi
                    if (spine_roi != null){
                        //println spine_roi
                        println "Get points coo"
                        Double[] spine_xs = spine_roi.getFloatPolygon().xpoints as List
                        Double[] spine_ys = spine_roi.getFloatPolygon().ypoints as List
                        //println spine_xs
                        //println spine_ys

                        // Measure distance between spine end-points and center of the largest circle
                        Double d1 = Math.sqrt( Math.pow(spine_xs[0]  - xC,2) + Math.pow(spine_ys[0]  - yC,2) )
                        Double d2 = Math.sqrt( Math.pow(spine_xs[-1] - xC,2) + Math.pow(spine_ys[-1] - yC,2) )
                        //println d1
                        //println d2

                        if (d2 < d1){
                            println "re-orient spine"
                            // make a new polyline roi from a list of points
                            spine_name = spine_roi.getName()
                            spine_roi = new PolygonRoi(spine_xs.reverse() as int[], spine_ys.reverse() as int[], spine_xs.size(), PolygonRoi.POLYLINE)
                            spine_roi.setName(spine_name)
                        } else {
                            println "orientation of spine is ok"
                        }

                        double line_roi_length = spine_roi.getLength()
                        rt.setValue("SpineLength", row, line_roi_length * pixelWidth)
                        rt.setValue("ElongationIndex", row, line_roi_length / (2*circle_roi_radius))
                        spine_roi.setPosition( ilastik_input_ch, 1, t)
                        image_wpr.saveROIs(user_client, ROIWrapper.fromImageJ([spine_roi] as List))
                        if (!headless_mode) {
                            rm.addRoi(spine_roi)
                        }
                    } else {
                        rt.setValue("SpineLength", row, 0)
                        rt.setValue("ElongationIndex", row, 1)
                    }
                } else {
                    rt.setValue("LargestRadius", row, 0)
                    rt.setValue("SpineLength", row, 0)
                    rt.setValue("ElongationIndex", row, 0)
                }
            } else {
                rt.setValue("LargestRadius", row, 0)
                rt.setValue("SpineLength", row, 0)
                rt.setValue("ElongationIndex", row, -1)
            }
        }
    }
    // get the list of image tables
    // remove the one with table_name
    image_wpr.getTables(user_client).each{ TableWrapper t_wpr ->
        if (t_wpr.getName() == table_name){
            user_client.delete(t_wpr)
        }
    }

    // Create an omero table:
    println "Create an omero table"
    TableWrapper table_wpr = new TableWrapper(user_client, rt, image_wpr.getId(), updatedRois, "ROI")

    // upload the table on OMERO
    table_wpr.setName(table_name)
    image_wpr.addTable(user_client, table_wpr)

    // add the same infos to the super_table
    if (super_table == null) {
        println "super_table is null"
        super_table = table_wpr
    } else {
        println "adding rows"
        super_table.addRows(user_client, rt, image_wpr.getId(), updatedRois, "ROI")
    }
    println super_table.getRowCount()
    println "Writting measurements to file"
    rt.save(output_directory.toString() + '/' + image_basename + "__Results.csv" )

    // Put all ROIs in overlay:
    Overlay global_overlay = new Overlay()
    ROIWrapper.toImageJ(image_wpr.getROIs(user_client), "ROI").each{
        global_overlay.add(it)
    }

    imp.setOverlay(global_overlay)

    // save file
    fs = new FileSaver(imp)
    output_path = new File (output_directory, image_basename + ".tiff" )
    fs.saveAsTiff(output_path.toString() )

    return
}

// In simple-omero-client
// Strings that can be converted to double are stored in double
// In order to build the super_table, tool_version should stay String
String tool_version = "Phase_v20230324"

// User set variables

#@ String(visibility=MESSAGE, value="Inputs", required=false) msg
#@ String(label="User name") USERNAME
#@ String(label="PASSWORD", style='PASSWORD', value="", persist=false) PASSWORD
#@ String(label="File path with omero credentials") credentials
#@ String(label="omero host server") host
#@ Integer(label="omero host server port", value=4064) port
#@ String(label="Object", choices={"image","dataset","well","plate"}) object_type
#@ Long(label="ID", value=119273) id

#@ String(visibility=MESSAGE, value="Parameters for segmentation/ROI", required=false) msg2
#@ File(label="Ilastik project") ilastik_project
#@ String(label="Ilastik project short name") ilastik_project_short_name
#@ String(label="Ilastik project type", choices={"Regular", "Auto-context"}, value="Regular") ilastik_project_type
#@ Integer(label="Ilastik label of interest", min=1, value=1) ilastik_label_OI
#@ Double(label="Probability threshold for ilastik", min=0, max=1, value=0.65) probability_threshold
#@ Double(label="Radius for median (=smooth the mask)", min=1, value=20) radius_median
#@ Integer(label="Minimum surface for Analyze Particle", value=5000) min_size_particle

#@ String(visibility=MESSAGE, value="Parameters for elongation index", required=false) msg3
#@ Boolean(label="Compute spine", value=true) get_spine
#@ Integer(label="Minimum diameter of inscribed circles", min=0, value=20) minimum_diameter
#@ Integer(label="Closeness Tolerance (Spine)", min=0, value=50) closeness_tolerance
#@ Double(label="Min similarity (Spine)", min=-1, max=1, value=0.1) min_similarity

#@ String(visibility=MESSAGE, value="Parameters for output", required=false) msg4
#@ File(style = "directory", label="Directory where measures are put") output_directory
#@ Boolean(label="<html>Run in debug mode<br/>(get all inscribed circles)</html>", value=false) debug

#@ ResultsTable rt
#@ CommandService cmds
#@ ConvertService cvts
#@ DatasetService ds
#@ DatasetIOService io

// Detect if is headless
// java.awt.GraphicsEnvironment.checkheadless_mode(GraphicsEnvironment.java:204)
Boolean headless_mode = GraphicsEnvironment.isHeadless()
if (headless_mode) {
    println "Running in headless mode"
}

// Define rm even if in headless mode
def rm
if (!headless_mode){
    // Reset RoiManager and Result table if not in headless
    rm = new RoiManager()
    rm = rm.getRoiManager()
    rm.reset()
    // Reset the table
    rt.reset()
}

if (PASSWORD == "") {
    File cred_file = new File(credentials)
    if (!cred_file.exists()) {
        throw new Exception("Password or credential file need to be set.")
    }
    String creds = FileUtils.readFileToString(cred_file, "UTF-8")
    if (creds.split("\n").size() < 2) {
        throw new Exception("Credential file requires 2 lines")
    }
    USERNAME = creds.split("\n")[0]
    PASSWORD = creds.split("\n")[1]
}

// Connection to server
Client user_client = new Client()
user_client.connect(host, port, USERNAME, PASSWORD.toCharArray())

// This super_table is a global variable and will be filled each time an image is processed.
super_table = null
// table_name is also a global variable
table_name = "Measurements_from_Galaxy_phase"
if (user_client.isConnected()) {
    println "\nConnected to "+host
    println "Results will be in " + output_directory.toString()

    try {

        switch (object_type) {
            case "image":
                ImageWrapper image_wr
                try {
                    image_wpr = user_client.getImage(id)
                } catch(Exception e) {
                    throw Exception("Could not retrieve the image, please check the id.")
                }
                processImage(user_client, image_wpr,
                     ilastik_project, ilastik_project_type,
                     ilastik_label_OI,
                     probability_threshold, radius_median, min_size_particle,
                     get_spine, minimum_diameter, closeness_tolerance, min_similarity,
                     ilastik_project_short_name,
                     output_directory,
                     headless_mode, debug, tool_version)
                break
            case "dataset":
                DatasetWrapper dataset_wrp
                try {
                    dataset_wrp = user_client.getDataset(id)
                } catch(Exception e) {
                    throw Exception("Could not retrieve the dataset, please check the id.")
                }
                processDataset(user_client, dataset_wrp,
                     ilastik_project, ilastik_project_type,
                     ilastik_label_OI,
                     probability_threshold, radius_median, min_size_particle,
                     get_spine, minimum_diameter, closeness_tolerance, min_similarity,
                     ilastik_project_short_name,
                     output_directory,
                     headless_mode, debug, tool_version)
                // get the list of dataset tables
                // remove the one with table_name
                dataset_wrp.getTables(user_client).each{ TableWrapper t_wpr ->
                    if (t_wpr.getName() == table_name + "_global"){
                        user_client.delete(t_wpr)
                    }
                }
                // upload the table on OMERO
                super_table.setName(table_name + "_global")
                dataset_wrp.addTable(user_client, super_table)
                break
            case "well":
                WellWrapper well_wrp
                try {
                    well_wrp = user_client.getWells(id)[0]
                } catch(Exception e) {
                    throw Exception("Could not retrieve the well, please check the id.")
                }
                processSingleWell(user_client, well_wrp,
                     ilastik_project, ilastik_project_type,
                     ilastik_label_OI,
                     probability_threshold, radius_median, min_size_particle,
                     get_spine, minimum_diameter, closeness_tolerance, min_similarity,
                     ilastik_project_short_name,
                     output_directory,
                     headless_mode, debug, tool_version)
                // get the list of well tables
                // remove the one with table_name
                well_wrp.getTables(user_client).each{ TableWrapper t_wpr ->
                    if (t_wpr.getName() == table_name + "_global"){
                        user_client.delete(t_wpr)
                    }
                }
                // upload the table on OMERO
                super_table.setName(table_name + "_global")
                well_wrp.addTable(user_client, super_table)
                break
            case "plate":
                PlateWrapper plate_wrp
                try {
                    plate_wrp = user_client.getPlates(id)[0]
                } catch(Exception e) {
                    throw Exception("Could not retrieve the plate, please check the id.")
                }
                processSinglePlate(user_client, plate_wrp,
                     ilastik_project, ilastik_project_type,
                     ilastik_label_OI,
                     probability_threshold, radius_median, min_size_particle,
                     get_spine, minimum_diameter, closeness_tolerance, min_similarity,
                     ilastik_project_short_name,
                     output_directory,
                     headless_mode, debug, tool_version)
                // get the list of well tables
                // remove the one with table_name
                plate_wrp.getTables(user_client).each{ TableWrapper t_wpr ->
                    if (t_wpr.getName() == table_name + "_global"){
                        user_client.delete(t_wpr)
                    }
                }
                // upload the table on OMERO
                super_table.setName(table_name + "_global")
                plate_wrp.addTable(user_client, super_table)
                break
        }

    } catch(Exception e) {
        println("Something went wrong: " + e)

        if (headless_mode){
            // This is due to Rank Filter + GaussianBlur
            System.exit(1)
        }
    } finally {
        user_client.disconnect()
        println "Disonnected " + host
    }
    if (headless_mode) {
        // This is due to Rank Filter + GaussianBlur
        System.exit(0)
    }

} else {
    println "Not able to connect to " + host
}

return
