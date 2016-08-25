using Gtk;
using WebKit;

public class DictionaryApp : Window {

  private const string TITLE = "Vortaro";
  private string dicts_dir = GLib.Environment.get_variable("HOME") + "/.dicts/";

  private Dictionary[] dicts = {};

  private Entry word;
  private WebView article;
  private Spinner spinner;
  private Label status;
  private string css;

  public DictionaryApp () {
    set_default_size (800, 600);

    create_widgets ();
    connect_signals ();
    this.word.grab_focus ();
    this.css = "div {"
             + "position: relative;"
             + "padding-top: 1.5em;"
             + "padding-bottom: 1.5em;"
             + "border-bottom: 1px solid #aaa;"
             + "}"
             + "div:last-child {"
             + "border-bottom: none;"
             + "}"
             + ".tr:before {"
             + "content: '[';"
             + "}"
             + ".tr:after {"
             + "content: ']';"
             + "}"
             + ".dict {"
             + "position: absolute;"
             + "top: 0.2em;"
             + "left: 50%;"
             + "}";
  }

  private void create_widgets () {
    var headerbar = new HeaderBar();
    headerbar.set_title(TITLE);
    headerbar.set_show_close_button(true);
    set_titlebar(headerbar);
    this.word = new Entry ();
    this.article = new WebView ();
    this.status = new Label("");
    this.spinner = new Spinner();
    var scrolled_window = new ScrolledWindow (null, null);
    scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    scrolled_window.add (this.article);
    var status_bar = new ActionBar ();
    status_bar.pack_start(spinner);
    status_bar.add(status);
    var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
    vbox.pack_start (this.word, false, true, 0);
    vbox.pack_start (scrolled_window, true, true, 0);
    vbox.pack_start (status_bar, false, true, 0);
    add (vbox);
  }

  private void connect_signals () {
    this.destroy.connect (Gtk.main_quit);
    this.word.activate.connect (on_activate);
  }

  private void on_activate () {
    var w = this.word.text;
    var text = "";
    foreach(var d in this.dicts) {
      var info = d.search(w);
      if (info.length > 0) {text += info;}
    }
    if (text.length == 0) {
      text = "<i>В словарях нет такого слова</i>";
    }
    var result = @"<!doctype html><html><body><style>$css</style>$text</body></html>";
    this.article.load_html (result, null);
  }

  public async void load_dicts () {
    SourceFunc callback = load_dicts.callback;
    ThreadFunc<void*> run = () => {
      var en_ru_dir = Path.build_path(Path.DIR_SEPARATOR_S, dicts_dir, "En_Ru");
      var dir = File.new_for_path(en_ru_dir);
      var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

      FileInfo file_info;
      while ((file_info = enumerator.next_file ()) != null) {
        var fname = file_info.get_name ();
        this.dicts += new Dictionary(Path.build_path(Path.DIR_SEPARATOR_S, en_ru_dir, fname));
      }
      Idle.add((owned) callback);
      return null;
    };
    Thread.create<void*>(run, false);
    this.status.label = "Loading dictionaries...";
    this.spinner.start();
    yield;
    this.status.label = "All dictionaries loaded!";
    this.spinner.stop();
  }

  public static int main (string[] args) {
    Gtk.init (ref args);

    var app = new DictionaryApp ();

    app.show_all ();
    app.load_dicts();
    Gtk.main ();

    return 0;
  }
}
