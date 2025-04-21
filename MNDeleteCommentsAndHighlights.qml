/*
 * Copyright (C) 2025 Michael Norris
 *
 */

// this version requires MuseScore Studio 4.4 or later

import MuseScore 3.0
import QtQuick 2.9
import QtQuick.Controls 2.15
import Muse.UiComponents 1.0
import FileIO 3.0


MuseScore {
	version:  "1.0"
	description: "This plugin removes any comments and highlights from your score that were added by the MN Plugins"
	menuPath: "Plugins.MNDeleteCommentsAndHighlights";
	requiresScore: true
	title: "MN Delete Comments and Highlights"
	id: mndeletecommentsandhighlights
	thumbnailName: "MNDeleteCommentsAndHighlights.png"	
	property var selectionArray: [];

  onRun: {
		if (!curScore) return;
				
		var elementsToRemove = [];
		var elementsToRecolor = [];
		
		// ** SAVE CURRENT SELECTION ** //
		saveSelection();
		
		// ** CHECK TITLE TEXT FOR HIGHLIGHTS ** //
		doCmd ("select-all");
		doCmd ("insert-vbox");
		var vbox = curScore.selection.elements[0];
		doCmd ("title-text");
		doCmd ("select-similar");
		
		var elems = curScore.selection.elements;
		for (var i = 0; i<elems.length; i++) {
			var e = elems[i];
			var c = e.color;	
			// style the element pink
			if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(e);
		}
		if (vbox != null) deleteObj (vbox);
		
		// **** SELECT ALL **** //
		doCmd ("select-all");
		
		// **** GET ALL OTHER ITEMS **** //
		var elems = curScore.selection.elements;
		
		// **** LOOP THROUGH ALL ITEMS AND ADD THEM TO AN ARRAY IF THEY MATCH **** //
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			var t = e.type;
			var c = e.color;	
			// style the element
			if (Qt.colorEqual(c,"hotpink")) {
				elementsToRecolor.push(e);
			} else {
				if (t == Element.STAFF_TEXT) {
					if (Qt.colorEqual(e.frameBgColor,"yellow") && Qt.colorEqual(e.frameFgColor,"black")) elementsToRemove.push(e);
				}
			}
		}
		
		var segment = curScore.firstSegment();
		while (segment) {
			if (segment.segmentType == Segment.TimeSig) {
				for (var i = 0; i < curScore.nstaves; i++) {
					var theTimeSig = segment.elementAt(i*4);
					if (theTimeSig.type == Element.TIMESIG) {
						var c = theTimeSig.color;
						if (Qt.colorEqual(c,"hotpink")) elementsToRecolor.push(theTimeSig);
					}
				}
			}
			segment = segment.next;
		}
		
		// **** DELETE EVERYTHING IN THE ARRAY **** //
		for (var i = 0; i < elementsToRecolor.length; i++) elementsToRecolor[i].color = "black";
		for (var i = 0; i < elementsToRemove.length; i++) deleteObj(elementsToRemove[i]);
		
		cmd ('escape');
		cmd ('escape');
		cmd ('concert-pitch');
		cmd ('concert-pitch');
	}
	
	function saveSelection () {
		selectionArray = [];
		if (curScore.selection.isRange) {
			selectionArray[0] = curScore.selection.startSegment.tick;
			//errorMsg += "\n"+curScore.selection.startSegment+" "+curScore.selection.startSegment.tick;
			
			selectionArray[1] = curScore.selection.endSegment.tick;
			selectionArray[2] = curScore.selection.startStaff;
			selectionArray[3] = curScore.selection.endStaff;
		}
	}
	
	
	function doCmd (theCmd) {
		curScore.startCmd ();
		cmd (theCmd);
		curScore.endCmd ();
	}
	
	function deleteObj (theElem) {
		curScore.startCmd ();
		removeElement (theElem);
		curScore.endCmd ();
	}
	
	function restoreSelection () {
		curScore.startCmd();

		if (selectionArray.length == 0) {
			curScore.selection.clear();
		} else {
			var st = selectionArray[0];
			var et = selectionArray[1];
			var ss = selectionArray[2];
			var es = selectionArray[3];
			curScore.selection.selectRange(st,et+1,ss,es + 1);
			//errorMsg += "\n"+st+" "+et+" "+ss+" "+es;
		}
		curScore.endCmd();
	}
	
	ApplicationWindow {
		id: dialog
		title: "WARNING!"
		property var msg: "Warning message here."
		visible: false
		flags: Qt.Dialog | Qt.WindowStaysOnTopHint
	      // Qt.WindowStaysOnTopHint => dialog always on top
	      // Qt.FramelessWindowHint  => dialog without title bar
		width: 500
		height: 400        

		StyledTextLabel {
			text: dialog.msg            
			anchors {
				top: parent.top 
				horizontalCenter: parent.horizontalCenter                
				margins:20 
			} 
		}
		FlatButton {            
			accentButton: true
			text: "Ok"
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				margins: 10
			}
			onClicked: dialog.close()
		}
	}
}
