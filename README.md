# 
<div align="center">
  <img
    src="images/reminders-icon.png"
    alt="Reminders MenuBar"
  >
  <h1>
    MN Better Notation Plugins for MuseScore
  </h1>
  <p>
    A set of plug-ins for MuseScore Studio 4.4 that check your scores for common notation and layout issues.
  </p>
  <p>
    <a href="#includedplugins">Included Plugins</a> •
    <a href="#installation">Installation</a> •
    <a href="#permission-request">Permission Request</a> •
    <a href="#contributing">Contributing</a> •
    <a href="#languages">Languages</a> •
    <a href="#license">License</a>
  </p>
</div>

<div align="center">
  <img
    max-width="400"
    width="45%"
    src="images/reminder-menubar-light.png"
    alt="Reminders MenuBar in light mode"
  >
  <img
    max-width="400"
    width="45%"
    src="images/reminder-menubar-dark.png"
    alt="Reminders MenuBar in dark mode"
  >
</div>

## Included plug-ins

* **MN Check Rhythmic Notation** checks for:
  * Notes incorrectly 'hiding' a beat (with standard exceptions)
  * Overspecified tied notes that can be 'condensed' into a single note
  * Overspecified rests that can be 'condensed' into a single rest
  * Bar rests incorrectly entered manually
  * Notes not beamed together correctly
  * Notes incorrectly beamed together

* **MN Check Layout** checks for over 60 different layout, notation and instrumentation problems, such as:
  * **Spacing and layout**: Inappropriate staff size, inappropriate margins, barline width too thick, bar spacing too wide or too narrow
  * **Staff names and order**: Incorrect terminology in staff names, incorrect staff order for stock ensembles, duplicate staff names  * **Fonts and styles**: inappropiate tuplets font, incorrectly styled text
  * **Dynamics**: Incorrect dynamics entry, redundant dynamics, hairpins not ‘terminated’, incorrect location for dynamics, dynamic needing restatement after long rest
  * **Text objects**: common misspellings, incorrectly capitalised text, space or non-alphanumeric character at start, text that could be abbreviated, incorrect location for expressions, text includes straight quotes rather than curly, text appears to be a tempo marking but not entered in Tempo text
  * **Orchestral parts issues**: Single line written on shared staff without, e.g., ‘a 2’; ‘unis’/‘div.’ confusion 
  * **Instrument-specific issues**: redundant mute indications, redundant arco/pizz./col legno/tasto/pont/ord. markings, passage that looks arco but is marked pizz., incorrect notation for string harmonics, string harmonic indicated where no harmonic exists, artificial harmonic interval incorrect, piano stretches too wide, long pizz. notes, staccato pizz. notes  * **Pitch**: incorrect use of clefs, clef change needed, incorrect use of 8va/8vb, 8va/8vb needed
  * **Slurs**: slurs incorrectly begin/end on tied note, repeated notes under a slur without articulation, accented notes under a slur
  * **Omissions**:  rehearsal marks (for longer conducted works), tempo marking, initial dynamic, pedal indications on pedal instrument
  * **Other**: fermatas inconsistent across all parts, tremolos incorrectly written, incorrect notation of grace notes, stems incorrectly flipped, mid-tie accidental, note tied to different pitch, pickup bars with inconsistent rests, transposing score not switched on, unnecessarily complex key signatures, short key signature changes, redundant time signature changes, staccato on dotted notes
* **MN Check Accidentals** checks for: 
  * **augmented and diminished intervals** preceded or followed by another augmented or diminished interval (often a sign that an accidental has been misspelled)
  * **double-sharps & double-flats** which may not be necessary
  * **extreme accidentals** (e.g. B# Cb E# Fb), accounting for key signature
  * **recommended courtesy accidentals**




<div align="center">
  <img
    src="images/reminders-menubar-demo.gif"
    alt="Reminders MenuBar demo"
  >
</div>

## Installation

*MN Better Notation Plugins require MuseScore Studio 4.4 or later.*
* **Download** the project as a zip file
* **Extract it** using an archive extraction software
* **Move the folder** to MuseScore’s plugins folder, configurable at [Preferences:General:Folders](https://musescore.org/en/handbook/4/preferences). The default directories are
  * Windows: C:\Users\[Your User Name]\Documents\MuseScore4\Plugins\
  * Mac OS: ~/Documents/MuseScore4/Plugins/
  * Linux: ~/Documents/MuseScore4/Plugins
* **Open MuseScore**
* Click **Home: Plugins** or **Plugins: Manage plugins**...
* For each of the four MN plugins, click on their icon and click ‘**Enable**’
* The plugins should now be available from the **Plugins** menubar

### Direct Download

Direct downloads can be found on the [releases page](https://github.com/DamascenoRafael/reminders-menubar/releases).  
After downloading and extracting, just drag the folder to MuseScore’s plugins folder:
Windows: C:\Users\[Your User Name]\Documents\MuseScore4\Plugins\
* Mac OS: ~/Documents/MuseScore4/Plugins/
* Linux: ~/Documents/MuseScore4/Plugins

## Use
* MN Check Layout operates on the entire score, irrespective of the user selection. MN Check Rhythmic Notation and MN Check Accidentals, however, only operate on the selected bars.
* The plugins add comments in yellow text boxes, and highlight the specific notes or objects that the comments refer to in bright pink.
* If there are a lot of boxes, sometimes a comment box can end up some distance away from the object it is referring to. In this instance, click and drag the box, and you will see an ‘attachment line’ that shows whereabouts the object it is referring to is located.
* Each time you run a plugin, it will remove any previous comments or highlights.
* To manually remove all comments and highlights from a score, please run the ‘MN Delete Comments and Highlights’ plugin

## Warning
Unfortunately MuseScore does not provide a mechanism of indicating who ‘created’ an object. As such, it uses the unusual styles of its comment boxes (yellow fill, black border) and highlights (hot pink) to distinguish them from normal text objects and notes created by the user.
If you only ever use standard black notes and text, then you will have no problem. If, however, you created boxes or highlights with the exact same style/colours as those created by the plugins, then these will be also be deleted when you run the plugins. The chance that you did that, however, is vanishingly small.

## Feedback and bug reports
Feel free to send me any feedback or bug reports! :heart:

## License

This project is licensed under the terms of the GNU General Public License v3.0.  
See [LICENSE](LICENSE) for details.
