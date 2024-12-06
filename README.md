# MN Better Notation Plugins for MuseScore

A set of plug-ins for [MuseScore Studio 4.4](https://musescore.org/en) that check your scores for common notation and layout issues.

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
  * **Spacing and layout**: inappropriate staff size, inappropriate margins, barline width too thick, bar spacing too wide or too narrow, minimum bar width too small, inappropriate spacing ratio
  * **Staff names and order**: non-standard staff names, non-standard staff name visibility, incorrect staff order, duplicate staff names  * **Fonts and styles**: inappropiate tuplets font, incorrectly styled text, incorrect dynamics font
  * **Dynamics**: missing first dynamic, redundant dynamics, long hairpins not ‘terminated’, incorrect location for dynamics, dynamic needing restating after long rest
  * **Text objects**: common misspellings, incorrectly capitalised text, space or non-alphanumeric character at start, text could be abbreviated, incorrect location for expressions, straight quotes instead of curly, tempo marking but not entered in Tempo text, default text in Project Properties not changed
  * **Orchestral parts issues**: single line on shared wind/brass staff lacking ‘a 2’/‘1.’ marking; string part lacking a ‘unis.’/‘div.’ marking
  * **String-specific issues**: redundant arco/pizz./col legno/tasto/pont/ord. markings, passage that looks arco but is marked pizz., incorrect notation for string harmonics, string harmonic does not exist, artificial harmonic interval incorrect, long pizz. notes, staccato pizz. notes
  * **Harp-specific issues**: double flats/sharps, impossible chords, too many notes in a chord, too many quick pedal changes
  * **Instrument-specific issues**: redundant mute indications, piano stretches too wide, flute harmonics incorrectly notated, fluttertongue incorrectly notated  * **Pitch**: incorrect use of clefs, clef change needed, incorrect use of 8va/8vb, 8va/8vb needed
  * **Key signatures**: extreme key signatures (6 or more sharps/flats), rapid key signature change, redundant key signature change
  * **Time signatures**: missing first time signature, redundant time signatures
  * **Clefs**: instrument doesn’t read given clef, redundant clef, clef change would improve readability
  * **Slurs**: slurs incorrectly begin/end on tied note, repeated notes under a slur without articulation, slur used instead of tie, accented notes in middle of a slur, slurs over rests
  * **Omissions**:rehearsal marks (for longer conducted works), tempo marking, pedal indications on pedal instrument
  * **Other**: fermatas inconsistent or missing across parts, tremolos incorrectly written, incorrect notation of grace notes, stems incorrectly flipped, note tied to different pitch, pickup bars with inconsistent rests, transposing score not switched on, unnecessarily complex key signatures, short key signature changes, redundant time signature changes, staccato on dotted notes
* **MN Check Accidentals** checks for: 
  * **augmented and diminished intervals** preceded or followed by another augmented or diminished interval (often a sign that an accidental has been misspelled)
  * **double-sharps & double-flats** which may not be necessary
  * **extreme accidentals** (e.g. B# Cb E# Fb), accounting for key signature
  * **recommended courtesy accidentals**


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

Direct downloads can be found on the [releases page](https://github.com/mnorrisvuw/MN-Better-Notation-Plugins-for-MuseScore/releases).

After downloading and extracting, just drag the folder to MuseScore’s plugins folder:
Windows: C:\Users\[Your User Name]\Documents\MuseScore4\Plugins\
* Mac OS: ~/Documents/MuseScore4/Plugins/
* Linux: ~/Documents/MuseScore4/Plugins

## Use
* These plugins scan the selected bars for any notation issues within their scope.

* When it finds a problem, it will add a yellow text box comment and highlight the appropriate object in pink. **Note that the plugins do not fix the error themselves: that is up to you.**

* Sometimes these comments might be more of a suggestion rather than a hard-and-fast typesetting rule: you should therefore consider each comment carefully before remedying.

* It can be a good idea to delete each comment box as you fix the relevant issue to keep track of what you have done.

* If there are a lot of boxes, sometimes a comment box can end up some distance away from the object it is referring to. In this instance, click and drag the box around a bit: you will see an ‘attachment line’ that shows the location of the object to which it is referring.

* Each time you run a plugin, it will remove any previous comments or highlights.

* To manually remove all comments and highlights from a score, please run the ‘MN Delete Comments and Highlights’ plugin

* Note: MN Check Layout operates on the entire score, irrespective of the user selection, while MN Check Rhythmic Notation and MN Check Accidentals only operate on the selected bars.


## Warnings
* This plugin has to use the styles of its comment boxes (yellow fill, black border) and highlights (hot pink) to distinguish them from normal text objects and highlights.
* If you select ‘Format→Reset Text Style Overrides’ or ‘Format→Reset Entire Score to Default Layout’ while you still have comments on the score, or MuseScore will revert them all to standard black-and-white text, and the ‘MN Delete Comments and Highlights’ will not be able to delete them.

* If you only ever use standard black notes and text, then you will have no problem. If, however, you created boxes or highlights with the exact same style/colours as those created by the plugins, then these will be also be deleted when you run the plugins.

## Wait! Nothing happened!!!
* MuseScore does not currently have a way of providing any error messages to the user if it encounters a bug in the plugin code. Instead it just does nothing.

* If you do not get a ‘COMPLETION’ dialog box after running the plugin, it may mean that MuseScore encountered a bug.

* Please send the MuseScore file to Michael Norris, along with a description of which plugin you were running and (if it makes a difference) what portion of the score you had selected.

* If you are able to replicate the bug reliably, that is also very helpful

* That leads me to...

## Feedback, requests and bug reports

* I love feedback, feature requests and bug reports! ♥️

## Known bugs and limitations

**MN Check Layout**

* Only checks the top staff of a harp part for issues
*  

## License

This project is licensed under the terms of the GNU General Public License v3.0.  
See [LICENSE](LICENSE) for details.
