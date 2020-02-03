import java.awt.datatransfer.*;
import java.awt.Toolkit;
import javax.swing.JOptionPane;
import ddf.minim.*;

//the amount of time that will be encoded
int time;
//the number of samples defaults to 1 second
int SAMPLES = 8000;
//max samples per array for the arduino header file
int maxSamples = 32000;
//the number of run cyces to watch progress in producing the header files
int runCycles = 0;

Minim minim;
AudioSample sample;

//parts to be used for the construction of a header file for an arduino program to playback the pcm audio
String declarationFirst = "const unsigned char sample";
String declarationSecond = "[] PROGMEM = {";
String closing = "};";

//save file path
String savePath = "";  
String saveName = "";

//output buffer to hold it
ArrayList<String> outputBuffer = new ArrayList();

//create a header file or copy to clip board?
boolean headerFile = false;

//setup function
void setup()
{
  //setting the size of the window
  size(512, 200);
  //sizetitle of the window
  surface.setTitle("Encode Audio 3 v2.0.0");
  //select the file
  selectInput("Select audio file to encode.", "fileSelected");
}

void fileSelected(File Selection) {
  if (Selection == null) {
    System.out.println("No File Selected");
    exit();
    return;
  }

  try {  
    confirmAndTime();
    //new minim instance
    minim = new Minim(this);

    //get the audio sample to be converted
    sample = minim.loadSample(Selection.toPath().toString());

    //get the samples from the left audio channel

    float[] samples = sample.getChannel(1);
    System.out.println(samples.length);
    float maxval = 0;

    //find the max value to be used later to keep everything relative to itself
    for (int i = 0; i < samples.length; i++) {
      if (abs(samples[i]) > maxval) maxval = samples[i];
    }

    //check
    int start;
    for (start = 0; start < samples.length; start++) {
      if (abs(samples[start]) / maxval > 0.01) break;
    }
    //make the result to be coptied onto the clipboard
    String result = "";  
    int sampleCounter = 0;

    for (int i = start; i < samples.length && i - start < SAMPLES; i++) {
      result += constrain(int(map(samples[i], -maxval, maxval, 0, 256)), 0, 255) + ", "; //generates numbers from 0 to 255 with their magnitudes realitive to the max value
      sampleCounter++;
      if (sampleCounter == maxSamples && headerFile) {
        runCycles++;
        System.out.println("Completed cycle: " + runCycles + " of: " + SAMPLES/maxSamples);
        outputBuffer.add(declarationFirst + runCycles + declarationSecond);
        outputBuffer.add(result);
        outputBuffer.add(closing);
        sampleCounter = 0;
        result = "";
      }
    }

    if (!result.equalsIgnoreCase("") && headerFile) {
      runCycles++;
      outputBuffer.add(declarationFirst + runCycles + declarationSecond);
      outputBuffer.add(result);
      outputBuffer.add(closing);
      String[] output = outputBuffer.toArray(new String[outputBuffer.size()]);
      try {
        saveStrings(savePath + "\\" + saveName + ".h", output);
      }
      catch(Exception e) {
        saveStrings(savePath + "\\" + "EncodedAudio" + ".h", output);
        JOptionPane.showMessageDialog(null, "File name was invalid so the file has been saved as EncodedAudio.h\n");
      }
      JOptionPane.showMessageDialog(null, "Audio saved to text file", "Success!", JOptionPane.INFORMATION_MESSAGE);
    }


    if (!headerFile) {
      //get the clipboard to copy to after
      Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
      //copy to the clipboard
      clipboard.setContents(new StringSelection(result), null);
      //successful popup
      JOptionPane.showMessageDialog(null, "Audio data copied to the clipboard.", "Success!", JOptionPane.INFORMATION_MESSAGE);
    }
  } 
  catch (Exception e) {
    //error pop up when invalid audio file is picked
    JOptionPane.showMessageDialog(null, "Maybe you didn't pick a valid audio file?\n" + e, "Error!", JOptionPane.ERROR_MESSAGE);
  }

  exit();
}


void confirmAndTime() {
  //holder to take the integer value in and convert to a boolean for the building of a header file
  int holder = JOptionPane.showConfirmDialog(null, "Would you like to make an arduino header file?", "Header File?", JOptionPane.YES_NO_OPTION);
  headerFile = (holder == 0);
  if (headerFile) {
    selectFolder("Select save location of output file", "folderSelect");
  }
  //name the save file
  saveName = JOptionPane.showInputDialog("Please enter a save name for the file");
  //if the file wasnt named  
  if (saveName.equals("")) {
    saveName = "Encoded Audio";
  }

//get how many seconds of audio to encode
  try {  
    String timeHolder = JOptionPane.showInputDialog("Please enter the number of seconds of audio to encode");
    time = Integer.parseInt(timeHolder);
  }//catch if there isnt a number put in
  catch(Exception e) {
    JOptionPane.showMessageDialog(null, "Maybe you didn't pick a valid number?\n" + e, "Error!", JOptionPane.ERROR_MESSAGE);
    exit();
  }
  //set the number of samples to encode
  SAMPLES = 8000 * time;
}


//gets and stores the save path to be used later if its needed
public void folderSelect(File location) {
  if (location != null) {
    savePath = location.getPath().toString();
  } else {
    savePath = "";
  }
}

void stop()
{
  sample.close();
  minim.stop();
  super.stop();
}
