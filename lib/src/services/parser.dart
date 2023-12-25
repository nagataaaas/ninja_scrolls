import 'package:html/dom.dart';
import 'package:html/parser.dart';

void parseHtml(String html) {
  var document = parse(html);

  // loop through all elements after first h2
  var h2 = document.getElementsByTagName('h2').first;
  var next = h2.nextElementSibling;
  while (next != null) {
    if (next.innerHtml.contains('わしにはひとつ、心残りがある')) {
      print(next.outerHtml);
      print(next.nodes);
      // loop over next.nodes
      for (var node in next.nodes) {
        if (node is Text) {
          print(node.text);
          print("its a text");
        }
        print(node);
        print(node.runtimeType);
      }
    }
    next = next.nextElementSibling;
  }
}
