import java.awt.datatransfer.*;
import java.awt.Toolkit;
import javax.swing.JOptionPane;
import ddf.minim.*;

int SAMPLES = 30000;

Minim minim;
AudioSample sample;

void setup()
{
  size(512, 200);
  //prompt for the user to selec a file
  selectInput("Select audio file to encode.", "fileSelected");
}

void fileSelected(File Selection) {
  if (Selection == null) {
    System.out.println("No File Selected");
    exit();
    return;
  }

  try {  
    //new minim instance
    minim = new Minim(this);

    //get the audio sample to be converted
    sample = minim.loadSample(Selection.toPath().toString());

    //get the samples from the left audio channel
    float[] samples = sample.getChannel(1);
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
    for (int i = start; i < samples.length && i - start < SAMPLES; i++) {
      result += constrain(int(map(samples[i], -maxval, maxval, 0, 256)), 0, 255) + ", "; //generates numbers from 0 to 255 with their magnitudes realitive to the max value
    }
    
    //get the clipboard to copy to after
    Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
    //copy to the clipboard
    clipboard.setContents(new StringSelection(result), null);
    //successful popup
    JOptionPane.showMessageDialog(null, "Audio data copied to the clipboard.", "Success!", JOptionPane.INFORMATION_MESSAGE);
  } 
  catch (Exception e) {
    //error pop up
    JOptionPane.showMessageDialog(null, "Maybe you didn't pick a valid audio file?\n" + e, "Error!", JOptionPane.ERROR_MESSAGE);
  }

  exit();
}

void stop()
{
  sample.close();
  minim.stop();
  super.stop();
}
