using Gtk;
using WebKit;

public class DictionaryApp : Window {

  private const string TITLE = "Vortaro";
  private string dicts_dir = GLib.Environment.get_variable("HOME") + "/.dicts/";

  private Dictionary[] dicts = {};

  private Entry word;
  private WebView article;

  public DictionaryApp () {
    this.title = DictionaryApp.TITLE;
    set_default_size (800, 600);

    create_widgets ();
    connect_signals ();
    this.word.grab_focus ();
  }

  private void create_widgets () {
    this.word = new Entry ();
    this.article = new WebView ();
    var scrolled_window = new ScrolledWindow (null, null);
    scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    scrolled_window.add (this.article);
    var vbox = new VBox(false, 0); //new Box (Gtk.Orientation.VERTICAL, 0);
    vbox.pack_start (this.word, false, true, 0);
    vbox.add (scrolled_window);
    add (vbox);
  }

  private void connect_signals () {
    this.destroy.connect (Gtk.main_quit);
    this.word.activate.connect (on_activate);
  }

  private void on_activate () {
    var w = this.word.text;
    var text = "";
    foreach(var d in dicts) {
      var info = d.search(w);
      if (info.length > 0) {text += "<div>" + info + "</div>";}
    }
    if (text.length == 0) {
      text = "<i>В словарях нет такого слова</i>";
    }
    var result = "<!doctype html><html><body>" + text + "</body></html>";
    this.article.load_html (result, null);
  }

  public void start () {
    this.dicts += new Dictionary(dicts_dir + "/En_Ru/LingvoUniversalEnRu/");
  }

  public static int main (string[] args) {
    Gtk.init (ref args);

    var app = new DictionaryApp ();

    app.show_all ();
    app.start ();
    Gtk.main ();

    return 0;
  }
}
