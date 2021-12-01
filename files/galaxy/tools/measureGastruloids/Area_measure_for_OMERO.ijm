// This macro was written thanks to
// https://code.adonline.id.au/imagej-batch-process-headless/
// and
// https://visikol.com/2019/02/building-an-imagej-macro-for-batch-processing-of-images-from-imaging-well-plates/
// The analysis part of the macro is from Pierre Osteil

// Specify global variables

tool_version = "20211201";

parameter_string = getArgument();
print(parameter_string);
arglist = split(parameter_string, ",");

inputDirectory = arglist[0];
outputDirectory = arglist[1];
suffix = arglist[2];
maxThreshold = arglist[3];

setBatchMode(true); 

close("\\Others");
close("Summary");

print("Will process the folder")

processFolder(inputDirectory);

print("Finished processed the folder");

setBatchMode(false); // Now disable BatchMode since we are finished

// Scan folders/subfolders/files to locate files with the correct suffix

function processFolder(input) {
    list = getFileList(input);
    print(list.length);
    for (i = 0; i < list.length; i++) {
        print(list[i]);
        if(File.isDirectory(input + "/" + list[i])){
            print('Folder');
            processFolder("" + input + "/" + list[i]);          
        }
        if(endsWith(list[i], suffix)){
            print('Process');
            processImage("" + input + "/" + list[i]);          
        }
    }
}


function processImage(imageFile)
{
    print(imageFile);
    run("Clear Results");
    print("nRes:" + nResults);
    open(imageFile);
    // Get the filename from the title of the image that's open for adding to the results table
    // We do this instead of using the imageFile parameter so that the
    // directory path is not included on the table
    filename = getTitle();
    
    print(filename);
    
    // Perform the analysis
    run("16-bit");
    setThreshold(0, maxThreshold);
    run("Convert to Mask");
    run("Dilate");
    run("Fill Holes");

    //Get the measurements
    run("Set Measurements...", "area feret's perimeter shape display redirect=None decimal=3");
    run("Set Scale...", "distance=1 known=0.92 unit=micron"); //objective 4x 2.27 on TC microscope for x10 use 0.92 (measured by PierreO)
    // run("Analyze Particles...", "size=10000-400000 circularity=0.05-1.00 display clear exclude add"); // add clear to have one Result file per image
    run("Analyze Particles...", "size=10000-400000 circularity=0.05-1.00 display clear exclude show=Overlay"); // add clear to have one Result file per image
    print("nRes:" + nResults);

    // Get date:
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
    TimeString = ""+year+"-";
    if (month<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+month+"-";
    if (dayOfMonth<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+dayOfMonth+"_";
    if (hour<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+hour+"-";
    if (minute<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+minute;
    // Now loop through each of the new results, and add the time to the "Date" column
    for (row = 0; row < nResults; row++)
    {
        setResult("Date", row, TimeString);
        setResult("Version", row, tool_version);
        setResult("MaxThreshold", row, maxThreshold);
    }

    // Save the results data
    saveAs("results", outputDirectory + "/" + filename + "__Results.csv");
    // Now loop through Overlay:
    print("Overlay size:" + Overlay.size);
    for (i=0; i<Overlay.size; i++) {
      Overlay.activateSelection(i);
      getSelectionCoordinates(x,y);
      print("Opening file");
      f = File.open(outputDirectory + "/" + filename + "__" + i + "_roi_coordinates.txt");
      for (j=0; j<x.length; j++){
        print(f, x[j] + "\t" + y[j]);        
      }
      File.close(f);
    }
    print("Selection OK");
    
    close();  // Closes the current image
    print("OK");
}
