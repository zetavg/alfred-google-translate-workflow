#!./node
var translate = require('google-translate-api');

var source = process.argv[2]
var target = process.argv[3]
var query = process.argv[4]
var target_display_name = process.argv[5]

translate(query, { from: source, to: target, raw: true }).then(res => {
  var rawStr = res.raw.replace(/,,/g, ',null,').replace(/,,/g, ',null,').replace(/\[,/g, '[null,');
  var raw = JSON.parse(rawStr);

  output = { items: [] };

  if (res.from.text.autoCorrected) {
    var autoCorrected = res.from.text.value.replace(/\<[^\<\>]+\>/g, '');
    autoCorrected = autoCorrected.replace(/\[/, '').replace(/\]/, '');
    output.items.push({ title: autoCorrected, subtitle: 'Did you mean this?', autocomplete: autoCorrected });
  }

  if (res.text) {
    const text = res.text.replace(/null$/, '');
    output.items.push({ title: text, subtitle: target_display_name, arg: text });
  }

  if (raw && raw[1]) {
    raw[1].forEach((group) => {
      var type = group[0];

      group[2].forEach((wordData) => {
        var word = wordData[0];
        var translations = wordData[1];
        var frequency = wordData[3];
        output.items.push({ title: word, subtitle: `(${type}) ${translations.join(', ')}`, arg: word });
      });
    });
  }

  console.log(JSON.stringify(output));
}).catch(e => {
  console.error(e);
});
