###########################
# Question System
###########################
var QuestionSystem = {
	new: func {

		#Load Properties
		var file = getprop("/sim/fg-root") ~ "\\Question\\Beginner.xml";
		var data = io.read_properties(file, "/QuestionSystem");

		var x = 400;
		var y = 300;
		var dlg = canvas.Window.new([x,y], "dialog").set("title", "Question");
		var my_canvas = dlg.createCanvas().setColorBackground(0,0,0,1);
		var root = my_canvas.createGroup();
		var txtTitle = root.createChild("text", "txtTitle");
		txtTitle.setText("Test").setTranslation(10, 20)      # The origin is in the top left corner
		                .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
		                .setFont("LiberationFonts/LiberationSans-Regular.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
		                .setFontSize(14, 1.2)        # Set fontsize and optionally character aspect ratio
		                .setColor(1,0,0)             # Text color;
		                .hide();

		var vbox = canvas.VBoxLayout.new();
		vbox.setContentsMargin(12);
    	dlg.setLayout(vbox);
		var checkbox1 = canvas.gui.widgets.CheckBox.new(root, canvas.style, {}).setText("testBox");
		vbox.addItem(checkbox1);

		return {
			parents: [QuestionSystem],
			dialog: dlg,
			canvas: my_canvas,
			questionText: txtTitle,
			questions: data,
			answers: [],
			timer: nil,
			scores: nil,
		};
	},

	showRandomQuestion: func {
		var idx = int(rand() * (size(me.questions) - 1));
		var questionText = getprop("/QuestionSystem", "Question", idx, "/Text");
		me.questionText.setText(questionText);
		me.questionText.show();

		#choices
		var choices = me.data.getNode("/QuestionSystem/Question[" ~ idx ~ "]/Choices").getChildren();
		for(i = 0; i < size(choices); i++) {
			var choiceText = getprop("/QuestionSystem", "Question", idx, "/Choices/Choice", i, Text);
		}
	},

	start: func {
		var timer = maketimer(100, me, QuestionSystem.showRandomQuestion);
		timer.start();
		me.timer = timer;
	}
};

var startQuestioning = func {
	var qs = QuestionSystem.new();
	qs.start();
};

setlistener("/sim/signals/nasal-dir-initialized", startQuestioning);
startQuestioning();