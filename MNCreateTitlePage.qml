/*
 * Copyright (C) 2025 Michael Norris
 *
 */

// this version requires MuseScore Studio 4.4 or later

import MuseScore 3.0
import QtQuick 2.9
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Muse.Ui 1.0
import Muse.UiComponents 1.0
import FileIO 3.0

MuseScore {
	version:  "1.0"
	description: "This plugin automatically creates a title page based on the horizontal frame at the top of the page"
	menuPath: "Plugins.MNCreateTitlePage"
	requiresScore: true
	title: "MN Create Title Page"
	id: mncreatetitlepage
	thumbnailName: "MNCreateTitlePage.png"	
	property var selectionArray: []
	property var titlePageStyles: []
	property var spatium: 0
	property var theTitle: ''
	property var theSubtitle: ''
	property var theComposer: ''
	property var titlePageHeight: 0
	property var inchesToMM: 25.4
	property var isMac: false
	property var frontMatterText: "INSTRUMENTATION\n\nFor ensemble and orchestral works, list the instruments required here in score order,\nincluding all doubling instruments and lists of percussion instruments.\n\n\n\nPERFORMANCE INSTRUCTIONS\n\nInclude a list of any unconventional notation used and their meanings,\nand/or any required instrument preparations or other special aspects\nof the piece that can’t be explained on the score.\n\n\n\nDEDICATION\n\nDedicated to ....\n\n\n\nDURATION\n\nApprox. duration: x mins\n\n\n\n(Delete one) Transposed score / Score in C\n\n\n\nPROGRAMME NOTE\n\nInclude a short programme note here\n\n\n\n© Composer Name, 20xx"
	
	FileIO { id: stylesfile;
		source: Qt.resolvedUrl("./assets/styles.json").toString().slice(8);
		onError: { console.log(msg); }
	}
	FileIO { id: versionnumberfile;
		source: Qt.resolvedUrl("./assets/versionnumber.txt").toString().slice(8);
		onError: { console.log(msg); }
	}


  onRun: {
		if (!curScore) return;
		
		spatium = curScore.style.value('spatium')*25.4/mscoreDPI;
		
		isMac = Qt.platform.os === 'osx';
		var versionNumber = versionnumberfile.read().trim();
		dialog.titleText = 'MN CREATE TITLE PAGE '+versionNumber;
		if (!isMac) dialog.fontSize = 12;
		
		// ** CHECK THERE ISN’T ALREADY A TITLE PAGE ** //
		var firstBarInScore = curScore.firstMeasure;
		var firstPageOfMusic = firstBarInScore.parent.parent;
		
		// RETURN IF THERE'S ALREADY A TITLE PAGE (DO SOMETHING HERE)
		if (firstPageOfMusic.pagenumber > 1) {
			dialog.msg = 'This score appears to already have a title page.';
			dialog.show();
			return;	
		}
		
		// ** ANALYSE THE EXISTING TITLE, SUBTITLE AND COMPOSER INFO ** //
		checkTitle ();
		if (theTitle == '') {
			dialog.msg = '<p>I couldn’t find an existing title frame. Please create a standard vertical frame, and add in the Title, Subtitle and Composer texts before running this plugin.</p><p>⚠️</p>';
			dialog.show();
			return;
		}
		// *** SHOW THE TITLE PAGE STYLE DIALOG *** //
		var stylesText = stylesfile.read().trim();
		var stylesJSON = JSON.parse(stylesText);
		titlePageStyles = stylesJSON.titlepages;
		for (var i = 0; i < titlePageStyles.length; i++) {
			var titlePageStyle = titlePageStyles[i];
			var titlePageThumbnail = './thumbnails/'+titlePageStyle.thumbnail+'.png';
			var titlePageLabel = titlePageStyle.label;
			listmodel.append({src: titlePageThumbnail, label: titlePageLabel }); 
		 }
		styles.show();
	}
	
	function checkTitle () {
				
		// ** SELECT ALL THE SCORE TEXT ** //
		curScore.startCmd ();
		cmd ("select-all");
		cmd ("insert-vbox");
		var vbox = curScore.selection.elements[0];
		cmd ("title-text");
		var tempText = curScore.selection.elements[0];
		cmd ("select-similar");
		var elems = curScore.selection.elements;
		for (var i = 0; i < elems.length; i++) {
			var e = elems[i];
			if (!e.is(tempText)) {
				//logError ("Found text object "+e.text);
				var eSubtype = e.subtypeName();
				// Strip out any tags
				if (eSubtype == 'Title') theTitle = e.text.replace(/<[^>]+>/g, "");
				if (eSubtype == 'Subtitle') theSubtitle = e.text.replace(/<[^>]+>/g, "");
				if (eSubtype == 'Composer') theComposer = e.text.replace(/<[^>]+>/g, "");
			}
		}
		if (vbox != null) { removeElement (vbox)};
		cmd ("escape");
		curScore.endCmd();		
	}
	
	function buttonClicked (chosenLabel) {
		var doFrontMatter = styles.createFrontMatter;
		var doChangeAllFonts = styles.changeAllFonts;
		var titlePageBox = null;
		var frontMatterBox = null;
		styles.close ();
		
		var chosenTitlePageStyle = null;
		for (var i = 0; i < titlePageStyles.length && chosenTitlePageStyle == null; i++) {
			if (titlePageStyles[i].label === chosenLabel) chosenTitlePageStyle = titlePageStyles[i];
		}
		if (chosenTitlePageStyle == null) {
			dialog.msg = 'Couldn’t find chosen title page style.';
			dialog.show();
			return;
		}
		var composerStyle = chosenTitlePageStyle.composer;
		var titleStyle = chosenTitlePageStyle.title;
		var subtitleStyle = chosenTitlePageStyle.subtitle;
		var lineStyle = ("line" in chosenTitlePageStyle) ? chosenTitlePageStyle.line : null;
		var line2Style = ("line2" in chosenTitlePageStyle) ? chosenTitlePageStyle.line2 : null;	
		
		// ** SELECT ALL THE SCORE TEXT ** //
		curScore.startCmd();
		cmd ("select-all");
		cmd ("insert-vbox");
		var vbox = curScore.selection.elements[0];
		cmd ("title-text");
		cmd ("select-similar");
		if (vbox != null) removeElement (vbox);
		curScore.endCmd();
		// add another vbox
		if (doFrontMatter) {
			curScore.startCmd();
			cmd ("insert-vbox");
			frontMatterBox = curScore.selection.elements[0];
			cmd ("page-break");
			cmd ("poet-text");
			var frontMatter = curScore.selection.elements[0];
			frontMatter.text = frontMatterText;
			frontMatter.align = Align.HCENTER;
			frontMatter.fontSize = 10;
			if ("frontmatterfont" in chosenTitlePageStyle) frontMatter.fontFace = chosenTitlePageStyle.frontmatterfont;
			curScore.endCmd();
		}
		curScore.startCmd();
		cmd ("insert-vbox");
		titlePageBox = curScore.selection.elements[0];
		cmd ("page-break");
		var newTitle = null;
		var titleLines = 0;
		if (theTitle !== '') {
			cmd ("title-text");
			newTitle = curScore.selection.elements[0];
			newTitle.text = theTitle;
			titleLines = theTitle.split(/\n/).length;
		}
		var newSubtitle = null;
		if (theSubtitle != '') {
			cmd ("subtitle-text");
			newSubtitle = curScore.selection.elements[0];
			newSubtitle.text = theSubtitle;
		}
		var newComposer = null;
		var composerLines = 0;
		if (theComposer != '') {
			cmd ("composer-text");
			newComposer = curScore.selection.elements[0];
			newComposer.text = theComposer;
			composerLines = theComposer.split(/\n/).length;
		}
		if (lineStyle != null) {
			cmd ("poet-text");
			var newLine = curScore.selection.elements[0];
			newLine.text = "—".repeat(23);
		}
		if (line2Style != null) {
			cmd ("poet-text");
			var newLine2 = curScore.selection.elements[0];
			newLine2.text = "—".repeat(23);
		}
		curScore.endCmd();
		cmd ("escape");
		var spatium = curScore.style.value("spatium")*inchesToMM/mscoreDPI;
		titlePageHeight = Math.round(curScore.style.value("pageHeight")*inchesToMM);
		var fontStyles = {'PLAIN' : 0, 'BOLD' : 1, 'ITALIC' : 2};
		var alignStyles = {'LEFT' : Align.LEFT, 'HCENTER' : Align.HCENTER, 'RIGHT' : Align.RIGHT, 'RIGHT VCENTER' : (Align.RIGHT | Align.VCENTER), 'HCENTER BOTTOM' : (Align.HCENTER | Align.BOTTOM), 'LEFT VCENTER' : (Align.LEFT | Align.VCENTER) };
		
		// NOW SET UP THE FONT STYLING AS PER THE TEMPLATES
		var hasBottom = false;
		if (newComposer != null) {
			
			curScore.startCmd();
			newComposer.fontSize = ("fontsize" in composerStyle) ? composerStyle.fontsize : 32.0;
			if ("font" in composerStyle) newComposer.fontFace = composerStyle.font;
			if ("fontstyle" in composerStyle) newComposer.fontStyle = fontStyles[composerStyle.fontstyle];
			if ("align" in composerStyle) {
				newComposer.align = alignStyles[composerStyle.align];
				if (!hasBottom) hasBottom = composerStyle.align.includes("BOTTOM");
			} else {
				newComposer.align = Align.CENTER;
			}
			if ("offsety" in composerStyle) {
				var accountForMultipleLines = true;
				if ("align" in composerStyle) if (!composerStyle.align.includes ("VCENTER") && composerStyle.offsetY < 40) accountForMultipleLines = false;
				if (accountForMultipleLines) {
					newComposer.offsetY = (composerStyle.offsety - ((composerLines - 1) * newComposer.fontSize / 2)) / spatium;
				} else {
					newComposer.offsetY = composerStyle.offsety / spatium;
				}
			}
			if ("offsetx" in composerStyle) newComposer.offsetX = composerStyle.offsetx / spatium;
			var theText = newComposer.text.replace(/<[^>]+>/g, "");
			var composerIsUpperCase = theText === theText.toUpperCase();
			var composerGoingToUpperCase = false;
			if ("case" in composerStyle) {
				if (composerStyle.case == "UPPER") {
					theText = theText.toUpperCase();
					composerGoingToUpperCase = true;
				}
			}
			// convert to titleCase
			if (composerIsUpperCase && !composerGoingToUpperCase) theText = theText.replace(/\b\w+/g,function(s){return s.charAt(0).toUpperCase() + s.substr(1).toLowerCase();});
			
			if ("space" in composerStyle) theText = theText.replace(/(.)/g,'$1\u2009'); // 2009 is a thin space
			if (theText.includes('Arr.') && !composerGoingToUpperCase) theText = theText.replace('Arr.','arr.');
			newComposer.text = theText;
			curScore.endCmd();
		}
		if (newTitle != null) {
			curScore.startCmd();
			newTitle.fontSize = ("fontsize" in titleStyle) ? titleStyle.fontsize : 28.0;
			if ("font" in titleStyle) {
				newTitle.fontFace = titleStyle.font;
				if (doChangeAllFonts) curScore.style.setValue("titleFontFace",titleStyle.font);
			}
			if ("fontstyle" in titleStyle) {
				newTitle.fontStyle = fontStyles[titleStyle.fontstyle];
				if (doChangeAllFonts) curScore.style.setValue("titleFontStyle",newTitle.fontStyle);
			}
			if ("align" in titleStyle) {
				newTitle.align =  alignStyles[titleStyle.align];
				if (!hasBottom) hasBottom = titleStyle.align.includes("BOTTOM");
			} else {
				newTitle.align = Align.CENTER;
			}
			if ("offsety" in titleStyle) {
				var accountForMultipleLines = true;
				if ("align" in titleStyle) if (!titleStyle.align.includes ("VCENTER")) accountForMultipleLines = false;
				if (accountForMultipleLines) {
					newTitle.offsetY = (titleStyle.offsety - ((titleLines - 1) * newTitle.fontSize / 2)) / spatium;
				} else {
					newTitle.offsetY = titleStyle.offsety / spatium;
				}
			}
			if ("offsetx" in titleStyle) newTitle.offsetX = titleStyle.offsetx / spatium;
			if ("case" in titleStyle) if (titleStyle.case == "UPPER") newTitle.text = newTitle.text.toUpperCase();
			if ("space" in titleStyle) newTitle.text = newTitle.text.replace(/(.)/g,'$1\u2009'); // 2009 is a thin space

			curScore.endCmd();
		}
		if (newSubtitle != null) {
			curScore.startCmd();
			newSubtitle.fontSize = ("fontsize" in subtitleStyle) ? subtitleStyle.fontsize : 22.0;
			if ("font" in subtitleStyle) {
				newSubtitle.fontFace = subtitleStyle.font;
				if (doChangeAllFonts) curScore.style.setValue("subTitleFontFace",subtitleStyle.font);
			}
			if ("fontstyle" in subtitleStyle) {
				newSubtitle.fontStyle = fontStyles[subtitleStyle.fontstyle];
				if (doChangeAllFonts) curScore.style.setValue("subTitleFontStyle",newSubtitle.fontStyle);
			}
			if ("align" in subtitleStyle) {
				newSubtitle.align =  alignStyles[subtitleStyle.align];
				if (!hasBottom) hasBottom = subtitleStyle.align.includes("BOTTOM");
			} else {
				newSubtitle.align = Align.CENTER;
			}
			if ("offsety" in subtitleStyle) newSubtitle.offsetY = subtitleStyle.offsety / spatium;
			if ("offsetx" in subtitleStyle) newSubtitle.offsetX = subtitleStyle.offsetx / spatium;
			if ("case" in subtitleStyle) if (subtitleStyle.case == "UPPER") newSubtitle.text = newSubtitle.text.toUpperCase();
			curScore.endCmd();
		}
		if (newLine != null) {
			curScore.startCmd();
			newLine.fontSize = ("fontsize" in lineStyle) ? lineStyle.fontsize : 22.0;
			if ("font" in lineStyle) newLine.fontFace = lineStyle.font;
			if ("fontstyle" in lineStyle) newLine.fontStyle = fontStyles[lineStyle.fontstyle];
			if ("align" in lineStyle) {
				newLine.align = alignStyles[lineStyle.align];
				if (!hasBottom) hasBottom = lineStyle.align.includes("BOTTOM");
			} else {
				newLine.align = Align.CENTER;
			}
			if ("offsety" in lineStyle) newLine.offsetY = lineStyle.offsety / spatium;
			if ("offsetx" in lineStyle) newLine.offsetX = lineStyle.offsetx / spatium;
			var repeats = 23;
			if ("repeats" in lineStyle) repeats = lineStyle.repeats;
			if ("char" in lineStyle) {
				newLine.text = lineStyle.char.repeat(repeats);
			} else {
				if (repeats != 23) newLine.text = '—'.repeat(repeats);
			}
			curScore.endCmd();
		}
		
		if (newLine2 != null) {
			curScore.startCmd();
			newLine2.fontSize = ("fontsize" in line2Style) ? line2Style.fontsize : 22.0;
			if ("font" in line2Style) newLine2.fontFace = line2Style.font;
			if ("fontstyle" in line2Style) newLine2.fontStyle = fontStyles[line2Style.fontstyle];
			if ("align" in line2Style) {
				newLine2.align = alignStyles[line2Style.align];
				if (!hasBottom) hasBottom = line2Style.align.includes("BOTTOM");
			} else {
				newLine2.align = Align.CENTER;
			}
			if ("offsety" in line2Style) newLine2.offsetY = line2Style.offsety / spatium;
			if ("offsetx" in line2Style) newLine2.offsetX = line2Style.offsetx / spatium;
			var repeats = 23;
			if ("repeats" in line2Style) repeats = line2Style.repeats;
			if ("char" in line2Style) {
				newLine2.text = line2Style.char.repeat(repeats);
			} else {
				if (repeats != 23) newLine2.text = '—'.repeat(repeats);
			}
			curScore.endCmd();
		}
		var calcBoxHeight = hasBottom ? Math.round(titlePageHeight / 1.95) : titlePageHeight;
		curScore.startCmd();
		titlePageBox.boxHeight = calcBoxHeight; //titlePageHeight - (titlePageBox.pagePos.y * 2);
		curScore.endCmd();
		var theMsg = '';
		if (frontMatterBox == null) {
			theMsg = '<p>Title page created.';
		} else {
			curScore.startCmd();
			frontMatterBox.boxHeight = calcBoxHeight;
			curScore.endCmd();
			theMsg = '<p>Title page and front matter page created.';
		}
		theMsg += ' Any long titles, subtitles or composers’ names may require additional manual adjustment.</p>';
		cmd('escape');
		cmd('concert-pitch');
		cmd('concert-pitch');
		var displayFontMessage = "fonturl" in chosenTitlePageStyle;
		if (("os" in chosenTitlePageStyle) && isMac) displayFontMessage = false;
		if (displayFontMessage) theMsg += '<p><b>NOTE</b>: This template requires the font ‘'+composerStyle.font+'’. If it is not already installed, download from <a href = "'+chosenTitlePageStyle.fonturl+'">'+chosenTitlePageStyle.fonturl+'</a>.</p>';
		
		theMsg += '<p><b>IMPORTANT</b>: If you wish to exclude the title page from the parts, please select the title page frame and tick ‘Properties→Exclude from parts’ (I cannot do this automatically).</p>';
		dialog.msg = theMsg; 
		dialog.show();
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

	
	StyledDialogView {
		id: dialog
		title: "TITLE PAGE CREATED"
		contentHeight: 282
		contentWidth: 466
		property var msg: ""
		property var titleText: ""
		property var fontSize: 18
	
		Text {
			id: theText
			width: parent.width-40
			x: 20
			y: 20
	
			text: dialog.titleText
			font.bold: true
			font.pointSize: dialog.fontSize
			color: ui.theme.fontPrimaryColor
		}
		
		Rectangle {
			x:20
			width: parent.width-45
			y:45
			height: 1
			color: ui.theme.fontPrimaryColor
		}
	
		ScrollView {
			id: view
			x: 20
			y: 60
			height: parent.height-100
			width: parent.width-40
			leftInset: 0
			leftPadding: 0
			ScrollBar.vertical.policy: ScrollBar.AsNeeded
			TextArea {
				height: parent.height
				textFormat: Text.RichText
				text: dialog.msg
				wrapMode: TextEdit.Wrap
				leftInset: 0
				leftPadding: 0
				readOnly: true
				onLinkActivated: Qt.openUrlExternally(link)
			}
		}
	
		ButtonBox {
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				margins: 10
			}
			buttons: [ ButtonBoxModel.Ok ]
			navigationPanel.section: dialog.navigationSection
			onStandardButtonClicked: function(buttonId) {
				if (buttonId === ButtonBoxModel.Ok) {
					dialog.close()
				}
			}
		}
	}
	
	StyledDialogView {
		id: styles
		title: "MN CREATE TITLE PAGE"
		contentHeight: 580
		contentWidth: 880
		property color backgroundColor: ui.theme.backgroundSecondaryColor
		property var createFrontMatter: false
		property var changeAllFonts: false

		Rectangle {
			color: styles.backgroundColor
			anchors.fill: parent
		}
	
		Text {
			id: styleText
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.topMargin: 20
			anchors.leftMargin: 20
			width: parent.width-40
	
			text: "Click one of the templates below to create a title page"
			font.bold: true
			font.pointSize: 18
			color: ui.theme.fontPrimaryColor
		}
		
		Rectangle {
			id: rect
			anchors.top: styleText.bottom
			anchors.left: parent.left
			anchors.leftMargin: 20
			anchors.topMargin: 10
			width: parent.width-45
			height: 1
			color: ui.theme.fontPrimaryColor
		}
		
		ListModel {
			id: listmodel
		}
		
		Component {
			id: listitem
			Grid {
				columns: 1
				spacing: 5
				padding: 5
				width: 280
				height: 381
				horizontalItemAlignment: Grid.AlignHCenter

				Rectangle {
					id: rect
					property var borderColor: "lightgray"
					color: "transparent"
					border.color: borderColor
					border.width: 4
					width: 272
					height: 381
					Image { 
						source: model.src
						fillMode: Image.PreserveAspectFit
						width: parent.width - 8
						x: 4
						y: 4
						MouseArea {
							anchors.fill: parent
							hoverEnabled: true
							onClicked: {
							   buttonClicked (model.label);
							}
							onEntered: {
								rect.borderColor = "gray";
							}
							onExited: {
								rect.borderColor = "lightgray";
							}
						}
					}
				}
				
				Text {
					text: model.label
				}
			}
		}
	
		ListView {
			id: stylesListView
			anchors.top: rect.bottom
			anchors.left: parent.left
			anchors.topMargin: 10
			anchors.leftMargin: 20
			height: 430
			width: parent.width - 40
			contentWidth: parent.width - 40
			orientation: Qt.Horizontal
			model: listmodel
			delegate: listitem
			clip: true
			ScrollBar.horizontal: ScrollBar {
				policy: ScrollBar.AlwaysOn
				width: 40
			}
		}
		
		GridLayout {
			id: options
			anchors.left: parent.left
			anchors.top: stylesListView.bottom
			anchors.leftMargin: 20
			anchors.topMargin: 20
			rows: 1
			columnSpacing: 40
			
			CheckBox {
				checked: styles.changeAllFonts
				onClicked: {
					checked = !checked
					styles.changeAllFonts = checked
				}
				text: "Change Title & Subtitle text style to match title page fonts"
			}
			
			CheckBox {
				checked: styles.createFrontMatter
				onClicked: {
					checked = !checked
					styles.createFrontMatter = checked
				}
				text: "Create front matter page"
			}
		}
		
		
		Text {
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 20
			anchors.left: parent.left
			anchors.leftMargin: 20
			text: '<b>NOTE</b>: end result may differ if you do not have the specific font installed. Links to required fonts can be found <a href="https://github.com/mnorrisvuw/MN-Better-Notation-Plugins-for-MuseScore?tab=readme-ov-file#fonts">here</a>'
			onLinkActivated: Qt.openUrlExternally(link)
			color: ui.theme.fontPrimaryColor
		}
	}
}
