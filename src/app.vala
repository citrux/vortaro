using Gtk;
using WebKit;

struct Word {
  public string word;
  public uint32 offset;
  public uint32 size;
  public Word(string w, uint32 o, uint32 s) {
    this.word = w;
    this.offset = o;
    this.size = s;
  }
}

Word? binsearch(Word[] haystack, string needle) {
  int64 l = 0, r = haystack.length;
  while (r > l) {
    int64 m = (l + r) / 2;
    if (haystack[m].word == needle) {
      return haystack[m];
    }
    int a = haystack[m].word.ascii_casecmp(needle);
    if (a ==  0) {
      if (haystack[m].word < needle) { l = m; } else { r = m; }
    } else {
      if (a < 0)  { l = m; } else { r = m; }
    }
  }
  return null;
}


class Dictionary : Object {
  public string name;
  public Word[] index;
  public File dict;

  private void buildIndex(string fname) {
    var file = File.new_for_path(fname);
    try {
      var file_stream = file.read ();
      var data_stream = new DataInputStream (file_stream);
      data_stream.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);
      while(true) {
        uint8[] word = {};
        uint8 chr = 0;
        do {
          chr = data_stream.read_byte();
          word += chr;
        } while (chr != 0);
        string word_str = (string) word;
        uint32 word_data_offset = data_stream.read_uint32();
        uint32 word_data_size = data_stream.read_uint32();
        this.index += Word(word_str, word_data_offset, word_data_size);
      }
    } catch {}

  }

  public string search(string word) {
    var result = "";
    var data = binsearch(this.index, word);
    if (data == null) {return "";}
    try {
      var file_stream = this.dict.read ();
      var data_stream = new DataInputStream (file_stream);
      data_stream.set_byte_order (DataStreamByteOrder.BIG_ENDIAN);
      data_stream.skip(data.offset);
      var raw = new uint8[data.size];
      data_stream.read(raw);
      raw += 0;
      result = (string) raw;
    } catch {}
    return result;
  }

  public Dictionary(string basedir) {
    try {
      var dir = File.new_for_path(basedir);
      var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

      FileInfo file_info;
      while ((file_info = enumerator.next_file ()) != null) {
        var fname = file_info.get_name ();
             if (fname.has_suffix(".idx"))  {buildIndex(basedir + fname);}
        else if (fname.has_suffix(".dict")) {this.dict = File.new_for_path(basedir + fname);}
        else if (fname.has_suffix(".ifo"))  {
          var file = File.new_for_path(basedir + fname);
          FileInputStream @is = file.read ();
          DataInputStream dis = new DataInputStream (@is);
          string line;

          while ((line = dis.read_line ()) != null) {
            if (line.has_prefix("bookname")) {
              this.name = line.split("=", 2)[1];
              break;
            }
          }
        }
      }
    } catch {}
  }
}

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
