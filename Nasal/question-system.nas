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
		var my_canvas = dlg.createCanvas();
		var root = my_canvas.createGroup();
		var vbox = canvas.VBoxLayout.new();
		vbox.setContentsMargin(12);
    	dlg.setLayout(vbox);

		return {
			parents: [QuestionSystem],
			dialog: dlg,
			canvas: my_canvas,
			questionText: nil,
			data: data,
			choices: [],
			vbox: vbox,
			root: root,
			timer: nil,
			scores: nil,
		};
	},

	showRandomQuestion: func {
		var idx = int(rand() * (size(me.data.getChildren())-1) + 0.5);
		print("ShowQuestion:" ~ idx ~ " of " ~ (size(me.data.getChildren())));

		me.vbox.clear();

		#question
		var questionText = getprop("/QuestionSystem", "Question", idx, "Text");
		var txtTitle = canvas.gui.widgets.Label.new(me.root, canvas.style, {wordWrap: 0});
		txtTitle.setText(questionText);
		me.vbox.addItem(txtTitle);
        me.questionText = txtTitle;

		#choices
		var choicesPath = "/QuestionSystem/Question[" ~ idx ~ "]/Choices";
		var choices = me.data.getNode(choicesPath).getChildren();
		var numChoices = size(choices);
		for(var i = 0; i < numChoices; i = i + 1) {
			var choicePath = choicesPath ~ "/Choice[" ~ i ~ "]";
			var choiceText = getprop(choicePath, "Text");
			var choicePoint = getprop(choicePath, "Point");
			var checkbox = canvas.gui.widgets.CheckBox.new(me.root, canvas.style, {}).setText(choiceText);
			var choice = {
				text: choiceText,
				point: choicePoint,
				checkbox: checkbox
			};
			append(me.choices, choice);
			me.vbox.addItem(checkbox);
		}
	},

	start: func {
		var timer = maketimer(15, me, QuestionSystem.showRandomQuestion);
		timer.start();
		me.timer = timer;
	},

	stop: func {
		me.timer.stop();
	}
};

var ___qs = nil;

var startQuestioning = func {
	var qs = QuestionSystem.new();
	qs.start();
	___qs = qs;
};

var stopQuestioning = func {
	___qs.stop();
};

setlistener("/sim/signals/nasal-dir-initialized", startQuestioning);
startQuestioning();